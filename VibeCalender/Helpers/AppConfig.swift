//
//  AppConfig.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import Combine
import Foundation

class AppConfig: ObservableObject {
  static let shared = AppConfig()

  // デバッグモードフラグ
  @Published var isDebugMode: Bool = false

  // API環境切り替えフラグ (true: Localhost, false: Production)
  @Published var shouldUseLocalAPI: Bool = false

  // オンボーディング完了フラグ (UserDefaultsで永続化)
  @Published var isOnboardingCompleted: Bool {
    didSet {
      UserDefaults.standard.set(isOnboardingCompleted, forKey: "isOnboardingCompleted")
    }
  }

  // 認証済みフラグは AuthManager に移行

  var apiBaseURL: String {
    if shouldUseLocalAPI {
      return "http://localhost:8000/v1"
    } else {
      return "https://api.ptera-cup.krz-tech.net/v1"
    }
  }

  init() {
    self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
  }
}
