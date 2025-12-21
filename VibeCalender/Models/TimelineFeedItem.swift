//
//  TimelineFeedItem.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/20.
//

import Foundation
import SwiftUI

/// タイムライン表示用 View Model
/// TimelinePost (データ) + User (投稿者情報) を統合してUIに提供する
struct TimelineFeedItem: Identifiable, Hashable, Sendable {
  let id: String
  let authorName: String
  let authorID: String
  let content: String
  let timestamp: Date
  var likes: Int
  let replies: Int
  let category: String
  var selectedReaction: ReactionType?
  var iconUrl: String?
  var eventDate: String?
  var colorHex: String?

  init(
    id: String, authorName: String, authorID: String, content: String, timestamp: Date, likes: Int,
    replies: Int, category: String, selectedReaction: ReactionType? = nil,
    iconUrl: String? = nil, eventDate: String? = nil, colorHex: String? = nil
  ) {
    self.id = id
    self.authorName = authorName
    self.authorID = authorID
    self.content = content
    self.timestamp = timestamp
    self.likes = likes
    self.replies = replies
    self.category = category
    self.selectedReaction = selectedReaction
    self.iconUrl = iconUrl
    self.eventDate = eventDate
    self.colorHex = colorHex
  }

  init(
    post: TimelinePost, user: User, likes: Int = 0, replies: Int = 0,
    category: String? = nil, selectedReaction: ReactionType? = nil
  ) {
    self.id = post.id
    self.authorName = user.username
    self.authorID = "@" + user.id
    self.content = post.content
    self.timestamp = post.createdAt
    self.likes = likes
    self.replies = replies
    self.category = category ?? post.category ?? "日常"
    self.selectedReaction = selectedReaction
    self.iconUrl = post.iconUrl
    self.eventDate = post.eventDate
    self.colorHex = post.colorHex
  }

  // MARK: - Mock Data Helper
  static func mockItems() -> [TimelineFeedItem] {
    let now = Date()

    // Mock Users
    let user1 = User(id: "kana_dev", username: "Kanaha", email: "kana@example.com", createdAt: now)
    let user2 = User(id: "kogayuto", username: "Yuto", email: "yuto@example.com", createdAt: now)
    let user3 = User(
      id: "antigravity", username: "AI Bot", email: "bot@example.com", createdAt: now)

    // Mock Posts
    let post1 = TimelinePost(
      id: UUID().uuidString, userId: user1.id, eventId: "evt1",
      content: "SwiftUIとUIKitの連携、結構面白いね！👻 #iosdev", createdAt: now)
    let post2 = TimelinePost(
      id: UUID().uuidString, userId: user2.id, eventId: "evt2",
      content: "DAWNTextすごい... 絵文字もバッチリ表示できる ✨🎉", createdAt: now.addingTimeInterval(-3600))
    let post3 = TimelinePost(
      id: UUID().uuidString, userId: user3.id, eventId: "evt3",
      content: "This implementation uses UIHostingConfiguration. It's powerful!",
      createdAt: now.addingTimeInterval(-7200))

    return [
      TimelineFeedItem(
        post: post1, user: user1, likes: 12, replies: 2, category: "仕事",
        selectedReaction: .thumbsUp),
      TimelineFeedItem(post: post2, user: user2, likes: 25, replies: 5, category: "遊び"),
      TimelineFeedItem(
        post: post3, user: user3, likes: 99, replies: 0, category: "日常", selectedReaction: .point),
    ]
  }
}

enum ReactionType: String, CaseIterable, Codable, Sendable {
  case point
  case thumbsUp
  case hand
  case pinch

  var emoji: String {
    switch self {
    case .point: return "🫵"
    case .thumbsUp: return "👍"
    case .hand: return "✋"
    case .pinch: return "🤏"
    }
  }
}

enum PostCategory: String, CaseIterable, Codable, Sendable {
  case work = "仕事"
  case play = "遊び"
  case school = "学校"
  case daily = "日常"

  var color: Color {
    switch self {
    case .work: return .blue
    case .play: return .orange
    case .school: return .green
    case .daily: return .gray
    }
  }

  var icon: String {
    switch self {
    case .work: return "briefcase.fill"
    case .play: return "gamecontroller.fill"
    case .school: return "book.closed.fill"
    case .daily: return "sun.max.fill"
    }
  }
}
