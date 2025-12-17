//
//  EventManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Combine
import EventKit
import Foundation

class EventManager: ObservableObject {
  var store = EKEventStore()
  // イベントへの認証ステータスのメッセージ
  @Published var statusMessage = ""

  init() {
    Task {
      do {
        // カレンダーへのアクセスを要求
        try await store.requestAccess(to: .event)
      } catch {
        print(error.localizedDescription)
      }
      // イベントへの認証ステータス
      let status = EKEventStore.authorizationStatus(for: .event)

      switch status {
      case .notDetermined:
        statusMessage = "カレンダーへのアクセスする\n権限が選択されていません。"
      case .restricted:
        statusMessage = "カレンダーへのアクセスする\n権限がありません。"
      case .denied:
        statusMessage = "カレンダーへのアクセスが\n明示的に拒否されています。"
      case .authorized:
        statusMessage = "カレンダーへのアクセスが\n許可されています。"
      case .fullAccess:
        statusMessage =
          "カレンダーへのフルアクセスが\n許可されています。"
      case .writeOnly:
        statusMessage =
          "カレンダーへの書き込みのみが\n許可されています。"
      @unknown default:
        statusMessage = "@unknown default"
      }
    }
  }
}
