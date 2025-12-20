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
    let category: PostCategory
    var selectedReaction: ReactionType?
    
    // MARK: - Initializer
    init(post: TimelinePost, user: User, likes: Int = 0, replies: Int = 0, category: PostCategory = .daily, selectedReaction: ReactionType? = nil) {
        self.id = post.id
        self.authorName = user.username
        self.authorID = "@" + user.id // 表示用IDフォーマット
        self.content = post.content
        self.timestamp = post.createdAt
        self.likes = likes
        self.replies = replies
        self.category = category
        self.selectedReaction = selectedReaction
    }
    
    // MARK: - Mock Data Helper
    static func mockItems() -> [TimelineFeedItem] {
        let now = Date()
        
        // Mock Users
        let user1 = User(id: "kana_dev", username: "Kanaha", email: "kana@example.com", createdAt: now)
        let user2 = User(id: "kogayuto", username: "Yuto", email: "yuto@example.com", createdAt: now)
        let user3 = User(id: "antigravity", username: "AI Bot", email: "bot@example.com", createdAt: now)
        
        // Mock Posts
        let post1 = TimelinePost(id: UUID().uuidString, userId: user1.id, eventId: "evt1", content: "SwiftUIとUIKitの連携、結構面白いね！👻 #iosdev", createdAt: now)
        let post2 = TimelinePost(id: UUID().uuidString, userId: user2.id, eventId: "evt2", content: "DAWNTextすごい... 絵文字もバッチリ表示できる ✨🎉", createdAt: now.addingTimeInterval(-3600))
        let post3 = TimelinePost(id: UUID().uuidString, userId: user3.id, eventId: "evt3", content: "This implementation uses UIHostingConfiguration. It's powerful!", createdAt: now.addingTimeInterval(-7200))
        
        return [
            TimelineFeedItem(post: post1, user: user1, likes: 12, replies: 2, category: .work, selectedReaction: .thumbsUp),
            TimelineFeedItem(post: post2, user: user2, likes: 25, replies: 5, category: .play),
            TimelineFeedItem(post: post3, user: user3, likes: 99, replies: 0, category: .daily, selectedReaction: .point)
        ]
    }
}

enum ReactionType: String, CaseIterable, Codable, Sendable {
    case point = "🫵"
    case thumbsUp = "👍"
    case hand = "✋"
    case pinch = "🤏"
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
