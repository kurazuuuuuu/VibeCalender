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

  private let profileFileName = "user_profile_data.json"
  private var model: SystemLanguageModel { .default }
  
  private var profileURL: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(profileFileName)
  }

  /// イベント履歴を分析してプロファイルを更新・保存する
  func analyzeAndSaveProfile(from events: [EKEvent]) async {
    let newProfile = await generateProfile(from: events)
    saveProfile(newProfile)
  }

  /// 保存されたプロファイルを取得
  func loadProfile() -> UserProfile {
    do {
        if FileManager.default.fileExists(atPath: profileURL.path) {
            let data = try Data(contentsOf: profileURL)
            return try JSONDecoder().decode(UserProfile.self, from: data)
        }
    } catch {
        print("Failed to load profile from file: \(error)")
    }
    return .empty
  }

  // MARK: - Analysis Logic (LLM)

  private func generateProfile(from events: [EKEvent]) async -> UserProfile {
    // データ収集
    let recentEvents = events.prefix(50).compactMap { $0.title }.joined(separator: ", ")
    let memos = MemoManager.shared.getAllMemos().prefix(20).map { $0.content }.joined(
      separator: "\n")

    let prompt = """
      あなたはユーザーの行動分析を行うAIです。
      以下の「イベント履歴」と「メモ」を分析し、JSON形式でプロファイルを出力してください。

      【重要: 分離指示】
      - **「ルーチン」**には、学校、授業、アルバイト、定期的な業務など、義務的・固定的な予定を分類してください。
      - **「キーワード（興味）」**には、趣味、遊び、食事、娯楽など、ユーザーの「Vibe（雰囲気）」を構成する要素のみを入れてください。ルーチンはここには含めないでください。

      【分析対象】
      Events: \(recentEvents)
      Memos: \(memos)

      【出力スキーマ】
      {   
          "routines": ["数学の授業", "コンビニバイト", ...],
          "keywords": [
              {
                  "name": "キーワード1",
                  "category": "ジャンル",
                  "locations": ["頻出する場所1", ...]
              },
              {
                  "name": "キーワード2",
                  "category": "ジャンル",
                  "locations": ["頻出する場所2", ...]
              }
          ],
          "vibe": "ユーザーの行動傾向や雰囲気を表す一言（ルーチンを除いた性格分析）"
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

      // 構造体でパース
      struct LLMProfileResponse: Codable {
        let routines: [String]
        let keywords: [ProfileKeyword]
        let vibe: String
      }

      let result = try JSONDecoder().decode(LLMProfileResponse.self, from: data)

      print("🧠 LLM Analysis Complete:\nKeywords: \(result.keywords.count)\nRoutines: \(result.routines.count)\nVibe: \(result.vibe)")

      return UserProfile(
        keywords: result.keywords,
        routines: result.routines,
        vibeDescription: result.vibe
      )

    } catch {
      print("LLM Profile Analysis Error: \(error)")
      return .empty
    }
  }

  private func saveProfile(_ profile: UserProfile) {
    do {
        let data = try JSONEncoder().encode(profile)
        try data.write(to: profileURL)
        print("User profile saved to: \(profileURL.path)")
    } catch {
        print("Failed to save profile to file: \(error)")
    }
  }
}
