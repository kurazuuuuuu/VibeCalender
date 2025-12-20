//
//  PostRowView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/20.
//

import SwiftUI
import DAWNText

struct PostRowView: View {
    let post: TimelineFeedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Author and Time
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text(post.authorName.prefix(1)).font(.headline))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(post.authorName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(post.authorID)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(post.timestamp.formatted())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Content using standard Text temporarily to fix build error (DAWN not found)
            Text(post.content)
                .font(.body)
                .foregroundColor(.primary) 
            
            // Footer: Actions
            HStack(spacing: 20) {
                ActionButton(icon: "bubble.right", text: "\(post.replies)")
                ActionButton(icon: "arrow.2.squarepath", text: "")
                ActionButton(icon: "heart", text: "\(post.likes)")
                ActionButton(icon: "square.and.arrow.up", text: "")
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

struct ActionButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            if !text.isEmpty {
                Text(text)
                    .font(.caption)
            }
        }
        .foregroundColor(.secondary)
    }
}

// Preview requires manual DAWNText setup or mock, standard preview might fail if lib not built
#Preview {
    PostRowView(post: TimelineFeedItem.mockItems()[0])
        .padding()
}
