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
      RootView()
        .environmentObject(eventManager)
        .environmentObject(appConfig)
        .environmentObject(AuthManager.shared)
        .iconPlaygroundSheet()
    }
  }
}
