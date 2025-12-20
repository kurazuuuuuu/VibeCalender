//
//  DebugProfileView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import SwiftUI

struct DebugProfileView: View {
  @State private var profile: UserProfile = .empty
  let analyzer = UserProfileAnalyzer.shared

  var body: some View {
    NavigationView {
      List {
        Section(header: Text("Profile Summary")) {
          LabeledContent("Vibe", value: profile.vibeDescription)
        }

        Section(header: Text("Routines (Excluded)")) {
          if profile.routines.isEmpty {
            Text("No routines")
              .foregroundColor(.secondary)
          } else {
            ForEach(profile.routines, id: \.self) { routine in
              Text(routine)
            }
          }
        }

        Section(header: Text("Raw Keyword Data (JSON)")) {
          if let jsonData = try? JSONEncoder().encode(profile.keywords),
            let jsonString = String(data: jsonData, encoding: .utf8)
          {
            Text(jsonString)
              .font(.caption)
              .foregroundColor(.secondary)
              .textSelection(.enabled)
          } else {
            Text("No keyword data")
          }
        }

        Section(header: Text("Structured Keywords")) {
          ForEach(profile.keywords, id: \.self) { keyword in
            VStack(alignment: .leading) {
              Text(keyword.name)
                .font(.headline)
              Text("Category: \(keyword.category)")
                .font(.caption)
              if !keyword.locations.isEmpty {
                Text("Locations: \(keyword.locations.joined(separator: ", "))")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
      }
      .navigationTitle("Debug Profile")
      .onAppear {
        loadProfile()
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Menu {
            Button("Reload") {
              loadProfile()
            }
            Button("Generate Mock Memos (10)") {
              MemoManager.shared.generateMockMemos()
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    }
  }

  private func loadProfile() {
    profile = analyzer.loadProfile()
  }
}

#Preview {
  DebugProfileView()
}
