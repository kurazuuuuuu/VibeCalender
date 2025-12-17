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

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(eventManager)
    }
  }
}
