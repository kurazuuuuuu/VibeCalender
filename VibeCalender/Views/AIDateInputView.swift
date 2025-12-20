//
//  AIDateInputView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import EventKit
import SwiftUI

struct AIDateInputView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var eventManager: EventManager

  @State private var selectedDate = Date()
  @State private var isLoading = false
  @State private var loadingMessage = "準備中..."
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    ZStack {
      // 背景
      Color(.systemBackground).ignoresSafeArea()

      if isLoading {
        AILoadingView(message: loadingMessage)
          .transition(.opacity)
          .zIndex(1)
      } else {
        VStack(spacing: 24) {
          // ヘッダー
          HStack {
            Button("閉じる") {
              dismiss()
            }
            .foregroundStyle(.secondary)

            Spacer()

            Text("AI 自動生成")
              .font(.headline)

            Spacer()

            // レイアウト調整用ダミー
            Text("閉じる")
              .hidden()
          }
          .padding()

          Spacer()

          Text("いつの予定を作りますか？")
            .font(.title2)
            .fontWeight(.bold)

          DatePicker(
            "日付を選択",
            selection: $selectedDate,
            displayedComponents: [.date, .hourAndMinute]
          )
          .datePickerStyle(.graphical)
          .environment(\.locale, Locale(identifier: "ja_JP"))
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color(.secondarySystemBackground))
          )
          .padding(.horizontal)

          Spacer()

          // Generate Button
          Button(action: performAIGeneration) {
            HStack {
              Image(systemName: "sparkles")
              Text("予定を生成する")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
          }
          .padding(.horizontal)
          .padding(.bottom, 20)
        }
        .zIndex(0)
      }
    }
    .alert("AI エラー", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  // MARK: - AI Generation Logic

  private func performAIGeneration() {
    withAnimation {
      isLoading = true
      loadingMessage = "勝手にカレンダー読み込み中..."
    }

    // 非同期で学習を実行してから生成
    Task {
      // 1. 最新データの取得
      let allEvents = eventManager.store.events(
        matching: eventManager.store.predicateForEvents(
          withStart: Date().addingTimeInterval(-365 * 24 * 3600),  // 過去1年
          end: Date(),
          calendars: nil
        )
      )

      // 2. オンデマンド学習 (Core ML Update)
      // 直前の変更を反映させる
      await EventPredictor.shared.train(with: allEvents)

      // 3. プロファイル分析 (Keyword Extraction)
      await UserProfileAnalyzer.shared.analyzeAndSaveProfile(from: allEvents)

      // 4. 生成実行 (Main Actor)
      await MainActor.run {
        Task {
            await generateEvent()
        }
      }
    }
  }

  private func generateEvent() async {
    // Hybrid Generation: Core ML + User Profile (LLM)
    guard let generatedEvent = await AICalendarGenerator.shared.generateEvent(for: selectedDate)
    else {
      handleError("AIが応答できませんでした。")
      return
    }

    withAnimation {
      loadingMessage = "ひらめきました: \(generatedEvent.title)"
    }

    let newStartDate = selectedDate
    let newEndDate = selectedDate.addingTimeInterval(generatedEvent.duration)

    // 保存
    do {
      _ = try eventManager.createEvent(
        title: generatedEvent.title,
        startDate: newStartDate,
        endDate: newEndDate,
        notes: generatedEvent.notes,
        isAIGenerated: true
      )

      // 完了待ち演出
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        withAnimation {
          isLoading = false
        }
        dismiss()
      }

    } catch {
      handleError("予定の保存に失敗しました: \(error.localizedDescription)")
    }
  }

  private func handleError(_ message: String) {
    withAnimation {
      isLoading = false
    }
    errorMessage = message
    showError = true
  }
}

#Preview {
  AIDateInputView()
    .environmentObject(EventManager())
}
