//
//  MemoListView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import SwiftUI

struct MemoListView: View {
  @StateObject private var memoManager = MemoManager.shared
  @State private var showingAddSheet = false
  @State private var newMemoContent = ""

  var body: some View {
    NavigationView {
      List {
        if memoManager.memos.isEmpty {
          Text("まだメモはありません。\n右上の＋ボタンから、今の気分ややりたいことを記録してみましょう！")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .listRowBackground(Color.clear)
        }

        ForEach(memoManager.memos) { memo in
          VStack(alignment: .leading, spacing: 8) {
            Text(memo.content)
              .font(.body)
              .lineLimit(nil)

            Text(memo.date.formatted(date: .numeric, time: .shortened))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
        .onDelete(perform: memoManager.deleteMemo)
      }
      .navigationTitle("メモ & 気分")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { showingAddSheet = true }) {
            Image(systemName: "plus")
          }
        }
      }
      .sheet(isPresented: $showingAddSheet) {
        NavigationStack {
          VStack {
            TextEditor(text: $newMemoContent)
              .padding()
              .background(Color(.secondarySystemBackground))
              .cornerRadius(12)
              .padding()

            Spacer()
          }
          .navigationTitle("新しいメモ")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("キャンセル") {
                showingAddSheet = false
                newMemoContent = ""
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("保存") {
                if !newMemoContent.isEmpty {
                  memoManager.addMemo(content: newMemoContent)
                  showingAddSheet = false
                  newMemoContent = ""
                }
              }
              .disabled(newMemoContent.isEmpty)
            }
          }
        }
        .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  MemoListView()
}
