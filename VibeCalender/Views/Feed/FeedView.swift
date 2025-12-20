//
//  FeedView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/20.
//

import SwiftUI

struct FeedView: View {
    @State var items: [TimelineFeedItem]
    
    // In a real app, this would likely come from a ViewModel or EnvironmentObject
    init(items: [TimelineFeedItem] = TimelineFeedItem.mockItems()) {
        _items = State(initialValue: items)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach($items) { $item in
                    PostRowView(post: $item)
                }
            }
            .padding(16)
            // Bottom padding for tab bar
            .padding(.bottom, 80)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .refreshable {
            // Future: Implement refresh logic
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        }
    }
}

#Preview {
    FeedView()
}
