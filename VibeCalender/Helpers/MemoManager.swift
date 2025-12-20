//
//  MemoManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//
import Foundation
import Combine
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
