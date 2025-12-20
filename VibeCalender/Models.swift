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
// MARK: - ProfileKeyword
struct ProfileKeyword: Codable, Hashable, Sendable {
  var name: String
  var category: String
  var locations: [String]
}

// MARK: - UserProfile
/// ユーザーの行動嗜好プロファイル (AI学習用)
struct UserProfile: Codable {
  var keywords: [ProfileKeyword]  // 構造化されたキーワード（趣味・興味）
  var routines: [String]  // 学校やバイトなどの固定ルーチン（生成には使わない）
  var masterKeywords: [String] = []  // オンボーディングで生成されたコア・インタレスト
  var masterNarrative: String = ""  // オンボーディングから生成された「人物像」の自然言語記述
  var vibeDescription: String  // 全体的な雰囲気

  var interests: [String] {
    keywords.map { $0.name }
  }

  static let empty = UserProfile(
    keywords: [],
    routines: [],
    masterKeywords: [],
    vibeDescription: "まだ十分に学習されていません。"
  )
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
