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
      avatarView
      mainContentView
    }
    .padding(16)
    .glassEffect(
      .standard,
      in: RoundedRectangle(cornerRadius: 24, style: .continuous),
      fill: backgroundTint
    )
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    .padding(.horizontal, 4)
  }

  // MARK: - Subviews

  private var backgroundTint: Color {
    post.colorHex.flatMap { Color(hex: $0) }?.opacity(0.15) ?? .clear
  }

  private var avatarView: some View {
    Group {
      if let iconUrl = post.iconUrl,
        let url = URL(string: iconUrl)
      {
        AsyncImage(url: url) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          ProgressView()
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
      } else {
        Circle()
          .fill(.ultraThinMaterial)
          .frame(width: 40, height: 40)
          .overlay(
            Text(post.authorName.prefix(1))
              .font(.headline)
              .foregroundStyle(.primary)
          )
      }
    }
    .overlay(
      Circle()
        .stroke(.white.opacity(0.3), lineWidth: 1)
    )
  }

  private var mainContentView: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Header (Name + ID)
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

      // Event Metadata (Date & Category)
      HStack(spacing: 8) {
        if let eventDate = post.eventDate {
          HStack(spacing: 4) {
            Image(systemName: "calendar")
              .font(.caption2)
            Text(eventDate)
              .font(.caption2)
              .fontWeight(.medium)
          }
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(.ultraThinMaterial)
          .clipShape(Capsule())
        }

        // Category Badge
        //   Text(post.category)
        //     .font(.caption2)
        //     .fontWeight(.bold)
        //     .foregroundStyle(.primary.opacity(0.8))
        //     .padding(.horizontal, 8)
        //     .padding(.vertical, 2)
        //     .background(backgroundTint.opacity(0.3))
        //     .background(.ultraThinMaterial)
        //     .clipShape(Capsule())
      }

      // Content
      Text(post.content)
        .font(.body)
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)

      // Footer (Reactions)
      reactionButton
        .padding(.top, 4)
    }
  }

  private var reactionButton: some View {
    HStack {
      Menu {
        ForEach(ReactionType.allCases, id: \.self) { reaction in
          Button(action: {
            handleReaction(reaction)
          }) {
            HStack {
              Text(reaction.emoji)
              if post.selectedReaction == reaction {
                Image(systemName: "checkmark")
              }
            }
          }
        }
      } label: {
        HStack(spacing: 4) {
          if let reaction = post.selectedReaction {
            Text(reaction.emoji)
              .font(.body)
          } else {
            Image(systemName: "plus")
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
  }

  private func handleReaction(_ reaction: ReactionType) {
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
  }
}

// MARK: - Color Extension
extension Color {
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0

    var r: Double = 0.0
    var g: Double = 0.0
    var b: Double = 0.0
    var a: Double = 1.0

    let length = hexSanitized.count

    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

    if length == 6 {
      r = Double((rgb & 0xFF0000) >> 16) / 255.0
      g = Double((rgb & 0x00FF00) >> 8) / 255.0
      b = Double(rgb & 0x0000FF) / 255.0
    } else if length == 8 {
      r = Double((rgb & 0xFF00_0000) >> 24) / 255.0
      g = Double((rgb & 0x00FF_0000) >> 16) / 255.0
      b = Double((rgb & 0x0000_FF00) >> 8) / 255.0
      a = Double(rgb & 0x0000_00FF) / 255.0
    } else {
      return nil
    }

    self.init(red: r, green: g, blue: b, opacity: a)
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
