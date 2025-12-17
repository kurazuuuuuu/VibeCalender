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
    VStack(spacing: 10) {
      Image(systemName: "calendar")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("身勝手カレンダー")

      Text(eventManager.statusMessage)
    }
    .padding(24)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(20)
    .shadow(radius: 1)

  }
}

#Preview {
  ContentView()
}
