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

      print(
        "🧠 LLM Analysis Complete:\nKeywords: \(result.keywords.count)\nRoutines: \(result.routines.count)\nVibe: \(result.vibe)"
      )

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

  // MARK: - Onboarding Logic

  // MARK: - Onboarding Logic (3 Stages)

  /// Stage 1: 大分類（Broad Categories）の生成
  func generateStage1Categories() async -> [String] {
    let prompt = """
      ユーザーの趣味・関心を絞り込むための「大分類（Category）」をランダムに6個生成してください。

      【要件】
      - 一般的なカテゴリー名のみを使用してください。
      - 固有名詞は含めないでください。
      - **「アカデミック・学習」だけでなく、「遊び・エンタメ・リラックス」に関連する分野もバランスよく含めてください。**
      - **似通ったカテゴリーばかりにならないよう、広範囲な分野から選出してください。**
      - **前置きや説明文は不要です。リストのみを出力してください。**

      出力例:
      インドア, アウトドア, アート・クリエイティブ, テック・ガジェット, フード・グルメ, エンタメ・ポップカルチャー

      出力形式: カンマ区切りのリスト
      """
    return await generateList(
      prompt: prompt,
      fallback: ["インドア", "アウトドア", "アート", "テック", "グルメ", "エンタメ"])
  }

  /// Stage 2: 中分類（Specific Genres）の生成
  func generateStage2Genres(selectedCategories: [String]) async -> [String] {
    let input = selectedCategories.joined(separator: ", ")
    let prompt = """
      ユーザーは以下のカテゴリーに興味があります:
      \(input)

      これらに関連する具体的な「ジャンル（Genre）」を6個生成してください。

      【要件】
      - 「読書」「カフェ巡り」のような一般的な行動のジャンルにしてください。
      - 特定の地名、店名、施設名は使用せず、一般的な名称を使用してください。
      - **出力のジャンルが偏らないよう、多様な側面から提案してください。**
      - **前置きや説明文は不要です。リストのみを出力してください。**

      入力例: インドア, アート
      出力例: 読書, 映画鑑賞, イラスト描画, DIY, 美術館巡り, 写真

      出力形式: カンマ区切りのリスト
      """
    return await generateList(
      prompt: prompt,
      fallback: ["読書", "映画", "カフェ", "写真", "音楽", "ゲーム"])
  }

  /// Stage 3: 具体的な活動・興味（Actionable Keywords）の生成
  func generateStage3Keywords(selectedGenres: [String]) async -> [String] {
    let input = selectedGenres.joined(separator: ", ")
    let prompt = """
      ユーザーは以下のジャンルに興味があります:
      \(input)

      これを踏まえて、実際の行動につながる「具体的でニッチなキーワード」を6個生成してください。

      【要件】
      - **具体的な地名や店舗名は使用せず**、場所を示唆したい場合は「隠れ家」「近所の」「都心の」などの形容詞を使用してください。
      - ユーザーが休日の予定としてイメージしやすい具体的な行動やモノを挙げてください。
      - **単なる類語の羅列にならないよう、異なる角度からのキーワードを混ぜてください。**
      - **前置きや説明文は不要です。リストのみを出力してください。**

      入力例: 読書, カフェ
      出力例: スペシャルティコーヒー, 朝活, 古本屋巡り, Kindle, ジャズ喫茶, テラス席

      出力形式: カンマ区切りのリスト
      """
    return await generateList(prompt: prompt, fallback: selectedGenres)
  }

  /// 汎用的なリスト生成ヘルパー
  private func generateList(prompt: String, fallback: [String]) async -> [String] {
    do {
      let session = LanguageModelSession(model: model)
      let response = try await session.respond(to: prompt)
      let content = response.content

      // パース処理: カンマ、改行、読点で分割
      let separators = CharacterSet(charactersIn: ",\n、")
      let rawItems = content.components(separatedBy: separators)

      var items: [String] = []

      for item in rawItems {
        // クリーニング
        var cleaned = item.trimmingCharacters(in: .whitespacesAndNewlines)

        // 箇条書き記号の削除 (行頭の -, *, •, ・)
        if let range = cleaned.range(of: "^[-•*・]\\s*", options: .regularExpression) {
          cleaned.removeSubrange(range)
        }

        // フィルタリング (空文字、長すぎる文、説明文の除外)
        if cleaned.isEmpty { continue }
        if cleaned.count > 15 { continue }  // 15文字を超えるものはキーワードではないとみなす
        if cleaned.contains("出力例") { continue }
        if cleaned.contains("以下") && cleaned.contains("リスト") { continue }
        if cleaned.hasSuffix("ます") || cleaned.hasSuffix("です") { continue }  // 文末表現を除外

        items.append(cleaned)
      }

      if items.isEmpty { return fallback }

      // 重複排除して先頭6件を返す
      let uniqueItems = Array(NSOrderedSet(array: items)).map { $0 as! String }
      return Array(uniqueItems.prefix(6))

    } catch {
      print("Generation Error: \(error)")
      return fallback
    }
  }

  /// マスタープロファイルを保存
  func saveMasterProfile(words: [String], narrative: String = "") {
    var profile = loadProfile()
    profile.masterKeywords = words
    if !narrative.isEmpty {
      profile.masterNarrative = narrative
    }
    saveProfile(profile)
  }

  // MARK: - Narrative Generation (Task 15)

  /// 選択されたキーワードから「人物像（Narrative Profile）」を生成する
  func generateMasterNarrative(from keywords: [String]) async -> String {
    let input = keywords.joined(separator: ", ")
    let prompt = """
      以下はユーザーが「興味のあるもの」として選んだキーワードのリストです:
      \(input)

      これらを元に、このユーザーがどのような人物で、どのような時間の過ごし方を好むかを記述した「人物像（Narrative Profile）」を生成してください。
      AIのエージェントがこの人物になりきって予定を考えるための「設定資料」として使います。

      【要件】
      - 3〜5文程度の自然な日本語の文章で記述してください。
      - 単にキーワードを羅列するのではなく、「〜を好み、休日は〜して過ごすことが多い」のように、ライフスタイルや価値観にまで踏み込んで想像してください。
      - ポジティブで、ユーザーが読んで「私のことだ！」と思えるような共感性の高い文章にしてください。
      - 一人称は使わず、客観的な描写（〜という人物。）にしてください。

      出力例:
      静かな環境で知的な刺激を受けることを好む人物。休日はお気に入りのカフェで読書に没頭したり、美術館でアートに触れて感性を磨く時間を大切にしている。また、最新のガジェットやテクノロジーにも関心が高く、知的好奇心を満たす活動に喜びを感じる傾向がある。
      """

    do {
      let session = LanguageModelSession(model: model)
      let response = try await session.respond(to: prompt)
      return response.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } catch {
      print("Narrative Generation Error: \(error)")
      return ""
    }
  }
}
