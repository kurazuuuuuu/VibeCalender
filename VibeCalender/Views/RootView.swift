//
//  RootView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/21.
//

import SwiftUI

struct RootView: View {
  @EnvironmentObject var appConfig: AppConfig
  @EnvironmentObject var eventManager: EventManager
  @EnvironmentObject var authManager: AuthManager

  @State private var isCapabilityChecked = false
  @State private var showSessionExpiredAlert = false
  @Environment(\.scenePhase) var scenePhase

  var body: some View {
    ZStack {
      if isCapabilityChecked {
        if authManager.isAuthenticated {
          ContentView()
            .preferredColorScheme(.light)
            .onAppear {
              // アプリ起動時の初期処理
            }
            .onChange(of: eventManager.isAuthorized) { isAuthorized in
              if isAuthorized {
                // performBackgroundTraining()
              }
            }
        } else {
          AuthRootView()
            .preferredColorScheme(.light)
        }
      } else {
        CapabilityCheckView(isOptimized: $isCapabilityChecked)
      }
    }
    .alert("セッション有効期限切れ", isPresented: $showSessionExpiredAlert) {
      Button("OK") {
        AuthManager.shared.logout()
      }
    } message: {
      Text("セッションの有効期限が切れました。\n再度ログインしてください。")
    }
    .onChange(of: scenePhase) { newPhase in
      if newPhase == .active && authManager.isAuthenticated {
        Task {
          let isValid = await APIClient.shared.validateSession()
          await MainActor.run {
            if !isValid {
              print("Session invalid, showing alert...")
              showSessionExpiredAlert = true
            } else {
              print("Session valid.")
            }
          }
        }

        // バックグラウンド学習のトリガー等もここに記述可能
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

      print("👻 Starting background training with \(events.count) events...")
      await EventPredictor.shared.train(with: events)

      // 4. プロファイル分析 (LLM/Keyword)
      print("🧠 Analyzing user profile...")
      await UserProfileAnalyzer.shared.analyzeAndSaveProfile(from: events)
    }
  }
}

#Preview {
  RootView()
    .environmentObject(AppConfig.shared)
    .environmentObject(EventManager())
    .environmentObject(AuthManager.shared)
}
