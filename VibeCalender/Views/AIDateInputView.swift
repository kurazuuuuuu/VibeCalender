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

            Text("予定を追加")
              .font(.headline)

            Spacer()

            // レイアウト調整用ダミー
            Text("閉じる")
              .hidden()
          }
          .padding()

          Spacer()

          Text("いつの予定を作りたいですか？")
            .font(.title2)
            .fontWeight(.bold)

          DatePicker(
            "日付を選択",
            selection: $selectedDate,
            displayedComponents: [.date]
          )

          .datePickerStyle(.graphical)
          .environment(\.locale, Locale(identifier: "ja_JP"))
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.ultraThinMaterial)
              .glassEffect(.ai, in: RoundedRectangle(cornerRadius: 16))
          )
          .padding(.horizontal)

          Spacer()

          // Generate Button
          Button(action: performAIGeneration) {
            HStack {
              Image(systemName: "sparkles")
              Text("予定を追加する...？")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
              LinearGradient(
                colors: [.purple, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .clipShape(Capsule())
            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
            .overlay(
              Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
            )
          }
          .padding(.horizontal)
          .padding(.bottom, 20)
          .interactive()
        }
        .zIndex(0)
      }
    }
    .alert("勝手に予定を追加できません...", isPresented: $showError) {
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
          withStart: Date().addingTimeInterval(-180 * 24 * 3600),  // 過去半年
          end: Date().addingTimeInterval(180 * 24 * 3600),  // 未来半年
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
      handleError("勝手に予定を追加できませんでした...")
      return
    }

    withAnimation {
      loadingMessage = "勝手に予定を思いつきました...ッ！: \(generatedEvent.title)"
    }

    // 日付 (Year/Month/Day) を selectedDate から、時間 (Hour/Minute) を GeneratedEvent から取得して結合
    var calendar = Calendar.current
    calendar.timeZone = TimeZone.current  // ユーザーの現在地タイムゾーン

    let baseComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
    var finalComponents = DateComponents()
    finalComponents.year = baseComponents.year
    finalComponents.month = baseComponents.month
    finalComponents.day = baseComponents.day
    finalComponents.hour = generatedEvent.startHour
    finalComponents.minute = generatedEvent.startMinute

    var finalStartComponents = DateComponents()
    finalStartComponents.year = baseComponents.year
    finalStartComponents.month = baseComponents.month
    finalStartComponents.day = baseComponents.day
    finalStartComponents.hour = generatedEvent.startHour
    finalStartComponents.minute = generatedEvent.startMinute

    var finalEndComponents = DateComponents()
    finalEndComponents.year = baseComponents.year
    finalEndComponents.month = baseComponents.month
    finalEndComponents.day = baseComponents.day
    finalEndComponents.hour = generatedEvent.endHour
    finalEndComponents.minute = generatedEvent.endMinute

    let newStartDate = calendar.date(from: finalStartComponents) ?? selectedDate
    // 日付をまたぐ場合（終了時間が開始時間より前）は翌日に設定する安全策
    var newEndDate = calendar.date(from: finalEndComponents) ?? selectedDate
    if newEndDate < newStartDate {
      newEndDate = calendar.date(byAdding: .day, value: 1, to: newEndDate) ?? newEndDate
    }

    // 保存
    do {
      _ = try eventManager.createEvent(
        title: generatedEvent.title,
        startDate: newStartDate,
        endDate: newEndDate,
        notes: generatedEvent.notes,
        isAIGenerated: true,
        colorHex: generatedEvent.colorHex,
        category: generatedEvent.category
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
