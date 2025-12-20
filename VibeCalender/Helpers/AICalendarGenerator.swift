import Foundation
import FoundationModels

/// Foundation Models Framework を使用して予定を生成する
class AICalendarGenerator {
  static let shared = AICalendarGenerator()

  private let analyzer = UserProfileAnalyzer.shared
  private let predictor = EventPredictor.shared

  // モデルへのセッションを保持（文脈維持のためだが、今回は単発生成）
  private var model: SystemLanguageModel { .default }

  struct GeneratedEvent {
    let title: String
    let category: String
    let notes: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
  }

  struct LLMEventResponse: Codable {
    let title: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let description: String
  }

  /// 指定された日時に対して、最適な予定を生成する (Async)
  func generateEvent(for date: Date) async -> GeneratedEvent? {
    // 1. Core ML: 時系列データからのカテゴリ予測
    guard let predictedCategory = predictor.predictCategory(for: date) else {
      return nil
    }

    // 2. Profile: ユーザーの嗜好データの取得
    let profile = analyzer.loadProfile()

    // 3. Foundation Model: 生成
    // プロンプトの構築
    let prompt = """
      あなたはユーザー自身です。
      以下の「文脈」と「プロファイル」に基づいて、ユーザーが実際に遂行できるカレンダーに追加するプランを1つ追加してください。

      【入力情報】
      - 予想カテゴリ: \(predictedCategory)
      - ユーザーの興味: \(profile.interests.joined(separator: ", "))
      - 雰囲気(Vibe): \(profile.vibeDescription)
      - 日時: \(date.formatted(date: .complete, time: .omitted))

      【重要: 脱・退屈宣言】
      - 「三者面談」「授業」「バイト」などの**義務的なキーワードは可能な限り無視**してください。もっと自由で楽しい時間を優先してください。
      - 単調な予定はNGです。**「場所Aで〇〇して、そのあと場所Bで××する」**という風に、移動を含めたストーリー性のある内容にしてください。

      【指示: 場所と表現】
      - **特定の地名（〇〇店など）は避け、汎用的な表現（「近所の公園」「駅前のカフェ」「川沿い」など）を使用してください。**
      - **ゲーム名や作品名などは匿名化の例外となります。**
      - 開始時刻と終了時刻は十分な時間を確保してください。例示の時間にとらわれず自由に設定してください。
      - 出力は必ず以下のJSON形式のみで行ってください。

      【出力例】
      {
        "title": "人間観察",
        "startHour": 11,
        "startMinute": 0,
        "endHour": 14,
        "endMinute": 30,
        "description": "まずは趣味の人間観察をする。その足で一番近くのラーメン屋に特攻し、一番辛いメニューを頼んで己の生存本能を呼び覚ます。"
      }
      """

    do {
      let session = LanguageModelSession(model: model)
      let response = try await session.respond(to: prompt)

      // クリーンアップとパース
      let jsonString = response.content
        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")

      guard let data = jsonString.data(using: .utf8) else { return nil }
      let llmEvent = try JSONDecoder().decode(LLMEventResponse.self, from: data)

      return GeneratedEvent(
        title: llmEvent.title,
        category: predictedCategory,
        notes: llmEvent.description + "\n(Based on \(predictedCategory))",
        startHour: llmEvent.startHour,
        startMinute: llmEvent.startMinute,
        endHour: llmEvent.endHour,
        endMinute: llmEvent.endMinute
      )
    } catch {
      print("Foundation Model Generation Error: \(error)")
      return nil
    }
  }
}
