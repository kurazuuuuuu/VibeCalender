//
//  EventManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Combine
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
    Task {
      await requestAccess()
    }
  }

  private func requestAccess() async {
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
