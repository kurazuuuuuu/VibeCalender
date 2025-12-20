//
//  ContentView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var eventManager: EventManager

  var body: some View {
    Group {
      if eventManager.isAuthorized {
        let _ = print("🚀 ContentView: showing MainTabView")
        MainTabView()
      } else {
        let _ = print("🚀 ContentView: showing AuthorizationView")
        // 認証待ち画面
        authorizationView
      }
    }
  }

  private var authorizationView: some View {
    VStack(spacing: 20) {
      Image(systemName: "calendar.badge.exclamationmark")
        .font(.system(size: 60))
        .foregroundColor(.orange)

      Text("カレンダーへのアクセスを許可")
        .font(.title2)
        .fontWeight(.bold)

      Text(eventManager.statusMessage)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Button(action: openSettings) {
        Text("設定を開く")
          .font(.headline)
          .foregroundColor(.white)
          .padding(.horizontal, 32)
          .padding(.vertical, 12)
          .background(Color.blue)
          .cornerRadius(12)
      }
    }
    .padding(32)
  }

  private func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(EventManager())
}
