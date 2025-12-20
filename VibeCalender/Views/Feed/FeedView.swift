//
//  FeedView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/20.
//

import SwiftUI

struct FeedView: View {
    let items: [TimelineFeedItem]
    
    // In a real app, this would likely come from a ViewModel or EnvironmentObject
    init(items: [TimelineFeedItem] = TimelineFeedItem.mockItems()) {
        self.items = items
    }
    
    var body: some View {
        List(items) { item in
            PostRowView(post: item)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
        .refreshable {
            // Future: Implement refresh logic
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        }
    }
}

#Preview {
    FeedView()
}
