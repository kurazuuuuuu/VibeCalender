import Combine
//
//  MemoManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//
import Foundation
import FoundationModels
import SwiftUI

class MemoManager: ObservableObject {
  static let shared = MemoManager()

  @Published var memos: [Memo] = []

  private var model: SystemLanguageModel { .default }
  private let userDefaultsKey = "saved_memos"

  init() {
    loadMemos()
  }

  // MARK: - CRUD Operations

  func addMemo(content: String) {
    let newMemo = Memo(content: content)
    // 新しいメモを先頭に追加
    memos.insert(newMemo, at: 0)
    saveMemos()
  }

  func deleteMemo(at offsets: IndexSet) {
    memos.remove(atOffsets: offsets)
    saveMemos()
  }

  func getAllMemos() -> [Memo] {
    return memos
  }

  /// LLMを使用して「意識高い系」「多趣味な若者」風のモックメモを動的生成する
  func generateMockMemos() async {
    let prompt = """
      あなたは多趣味で好奇心旺盛な若者の「日記（メモ）」を代筆するAIです。
      以下のジャンルからランダムに組み合わせて、**ユニークで具体的なメモを10件** 生成してください。

      【ジャンル例】
      - カフェ巡り、映画、読書、テック、アウトドア、グルメ、ファッション、旅行、ゲーム、アート

      【要件】
      - 各行に1つのメモを出力してください（箇条書き記号は不要）。
      - 文体は短文の口語体（「〜したい」「〜だった」など）。
      - 具体的で「それっぽい」固有名詞や地名を入れるとベターです。
      - 出力は純粋なテキストのみ（JSONやMarkdownは不要）。

      【出力例】
      中目黒のスタバで新作のフラペチーノ飲んだ。甘すぎなくて良い。
      今週末こそ積読している技術書を消化する。
      """

    do {
      let session = LanguageModelSession(model: model)
      let response = try await session.respond(to: prompt)
      let content = response.content

      let lines = content.split(separator: "\n").map {
        String($0).trimmingCharacters(in: .whitespacesAndNewlines)
      }.filter { !$0.isEmpty }

      await MainActor.run {
        for line in lines.prefix(10) {
          addMemo(content: line)
        }
      }
      print("🤖 Generated \(lines.count) mock memos via LLM.")

    } catch {
      print("Failed to generate mock memos: \(error)")
      // Fallback
      let fallbackMemos = [
        "LLMの生成に失敗したけど、とりあえずカフェ行きたい。",
        "ネットワークエラーかな？週末は山に篭ろう。",
        "デバッグ中。SwiftUIのプレビューが重い。",
      ]
      await MainActor.run {
        for memo in fallbackMemos {
          addMemo(content: memo)
        }
      }
    }
  }

  // MARK: - Persistence

  private func saveMemos() {
    do {
      let data = try JSONEncoder().encode(memos)
      UserDefaults.standard.set(data, forKey: userDefaultsKey)
    } catch {
      print("Failed to save memos: \(error)")
    }
  }

  private func loadMemos() {
    guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

    do {
      memos = try JSONDecoder().decode([Memo].self, from: data)
    } catch {
      print("Failed to load memos: \(error)")
    }
  }
}
