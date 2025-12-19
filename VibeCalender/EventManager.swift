//
//  EventManager.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import Combine
import EventKit
import Foundation

@MainActor
class EventManager: ObservableObject {
    var store = EKEventStore()
    
    // イベントへの認証ステータスのメッセージ
    @Published var statusMessage = ""
    
    // 認証済みフラグ
    @Published var isAuthorized = false
    
    init() {
        Task {
            await requestAccess()
        }
    }
    
    private func requestAccess() async {
        do {
            // カレンダーへのアクセスを要求
            try await store.requestFullAccessToEvents()
            updateStatus()
        } catch {
            print(error.localizedDescription)
            updateStatus()
        }
    }
    
    private func updateStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            statusMessage = "カレンダーへのアクセスする\n権限が選択されていません。"
            isAuthorized = false
        case .restricted:
            statusMessage = "カレンダーへのアクセスする\n権限がありません。"
            isAuthorized = false
        case .denied:
            statusMessage = "カレンダーへのアクセスが\n明示的に拒否されています。"
            isAuthorized = false
        case .fullAccess:
            statusMessage = "カレンダーへのフルアクセスが\n許可されています。"
            isAuthorized = true
        case .writeOnly:
            statusMessage = "カレンダーへの書き込みのみが\n許可されています。"
            isAuthorized = true
        @unknown default:
            statusMessage = "@unknown default"
            isAuthorized = false
        }
    }
}
