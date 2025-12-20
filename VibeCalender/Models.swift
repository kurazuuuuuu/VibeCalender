//
//  Models.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Foundation

// MARK: - User
/// ユーザー情報
struct User: Codable, Identifiable, Sendable {
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
struct ScheduleEvent: Codable, Identifiable, Sendable {
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
/// 学習データ（ユーザー傾向エンコード）
struct UserProfile: Codable, Sendable {
  var userId: String
  var encodedPreferences: String  // LLM用エンコード済みデータ
  var lastUpdated: Date

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case encodedPreferences = "encoded_preferences"
    case lastUpdated = "last_updated"
  }
}

// MARK: - TimelinePost
/// タイムライン投稿
struct TimelinePost: Codable, Identifiable, Sendable {
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

/// 認証レスポンス
struct AuthResponse: Codable {
  var token: String
  var user: User
}
