//
//  UserProfileAnalyzer.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import EventKit
import Foundation
import FoundationModels

/// 過去のイベントからユーザープロファイルを生成するクラス
/// (LLM Foundational Model を使用して高度な分析を行う)
class UserProfileAnalyzer {
  static let shared = UserProfileAnalyzer()

  private let profileKey = "user_profile_data"
  private var model: SystemLanguageModel { .default }

  /// イベント履歴を分析してプロファイルを更新・保存する
  func analyzeAndSaveProfile(from events: [EKEvent]) async {
    let newProfile = await generateProfile(from: events)
    saveProfile(newProfile)
  }

  /// 保存されたプロファイルを取得
  func loadProfile() -> UserProfile {
    if let data = UserDefaults.standard.data(forKey: profileKey),
      let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
    {
      return profile
    }
    return .empty
  }

  // MARK: - Analysis Logic (LLM)

  private func generateProfile(from events: [EKEvent]) async -> UserProfile {
    // データ収集
    let recentEvents = events.prefix(30).compactMap { $0.title }.joined(separator: ", ")
    let memos = MemoManager.shared.getAllMemos().prefix(10).map { $0.content }.joined(separator: "\n")
    
    let prompt = """
    あなたはユーザーの行動分析を行うAIです。
    以下の「イベント履歴」と「メモ」を分析し、JSON形式でプロファイルを出力してください。
    
    【分析対象】
    Events: \(recentEvents)
    Memos: \(memos)
    
    【出力スキーマ】
    {
        "interests": ["キーワード1", "キーワード2", ...], // ユーザーの興味関心（上位10個, 抽象概念含む）
        "vibe": "ユーザーの行動傾向や雰囲気を表す一言（例: アクティブで自己研鑽に熱心）",
        "locations": ["頻出する場所1", ...] // 明示的な場所の名前があれば
    }
    
    必ずJSON文字列のみを返してください。Markdown記法は不要です。
    """

    do {
        // LLM生成
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)
        let jsonString = response.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        
        guard let data = jsonString.data(using: .utf8) else { return .empty }
        
        // 簡易構造体でパース
        struct AnalysisResult: Codable {
            let interests: [String]
            let vibe: String
            let locations: [String]?
        }
        
        let result = try JSONDecoder().decode(AnalysisResult.self, from: data)
        
        print("🧠 LLM Analysis Complete:\nInterests: \(result.interests)\nVibe: \(result.vibe)")
        
        // カテゴリ分析はCore MLに任せるため、LLMからは除外（または簡易的に空で埋める）
        // ※ 本来はカテゴリもLLMで推定可能だが、既存コードとの整合性のため
        
        return UserProfile(
            interests: result.interests,
            categoryKeywords: [:], // LLM版では一旦空にする（必要ならロジック追加）
            frequentLocations: result.locations ?? [],
            vibeDescription: result.vibe
        )
        
    } catch {
        print("LLM Profile Analysis Error: \(error)")
        return .empty
    }
  }

  private func saveProfile(_ profile: UserProfile) {
    if let data = try? JSONEncoder().encode(profile) {
      UserDefaults.standard.set(data, forKey: profileKey)
    }
  }
}
