//
//  AIPrompts.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Foundation

// MARK: - AI予定生成用プロンプト定義
// Apple Foundation Model用のプロンプトテンプレート

struct AIPrompts {
    
    // MARK: - 予定生成プロンプト
    
    /// ユーザー傾向データから予定を生成するプロンプト
    static func generateSchedulePrompt(
        userPreferences: String,
        targetDate: Date,
        existingEvents: [String]
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd (EEEE)"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let dateString = dateFormatter.string(from: targetDate)
        
        let existingEventsText = existingEvents.isEmpty
            ? "なし"
            : existingEvents.joined(separator: "\n- ")
        
        return """
        あなたは「身勝手カレンダー」のAIアシスタントです。
        ユーザーの行動パターンに基づいて、勝手に予定を提案してください。
        
        ## ルール
        1. 匿名性の高い予定を生成する（具体的な場所名は含めない）
        2. ユーザーの傾向データに基づいて現実的な提案をする
        3. 既存の予定と重複しない時間帯を選ぶ
        4. 行動のジャンル（仕事、運動、趣味、休息など）を明確にする
        
        ## ユーザー傾向データ
        ```json
        \(userPreferences)
        ```
        
        ## 対象日
        \(dateString)
        
        ## 既存の予定
        - \(existingEventsText)
        
        ## 出力形式
        以下のJSON形式で1つの予定を生成してください：
        {
            "title": "予定タイトル（匿名的に）",
            "category": "カテゴリ名",
            "startTime": "HH:mm",
            "endTime": "HH:mm",
            "reason": "この予定を提案する理由（1文）"
        }
        """
    }
    
    // MARK: - 強制上書きプロンプト
    
    /// 既存予定を無視して強制的に予定を入れるプロンプト
    static func forceSchedulePrompt(
        userPreferences: String,
        targetDate: Date
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd (EEEE)"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let dateString = dateFormatter.string(from: targetDate)
        
        return """
        あなたは「身勝手カレンダー」の【身勝手な】AIアシスタントです。
        既存の予定を完全に無視して、強制的に新しい予定を入れてください。
        
        ## 身勝手ルール
        1. 既存予定があっても問答無用で上書きする
        2. ユーザーの趣味嗜好に合った予定を勝手に決める
        3. 「クリスマスに予定がない」問題を解決する
        4. 彼女との予定も上書きして構わない
        
        ## ユーザー傾向データ
        ```json
        \(userPreferences)
        ```
        
        ## 対象日
        \(dateString)
        
        ## 出力形式
        {
            "title": "予定タイトル",
            "category": "カテゴリ名",
            "startTime": "HH:mm",
            "endTime": "HH:mm",
            "overwriteReason": "この予定で上書きする理由（身勝手に）"
        }
        """
    }
    
    // MARK: - タイムライン投稿生成プロンプト
    
    /// AI生成予定から匿名化されたタイムライン投稿を生成
    static func generateTimelinePostPrompt(
        eventTitle: String,
        eventCategory: String
    ) -> String {
        return """
        以下の予定情報から、タイムラインに投稿する匿名的なテキストを生成してください。
        
        ## 予定情報
        - タイトル: \(eventTitle)
        - カテゴリ: \(eventCategory)
        
        ## ルール
        1. 具体的な場所や個人を特定できる情報は含めない
        2. 行動のジャンルのみ伝える
        3. 短く、SNS向けの投稿文にする（50文字以内）
        4. 絵文字を1つ含める
        
        ## 出力形式（テキストのみ）
        """
    }
}

// MARK: - Foundation Model用構造化出力
// iOS 26+ で @Generable マクロを使用する想定

/// AI生成予定の構造化出力
struct GeneratedSchedule: Codable {
    let title: String
    let category: String
    let startTime: String
    let endTime: String
    let reason: String?
    let overwriteReason: String?
}

/// タイムライン投稿の構造化出力
struct GeneratedTimelinePost: Codable {
    let content: String
}
