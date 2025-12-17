//
//  UserPreferenceEncoder.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import EventKit
import Foundation

// MARK: - 学習データ構造
// ユーザーの予定傾向をLLMが理解しやすい形式でエンコード

/// ユーザーの行動傾向データ（LLM理解用）
struct UserPreferenceData: Codable {
  /// 曜日別の予定頻度
  var weekdayFrequency: [String: Int]  // "Mon": 5, "Tue": 3, ...

  /// 時間帯別の予定傾向
  var timeSlotPreference: [String: Int]  // "morning": 3, "afternoon": 5, "evening": 2

  /// カテゴリ別の予定数
  var categoryDistribution: [String: Int]  // "仕事": 10, "プライベート": 5, ...

  /// よく使うキーワード（予定タイトルから抽出）
  var frequentKeywords: [String]

  /// 平均予定時間（分）
  var averageDurationMinutes: Int

  /// 直近1ヶ月の予定数
  var totalEventsCount: Int

  /// 空き時間帯
  var freeTimeSlots: [String]  // "Mon-morning", "Fri-evening", ...

  /// 最終更新日
  var lastUpdated: Date
}

// MARK: - エンコーダー

class UserPreferenceEncoder {
  private let eventStore: EKEventStore

  init(eventStore: EKEventStore) {
    self.eventStore = eventStore
  }

  /// 前後1ヶ月の予定からユーザー傾向をエンコード
  func encodeUserPreferences() async -> UserPreferenceData {
    let calendar = Calendar.current
    let now = Date()

    // 前後1ヶ月の範囲
    guard let startDate = calendar.date(byAdding: .month, value: -1, to: now),
      let endDate = calendar.date(byAdding: .month, value: 1, to: now)
    else {
      return emptyPreferenceData()
    }

    // EventKitから予定を取得
    let predicate = eventStore.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: nil
    )
    let events = eventStore.events(matching: predicate)

    return analyzeEvents(events)
  }

  private func analyzeEvents(_ events: [EKEvent]) -> UserPreferenceData {
    var weekdayFrequency: [String: Int] = [:]
    var timeSlotPreference: [String: Int] = [
      "morning": 0, "afternoon": 0, "evening": 0, "night": 0,
    ]
    var categoryDistribution: [String: Int] = [:]
    var keywords: [String: Int] = [:]
    var totalDuration: Int = 0
    var freeSlots: Set<String> = []

    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let calendar = Calendar.current

    for event in events {
      guard let startDate = event.startDate else { continue }

      // 曜日カウント
      let weekday = calendar.component(.weekday, from: startDate)
      let weekdayStr = weekdays[weekday - 1]
      weekdayFrequency[weekdayStr, default: 0] += 1

      // 時間帯カウント
      let hour = calendar.component(.hour, from: startDate)
      let timeSlot = getTimeSlot(hour: hour)
      timeSlotPreference[timeSlot, default: 0] += 1

      // カテゴリ（カレンダー名）カウント
      let calendarTitle = event.calendar?.title ?? "その他"
      categoryDistribution[calendarTitle, default: 0] += 1

      // キーワード抽出
      if let title = event.title {
        let words = extractKeywords(from: title)
        for word in words {
          keywords[word, default: 0] += 1
        }
      }

      // 時間計算
      if let end = event.endDate {
        let duration = Int(end.timeIntervalSince(startDate) / 60)
        totalDuration += duration
      }
    }

    // 頻出キーワードTop10
    let topKeywords =
      keywords
      .sorted { $0.value > $1.value }
      .prefix(10)
      .map { $0.key }

    // 平均時間
    let avgDuration = events.isEmpty ? 60 : totalDuration / events.count

    return UserPreferenceData(
      weekdayFrequency: weekdayFrequency,
      timeSlotPreference: timeSlotPreference,
      categoryDistribution: categoryDistribution,
      frequentKeywords: Array(topKeywords),
      averageDurationMinutes: avgDuration,
      totalEventsCount: events.count,
      freeTimeSlots: Array(freeSlots),
      lastUpdated: Date()
    )
  }

  private func getTimeSlot(hour: Int) -> String {
    switch hour {
    case 6..<12: return "morning"
    case 12..<17: return "afternoon"
    case 17..<21: return "evening"
    default: return "night"
    }
  }

  private func extractKeywords(from title: String) -> [String] {
    // 簡易的なキーワード抽出（2文字以上の単語）
    let words = title.components(separatedBy: CharacterSet.alphanumerics.inverted)
    return words.filter { $0.count >= 2 }
  }

  private func emptyPreferenceData() -> UserPreferenceData {
    return UserPreferenceData(
      weekdayFrequency: [:],
      timeSlotPreference: [:],
      categoryDistribution: [:],
      frequentKeywords: [],
      averageDurationMinutes: 60,
      totalEventsCount: 0,
      freeTimeSlots: [],
      lastUpdated: Date()
    )
  }

  /// JSON文字列にエンコード（API送信用・LLMプロンプト用）
  func encodeToJSON(preferences: UserPreferenceData) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    guard let data = try? encoder.encode(preferences),
      let jsonString = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }
    return jsonString
  }
}
