import Combine
//
//  MemoManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//
import Foundation
import SwiftUI

class MemoManager: ObservableObject {
  static let shared = MemoManager()

  @Published var memos: [Memo] = []

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

  func generateMockMemos() {
    let mockContents = [
      "面白いカフェ見つけた。隠れ家っぽくて良い。",
      "最新のiPad Proが欲しいけど高すぎる...迷う。",
      "週末は高尾山にハイキングに行こうかな。",
      "映画「Dune」の映像美がすごかった。",
      "新しい服買いに行きたい。渋谷あたりで。",
      "Swiftのasync/await、やっと理解できてきた。",
      "積読が増えていく一方だ...今週末こそ読む。",
      "ボードゲーム会、めちゃくちゃ楽しかった。",
      "美味しいラーメン屋を開拓したい。",
      "部屋の模様替えをしたい。北欧風の家具探そう。",
      "旅行行きたいなー。温泉でゆっくりしたい。",
    ]

    for content in mockContents {
      addMemo(content: content)
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
