//
//  AuthManager.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/21.
//

import Combine
import Foundation
import SwiftUI

class AuthManager: ObservableObject {
  static let shared = AuthManager()

  @Published var isAuthenticated: Bool = false
  @Published var currentUserId: String?

  private let tokenService = "com.vibecalender.auth.token"
  private let account = "currentUser"
  private let userIdAccount = "currentUserId"

  private init() {
    // 初期化時にKeychainからトークンとUserIDを確認
    if let token = KeychainHelper.shared.readString(service: tokenService, account: account),
      !token.isEmpty
    {
      self.isAuthenticated = true

      // UserIDも復元
      if let uid = KeychainHelper.shared.readString(service: tokenService, account: userIdAccount) {
        self.currentUserId = uid
      } else {
        // 下位互換性: KeychainになければUserDefaultsから探す（移行用）
        if let oldUid = UserDefaults.standard.string(forKey: "currentUserId") {
          self.currentUserId = oldUid
          // Keychainに移行
          KeychainHelper.shared.save(oldUid, service: tokenService, account: userIdAccount)
          UserDefaults.standard.removeObject(forKey: "currentUserId")
        }
      }
    } else {
      // 下位互換性: KeychainにないがUserDefaultsにある場合（移行用）
      if let oldToken = UserDefaults.standard.string(forKey: "authToken"), !oldToken.isEmpty {
        self.isAuthenticated = true
        KeychainHelper.shared.save(oldToken, service: tokenService, account: account)
        UserDefaults.standard.removeObject(forKey: "authToken")

        if let oldUid = UserDefaults.standard.string(forKey: "currentUserId") {
          self.currentUserId = oldUid
          KeychainHelper.shared.save(oldUid, service: tokenService, account: userIdAccount)
          UserDefaults.standard.removeObject(forKey: "currentUserId")
        }
      }
    }
  }

  // MARK: - Token Operations

  func getAuthToken() -> String? {
    return KeychainHelper.shared.readString(service: tokenService, account: account)
  }

  // MARK: - Auth Actions

  // ログインや登録成功時に呼ばれる
  func setAuthenticated(token: String, userId: String) {
    KeychainHelper.shared.save(token, service: tokenService, account: account)
    KeychainHelper.shared.save(userId, service: tokenService, account: userIdAccount)

    DispatchQueue.main.async {
      self.isAuthenticated = true
      self.currentUserId = userId
    }
  }

  func logout() {
    print("🔒 AuthManager: Logging out...")
    KeychainHelper.shared.delete(service: tokenService, account: account)
    KeychainHelper.shared.delete(service: tokenService, account: userIdAccount)
    URLCache.shared.removeAllCachedResponses()

    DispatchQueue.main.async {
      self.isAuthenticated = false
      self.currentUserId = nil
    }
  }
}
