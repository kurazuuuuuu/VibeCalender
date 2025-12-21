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
    let colorHex: String?
  }

  struct LLMEventResponse: Codable {
    let title: String
    let category: String
    let colorHex: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let description: String
  }

  /// 指定された日時に対して、最適な予定を生成する (Async)
  func generateEvent(for date: Date) async -> GeneratedEvent? {
    // 1. Core ML: 時系列データからのカテゴリ予測 (参考情報として抽出、ログ出力)
    let predictedCategory = predictor.predictCategory(for: date) ?? "Unknown"
    print("DEBUG: CoreML Predicted Category: \(predictedCategory)")

    // 2. Profile: ユーザーの全プロファイル（ルーチン + 興味）の取得
    let profile = analyzer.loadProfile()

    // プロンプト用のリスト整形
    let routinesList = profile.routines.isEmpty ? "なし" : profile.routines.joined(separator: ", ")

    var interestItems: [String] = []
    if !profile.keywords.isEmpty {
      let dynamicItems = profile.keywords.map { keyword in
        let locs =
          keyword.locations.isEmpty ? "" : " (候補地: \(keyword.locations.joined(separator: "/")))"
        return "- [Learned] \(keyword.name) [\(keyword.category)]\(locs)"
      }
      interestItems.append(contentsOf: dynamicItems)
    }
    if !profile.masterKeywords.isEmpty {
      let masterItems = profile.masterKeywords.map { "- [Core Interest] \($0)" }
      interestItems.append(contentsOf: masterItems)
    }

    let interestsList = interestItems.isEmpty ? "なし" : interestItems.joined(separator: "\n")

    // 3. Foundation Model: 生成
    // プロンプトの構築（LLM主導型）
    let prompt = """
      あなたはユーザー自身（の意思決定エージェント）です。
      「現在の日時」「過去の傾向(CoreML予測)」「ユーザープロファイル」に基づいて、
      **今、カレンダーに入れるべき最適な予定（1件）** を決定・生成してください。

      【入力情報】
      - 日時: \(date.formatted(date: .complete, time: .omitted))
      - 推薦カテゴリ(周辺状況): \(predictedCategory)

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
         - もし自由時間なら、推薦カテゴリにとらわれず、「Interests」の中から最適なものを選んでください。

      2. **予定の具体化とビジュアル化**:
         - 予定の内容を、具体的かつ情景が浮かぶストーリーに膨らませてください。
         - **「category」フィールドには、その予定を象徴する、画像生成AIへの指示出しに適した短く具体的なキーワード（ビジュアルカテゴリ）を入れてください。**
         - 例: 「カフェ読書」→「落ち着いた木漏れ日のカフェで読書」、「ジム」→「ネオンが輝くスタイリッシュなスポーツジム」
         - **「colorHex」フィールドには、その予定の雰囲気に合うHexカラーコード（例: #FF5733）を1つ入れてください。**
         - **「一般」「日常」などの抽象的な言葉は絶対に使わないでください。**
         - 若者らしい言葉遣いを心がけてください。（例：チルい、アツい、ヤバい）

      【出力要件】
      - 出力は以下のJSON形式のみ。
      - **理由は不要です。予定の内容（description）のみ記述してください。**

      【JSON出力例】
      {
        "title": "カフェ読書（例）",
        "category": "落ち着いた木漏れ日のカフェで読書",
        "colorHex": "#E6D5B8",
        "startHour": 14,
        "startMinute": 0,
        "endHour": 17,
        "endMinute": 0,
        "description": "最近見つけた隠れ家カフェで、積読していた技術書を読む。そのあと近くの川沿いを散歩してリフレッシュする。"
      }

      以上があなたに与えるシステムプロンプトです。あくまでシステムプロンプトであり、JSON出力例に含まれる内容を流用することは禁止します。
      意思決定プロセスに従い予定を生成し、JSONでレスポンスしてください。
      """

    do {
      let session = LanguageModelSession(model: model)
      let response = try await session.respond(to: prompt)

      // クリーンアップとパース
      let jsonString = response.content
        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```", with: "")

      guard let data = jsonString.data(using: .utf8) else { throw URLError(.badServerResponse) }
      let llmEvent = try JSONDecoder().decode(LLMEventResponse.self, from: data)

      return GeneratedEvent(
        title: llmEvent.title,
        category: llmEvent.category,  // LLMが生成した詳細なカテゴリを優先
        notes: llmEvent.description,
        startHour: llmEvent.startHour,
        startMinute: llmEvent.startMinute,
        endHour: llmEvent.endHour,
        endMinute: llmEvent.endMinute,
        colorHex: llmEvent.colorHex
      )
    } catch {
      print("Foundation Model Generation Error: \(error). Falling back to rule-based generation.")
      return generateFallbackEvent(for: date, category: predictedCategory)
    }
  }

  /// ルールベースの簡易生成 (LLMが利用できない場合)
  private func generateFallbackEvent(for date: Date, category: String) -> GeneratedEvent {
    let hour = Calendar.current.component(.hour, from: date)
    let isWeekend = Calendar.current.isDateInWeekend(date)

    // 時間帯と曜日による簡易分岐
    let title: String
    let description: String
    let durationHours: Int
    let colorHex: String

    if isWeekend {
      if hour < 12 {
        title = "カフェでリラックス"
        description = "近所のカフェでゆっくりコーヒーを飲みながら、一週間の疲れを癒す。"
        durationHours = 2
        colorHex = "#E6D5B8"
      } else if hour < 18 {
        title = "ショッピング"
        description = "気になっていたお店を巡って、新しいアイテムを探す。"
        durationHours = 3
        colorHex = "#FFCC33"
      } else {
        title = "映画鑑賞"
        description = "自宅で気になっていた映画を観て過ごす。"
        durationHours = 2
        colorHex = "#333366"
      }
    } else {
      // 平日
      if hour >= 18 {
        title = "ジムでトレーニング"
        description = "仕事終わりに軽く汗を流してリフレッシュする。"
        durationHours = 1
        colorHex = "#FF6666"
      } else {
        title = "集中作業"
        description = "カフェや図書館で集中してタスクを片付ける。"
        durationHours = 2
        colorHex = "#6699CC"
      }
    }

    return GeneratedEvent(
      title: title,
      category: category,
      notes: "\(description) (Auto-generated fallback)",
      startHour: hour,
      startMinute: 0,
      endHour: hour + durationHours,
      endMinute: 0,
      colorHex: colorHex
    )
  }
}
