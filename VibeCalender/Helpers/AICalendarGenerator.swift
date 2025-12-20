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
    // 1. Core ML: 時系列データからのカテゴリ予測 (あくまでヒントとして取得)
    let predictedCategory = predictor.predictCategory(for: date) ?? "Unknown"

    // 2. Profile: ユーザーの全プロファイル（ルーチン + 興味）の取得
    let profile = analyzer.loadProfile()

    // プロンプト用のリスト整形
    let routinesList = profile.routines.isEmpty ? "なし" : profile.routines.joined(separator: ", ")

    let interestsList: String
    var interestItems: [String] = []

    // 1. Dynamic Keywords (Learning)
    if !profile.keywords.isEmpty {
      let dynamicItems = profile.keywords.map { keyword in
        let locs =
          keyword.locations.isEmpty ? "" : " (候補地: \(keyword.locations.joined(separator: "/")))"
        return "- [Learned] \(keyword.name) [\(keyword.category)]\(locs)"
      }
      interestItems.append(contentsOf: dynamicItems)
    }

    // 2. Master Keywords (Onboarding)
    if !profile.masterKeywords.isEmpty {
      let masterItems = profile.masterKeywords.map { keyword in
        return "- [Core Interest] \(keyword) (ユーザー自身が強く希望している分野)"
      }
      interestItems.append(contentsOf: masterItems)
    }

    interestsList = interestItems.isEmpty ? "なし" : interestItems.joined(separator: "\n")

    // 3. Foundation Model: 生成
    // プロンプトの構築（LLM主導型）
    let prompt = """
      あなたはユーザー自身（の意思決定エージェント）です。
      「現在の日時」「過去の傾向(CoreML予測)」「ユーザープロファイル」に基づいて、
      **今、カレンダーに入れるべき最適な予定（1件）** を決定・生成してください。

      【入力情報】
      - 日時: \(date.formatted(date: .complete, time: .omitted))
      - AI予測カテゴリ(参考): \(predictedCategory)

      【ユーザープロファイル】
      [Routines: 義務・固定]
      \(routinesList)

      [Interests: 興味・関心]
      \(interestsList)

      [Vibe: 雰囲気]
      \(profile.vibeDescription)

      【意思決定プロセス】
      1. **RoutinesかInterestsか**:
         - まず、この日時が「Routines（学校、バイト等）」を入れるべき時間帯か判断してください。
         - もし自由時間なら、CoreMLの予測にとらわれず、「Interests」の中から最適なものを選んでください。
         - CoreMLが「Study」と予測しても、休日なら無視して「Interests」を優先するなど、人間らしい柔軟な判断をしてください。

      2. **予定の具体化**:
         - 「Interests」から選ぶ場合は、単にキーワードを使うのではなく、具体的なアクションに膨らませてください。
         - 場所が記録されている場合はそれを活用し、なければ「近所の公園」「駅前のカフェ」など汎用的な表現を使ってください。
         - 駅や店の具体的な固有名がある場合は**絶対に使用しないでください**人物名に関しても匿名化してください。
         - ストーリー性を持たせ、「[場所]で[行動A]をして、そのあと[行動B]する」のような形式にしてください。
         - **若者らしい言葉遣いを心がけてください。（例：チルい、アツい、ヤバい）**

      【出力要件】
      - 出力は以下のJSON形式のみ。
      - **理由は不要です。予定の内容（description）のみ記述してください。**

      # 以下はあくまで一例です。タイトル・時間・概要など絶対に流用せず、条件に従って生成してください。
      【JSON出力例】
      {
        "title": "カフェ読書",
        "startHour": 14,
        "startMinute": 0,
        "endHour": 17,
        "endMinute": 0,
        "description": "最近見つけた隠れ家カフェで、積読していた技術書を読む。そのあと近くの川沿いを散歩してリフレッシュする。"
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
        category: predictedCategory,  // CoreMLの結果はメタデータとして保持（分析用）
        notes: llmEvent.description,
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
