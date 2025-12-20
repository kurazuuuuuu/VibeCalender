//
//  VibeCalenderApp.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import SwiftUI

@main
struct VibeCalenderApp: App {
  @StateObject private var eventManager = EventManager()
  @StateObject private var appConfig = AppConfig.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(eventManager)
        .environmentObject(appConfig)
        .preferredColorScheme(.light)
        .onAppear {
          // アプリ起動時の初期処理
          //          performBackgroundTraining()
        }
        .onChange(of: eventManager.isAuthorized) { isAuthorized in
          if isAuthorized {
            //          performBackgroundTraining()
          }
        }
    }
  }

  // MARK: - Background Training

  private func performBackgroundTraining() {
    guard eventManager.isAuthorized else { return }

    Task {
      // 過去3ヶ月〜未来1ヶ月のデータを学習に使用
      let calendar = Calendar.current
      let now = Date()
      guard let startDate = calendar.date(byAdding: .month, value: -3, to: now),
        let endDate = calendar.date(byAdding: .month, value: 1, to: now)
      else { return }

      let events = eventManager.fetchEvents(from: startDate, to: endDate)

      // 学習実行 (重い処理なのでデタッチされたタスクで実行推奨だが、
      // EventPredictor.train内ですでに非同期API(MLUpdateTask)を使用しているためそのまま呼ぶ)
      print("👻 Starting background training with \(events.count) events...")
      await EventPredictor.shared.train(with: events)

      // 4. プロファイル分析 (LLM/Keyword)
      print("🧠 Analyzing user profile...")
      await UserProfileAnalyzer.shared.analyzeAndSaveProfile(from: events)
    }
  }
}
