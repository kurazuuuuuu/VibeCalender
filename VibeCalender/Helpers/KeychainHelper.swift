//
//  KeychainHelper.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/21.
//

import Foundation
import Security

class KeychainHelper {
  static let shared = KeychainHelper()

  private init() {}

  // MARK: - Save

  func save(_ data: Data, service: String, account: String) {
    let query =
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecValueData: data,
      ] as [String: Any]

    // 既存データ削除
    SecItemDelete(query as CFDictionary)

    // 新規保存
    SecItemAdd(query as CFDictionary, nil)
  }

  func save(_ string: String, service: String, account: String) {
    if let data = string.data(using: .utf8) {
      save(data, service: service, account: account)
    }
  }

  // MARK: - Read

  func read(service: String, account: String) -> Data? {
    let query =
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne,
      ] as [String: Any]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess {
      return dataTypeRef as? Data
    }
    return nil
  }

  func readString(service: String, account: String) -> String? {
    if let data = read(service: service, account: account) {
      return String(data: data, encoding: .utf8)
    }
    return nil
  }

  // MARK: - Delete

  func delete(service: String, account: String) {
    let query =
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
      ] as [String: Any]

    SecItemDelete(query as CFDictionary)
  }
}
