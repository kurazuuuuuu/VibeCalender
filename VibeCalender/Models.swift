//
//  Models.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Foundation

// MARK: - User
/// ユーザー情報
struct User: Codable, Identifiable {
  let id: String
  var username: String
  var email: String
  var createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, username, email
    case createdAt = "created_at"
  }
}

// MARK: - ScheduleEvent
/// 予定データ（API連携用）
struct ScheduleEvent: Codable, Identifiable {
  let id: String
  var userId: String
  var title: String
  var category: String  // 行動ジャンル（仕事、プライベート等）
  var startDate: Date
  var endDate: Date
  var isAIGenerated: Bool  // AI生成フラグ
  var ekEventId: String?  // EventKit連携用
  var createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, title, category
    case userId = "user_id"
    case startDate = "start_date"
    case endDate = "end_date"
    case isAIGenerated = "is_ai_generated"
    case ekEventId = "ek_event_id"
    case createdAt = "created_at"
  }
}

// MARK: - UserProfile
/// ユーザーの行動嗜好プロファイル (AI学習用)
struct UserProfile: Codable {
  var interests: [String]  // 全体的な興味・関心
  var categoryKeywords: [String: [String]]  // カテゴリごとの頻出キーワードマップ
  var frequentLocations: [String]  // よく行く場所
  var vibeDescription: String  // 全体的な雰囲気

  static let empty = UserProfile(
    interests: [],
    categoryKeywords: [:],
    frequentLocations: [],
    vibeDescription: "まだ十分に学習されていません。"
  )

  // Core MLカテゴリごとの好みを定義
  func getKeywords(for category: String) -> [String] {
    return categoryKeywords[category] ?? interests
  }
}

// MARK: - TimelinePost
/// タイムライン投稿
struct TimelinePost: Codable, Identifiable {
  let id: String
  var userId: String
  var eventId: String
  var content: String  // 匿名化された予定内容
  var createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id, content
    case userId = "user_id"
    case eventId = "event_id"
    case createdAt = "created_at"
  }
}

// MARK: - Auth
/// ログインリクエスト
struct LoginRequest: Codable {
  var email: String
  var password: String
}

/// 登録リクエスト
struct RegisterRequest: Codable {
  var username: String
  var email: String
  var password: String
}

struct AuthResponse: Codable {
  var token: String
  var user: User
}

// MARK: - Memo
/// ユーザーメモ (AI学習用データソース)
struct Memo: Codable, Identifiable {
  var id: UUID
  var content: String
  var date: Date
  
  init(id: UUID = UUID(), content: String, date: Date = Date()) {
    self.id = id
    self.content = content
    self.date = date
  }
}
