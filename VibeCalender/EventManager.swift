//
//  EventManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Combine
import CoreML
import EventKit
import Foundation

@MainActor
class EventManager: ObservableObject {
  var store = EKEventStore()

  // イベントへの認証ステータスのメッセージ
  @Published var statusMessage = ""

  // 認証済みフラグ
  @Published var isAuthorized = false

  // 利用可能なカレンダーリスト
  @Published var calendars: [EKCalendar] = []

  init() {
    // 起動時に現在のステータスを即座に反映
    updateStatus()
    loadCalendars()

    // 認証が必要な場合のみリクエスト
    if EKEventStore.authorizationStatus(for: .event) == .notDetermined {
      Task {
        await requestAccess()
      }
    }
  }

  private func requestAccess() async {
    let status = EKEventStore.authorizationStatus(for: .event)
    guard status == .notDetermined else {
      updateStatus()
      return
    }

    do {
      // カレンダーへのアクセスを要求
      try await store.requestFullAccessToEvents()
      updateStatus()
      loadCalendars()
    } catch {
      print(error.localizedDescription)
      updateStatus()
    }
  }

  private func updateStatus() {
    let status = EKEventStore.authorizationStatus(for: .event)

    switch status {
    case .notDetermined:
      statusMessage = "カレンダーへのアクセスする\n権限が選択されていません。"
      isAuthorized = false
    case .restricted:
      statusMessage = "カレンダーへのアクセスする\n権限がありません。"
      isAuthorized = false
    case .denied:
      statusMessage = "カレンダーへのアクセスが\n明示的に拒否されています。"
      isAuthorized = false
    case .fullAccess:
      statusMessage = "カレンダーへのフルアクセスが\n許可されています。"
      isAuthorized = true
    case .writeOnly:
      statusMessage = "カレンダーへの書き込みのみが\n許可されています。"
      isAuthorized = true
    @unknown default:
      statusMessage = "@unknown default"
      isAuthorized = false
    }
  }

  // MARK: - カレンダー取得

  func loadCalendars() {
    calendars = store.calendars(for: .event)
  }

  var defaultCalendar: EKCalendar? {
    store.defaultCalendarForNewEvents
  }

  // MARK: - 予定取得

  func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
    let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
    return store.events(matching: predicate)
  }

  func fetchEvent(by identifier: String) -> EKEvent? {
    return store.event(withIdentifier: identifier)
  }

  // MARK: - 予定作成

  func createEvent(
    title: String,
    startDate: Date,
    endDate: Date,
    calendar: EKCalendar? = nil,
    notes: String? = nil,
    isAIGenerated: Bool = false
  ) throws -> EKEvent {
    let event = EKEvent(eventStore: store)
    event.title = title
    event.startDate = startDate
    event.endDate = endDate
    event.calendar = calendar ?? defaultCalendar
    event.notes = notes

    // AI生成フラグをnotesに追加
    if isAIGenerated {
      event.notes = (event.notes ?? "") + "\n[AI Generated]"
    }

    try store.save(event, span: .thisEvent)
    return event
  }

  // MARK: - 予定更新

  func updateEvent(
    _ event: EKEvent,
    title: String? = nil,
    startDate: Date? = nil,
    endDate: Date? = nil,
    calendar: EKCalendar? = nil,
    notes: String? = nil
  ) throws {
    if let title = title {
      event.title = title
    }
    if let startDate = startDate {
      event.startDate = startDate
    }
    if let endDate = endDate {
      event.endDate = endDate
    }
    if let calendar = calendar {
      event.calendar = calendar
    }
    if let notes = notes {
      event.notes = notes
    }

    try store.save(event, span: .thisEvent)
  }

  // MARK: - 予定削除

  func deleteEvent(_ event: EKEvent) throws {
    try store.remove(event, span: .thisEvent)
  }

  // MARK: - AI生成判定

  func isAIGenerated(_ event: EKEvent) -> Bool {
    return event.notes?.contains("[AI Generated]") ?? false
  }
}

// MARK: - AI Features Extension for Date

extension Date {
  var aiFeatures: (month: Int64, day: Int64, weekday: Int64, hour: Int64, isWeekend: Int64) {
    let calendar = Calendar.current
    let comps = calendar.dateComponents([.month, .day, .weekday, .hour], from: self)

    let month = Int64(comps.month ?? 1)
    let day = Int64(comps.day ?? 1)
    let hour = Int64(comps.hour ?? 0)

    // Swiftのweekday: 1(Sun) ~ 7(Sat)
    // Pythonのweekday: 0(Mon) ~ 6(Sun)
    let swiftWeekday = comps.weekday ?? 1
    let pyWeekday = (swiftWeekday == 1) ? 6 : swiftWeekday - 2

    // 週末判定 (Pythonロジック: 土(5), 日(6) なら週末)
    let isWeekend: Int64 = (pyWeekday >= 5) ? 1 : 0

    return (month, day, Int64(pyWeekday), hour, isWeekend)
  }
}

// MARK: - Event Predictor

class EventPredictor {
  static let shared = EventPredictor()

  var model: CalendarClassifier?

  private var modelURL: URL {
    let fileManager = FileManager.default
    // 注意: Simluator等では documentDirectory が変わる可能性があるが、標準的な取得方法に従う
    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return documentDirectory.appendingPathComponent("CalendarClassifier.mlmodelc")
  }

  init() {
    loadModel()
  }

  private func loadModel() {
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: modelURL.path) {
      do {
        print("Loading personalized model from: \(modelURL.path)")
        let config = MLModelConfiguration()
        self.model = try CalendarClassifier(contentsOf: modelURL, configuration: config)
        return
      } catch {
        print("Failed to load personalized model: \(error)")
      }
    }

    do {
      print("Loading default model.")
      self.model = try CalendarClassifier(configuration: MLModelConfiguration())
    } catch {
      print("Failed to load default model: \(error)")
    }
  }

  /// 確率的サンプリングを用いてカテゴリを予測する (多様性確保)
  func predictCategory(for date: Date) -> String? {
    guard let model = model else { return nil }
    let features = date.aiFeatures

    do {
      let input = try CalendarClassifierInput(
        weekday: features.weekday,
        hour: features.hour,
        month: features.month,
        day: features.day,
        is_weekend: features.isWeekend,
        original_subject_length: 0
      )

      let output = try model.prediction(input: input)

      // 確率分布を取得 (例: ["Work": 0.6, "Personal": 0.3, ...])
      let probabilities = output.categoryProbability

      // 重み付きランダムサンプリング
      return weightedRandomSelection(from: probabilities) ?? output.category

    } catch {
      print("AI Prediction Error: \(error)")
      return nil
    }
  }

  /// 重み付きランダム選択
  private func weightedRandomSelection(from probabilities: [String: Double]) -> String? {
    let total = probabilities.values.reduce(0, +)
    guard total > 0 else { return nil }

    let threshold = Double.random(in: 0..<total)
    var current = 0.0

    // 確率が高い順に試行したほうが効率的だが、辞書は順序保証がないためそのまま回す
    for (category, probability) in probabilities {
      current += probability
      if current >= threshold {
        return category
      }
    }
    return probabilities.keys.first
  }

  /// 過去のイベントデータを用いてモデルを再学習させる (Async)
  func train(with events: [EKEvent]) async {
    guard !events.isEmpty else { return }

    var featureProviders: [MLFeatureProvider] = []

    // データ前処理
    for event in events {
      guard let startDate = event.startDate,
        let category = event.calendar?.title
      else { continue }

      let features = startDate.aiFeatures
      let data: [String: Any] = [
        "weekday": features.weekday,
        "hour": features.hour,
        "month": features.month,
        "day": features.day,
        "is_weekend": features.isWeekend,
        "category": category,
      ]

      if let provider = try? MLDictionaryFeatureProvider(dictionary: data) {
        featureProviders.append(provider)
      }
    }

    guard !featureProviders.isEmpty else { return }
    let batchProvider = MLArrayBatchProvider(array: featureProviders)

    // ベースモデルの取得
    guard
      let defaultModelURL = Bundle.main.url(
        forResource: "CalendarClassifier", withExtension: "mlmodelc")
    else {
      print("Default compiled model not found.")
      return
    }
    let baseModelURL =
      FileManager.default.fileExists(atPath: modelURL.path) ? modelURL : defaultModelURL

    print("Starting on-demand training with \(featureProviders.count) events...")

    // MLUpdateTask を async でラップ
    return await withCheckedContinuation { continuation in
      do {
        let updateTask = try MLUpdateTask(
          forModelAt: baseModelURL,
          trainingData: batchProvider,
          configuration: nil,
          completionHandler: { context in
            self.handleUpdateCompletion(context: context)
            continuation.resume()
          }
        )
        updateTask.resume()
      } catch {
        print("Failed to start training task: \(error)")
        continuation.resume()
      }
    }
  }

  private func handleUpdateCompletion(context: MLUpdateContext) {
    if let error = context.task.error {
      print("Model update failed: \(error)")
      return
    }

    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: modelURL.path) {
        try fileManager.removeItem(at: modelURL)
      }
      try context.model.write(to: modelURL)
      print("Updated model saved to: \(modelURL.path)")

      DispatchQueue.main.async {
        self.loadModel()
      }
    } catch {
      print("Failed to save updated model: \(error)")
    }
  }
}
