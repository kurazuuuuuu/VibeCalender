//
//  PostRowView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/20.
//

import DAWNText
import SwiftUI

struct PostRowView: View {
  @Binding var post: TimelineFeedItem

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // Avatar
      Circle()
        .fill(.ultraThinMaterial)
        .frame(width: 40, height: 40)
        .overlay(
          Text(post.authorName.prefix(1))
            .font(.headline)
            .foregroundStyle(.primary)
        )
        .overlay(
          Circle()
            .stroke(.white.opacity(0.3), lineWidth: 1)
        )

      VStack(alignment: .leading, spacing: 6) {
        // Header (Name + ID) - Timestamp removed
        HStack(spacing: 4) {
          Text(post.authorName)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          Text(post.authorID)
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()
        }

        // Content
        Text(post.content)
          .font(.body)
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)

        // Footer (Reaction)
        HStack {
          Menu {
            ForEach(ReactionType.allCases, id: \.self) { reaction in
              Button(action: {
                Task {
                  if post.selectedReaction == reaction {
                    // Toggle off
                    post.selectedReaction = nil
                    post.likes -= 1
                    try? await APIClient.shared.removeReaction(postID: post.id)
                  } else {
                    // New or Change
                    let wasNil = post.selectedReaction == nil
                    post.selectedReaction = reaction
                    if wasNil {
                      post.likes += 1
                    }
                    try? await APIClient.shared.toggleReaction(postID: post.id, type: reaction)
                  }
                }
              }) {
                HStack {
                  Text(reaction.rawValue)
                  if post.selectedReaction == reaction {
                    Image(systemName: "checkmark")
                  }
                }
              }
            }
          } label: {
            HStack(spacing: 4) {
              if let reaction = post.selectedReaction {
                Text(reaction.rawValue)
                  .font(.body)
              } else {
                Image(systemName: "hand.thumbsup")
                  .font(.caption)
              }

              if post.likes > 0 {
                Text("\(post.likes)")
                  .font(.caption)
              }
            }
            .foregroundStyle(post.selectedReaction != nil ? .primary : .secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
              Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                  Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
            )
          }

          Spacer()
        }
        .padding(.top, 4)
      }
    }
    .padding(16)
    // Apply Liquid Glass Effect with "Refreshing" Tint
    .vibeGlassEffect(
      .vibeGlassEffectStyle(tint: post.category.color.opacity(0.1)),
      in: RoundedRectangle(cornerRadius: 24, style: .continuous)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    .padding(.horizontal, 4)  // Add side padding to float inside the screen
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
  PostRowView(post: .constant(TimelineFeedItem.mockItems()[0]))
    .padding()
}
