//
//  FeedView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/20.
//

import SwiftUI

struct FeedView: View {
  @State private var items: [TimelineFeedItem] = []
  @State private var isLoading = false
  @State private var canLoadMore = true
  @State private var offset = 0
  @Binding var showSideMenu: Bool
  private let limit = 20

  var body: some View {
    ZStack {
      NavigationView {
        ScrollView {
          LazyVStack(spacing: 16) {
            if items.isEmpty && isLoading {
              ProgressView()
                .padding(.top, 50)
            } else if items.isEmpty {
              Text("No posts yet.")
                .foregroundStyle(.secondary)
                .padding(.top, 50)
            }

            ForEach($items) { $item in
              PostRowView(post: $item)
                .onAppear {
                  if item.id == items.last?.id && canLoadMore && !isLoading {
                    Task {
                      await loadMore()
                    }
                  }
                }
            }

            if isLoading && !items.isEmpty {
              ProgressView()
                .padding()
            }
          }
          .padding(16)
          // Bottom padding for tab bar
          .padding(.bottom, 80)
        }
        .background(
          Color.white.opacity(0.5)  // Base lightness
            .ignoresSafeArea()
        )
        .background(
          LinearGradient(
            stops: [
              .init(color: .blue.opacity(0.05), location: 0),
              .init(color: .purple.opacity(0.05), location: 0.3),
              .init(color: .white.opacity(0.5), location: 0.6),
              .init(color: .white, location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .ignoresSafeArea()
        )
        .refreshable {
          await refresh()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
              withAnimation {
                showSideMenu.toggle()
              }
            }) {
              Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundStyle(.primary)
            }
          }

          ToolbarItem(placement: .principal) {
            Text("Timeline")
              .font(.headline)
          }
        }
      }  // End NavigationView
    }
    .task {
      if items.isEmpty {
        await loadMore()
      }
    }
  }

  private func loadMore() async {
    guard !isLoading && canLoadMore else { return }
    isLoading = true

    do {
      let newItems = try await APIClient.shared.fetchTimeline(limit: limit, offset: offset)
      if newItems.count < limit {
        canLoadMore = false
      }

      await MainActor.run {
        // Deduplicate just in case
        let existingIDs = Set(items.map { $0.id })
        let uniqueNewItems = newItems.filter { !existingIDs.contains($0.id) }
        items.append(contentsOf: uniqueNewItems)
        offset += newItems.count
        isLoading = false
      }
    } catch {
      print("Failed to fetch timeline: \(error)")
      isLoading = false
    }
  }

  private func refresh() async {
    offset = 0
    canLoadMore = true
    isLoading = false  // Reset loading state

    // Temporarily clear items or keep them until new ones arrive?
    // Let's clear to simulate fresh load
    // items = []
    // Actually, better to overwrite.

    do {
      let newItems = try await APIClient.shared.fetchTimeline(limit: limit, offset: 0)
      await MainActor.run {
        items = newItems
        offset = newItems.count
        if newItems.count < limit {
          canLoadMore = false
        }
      }
    } catch {
      print("Failed to refresh: \(error)")
    }
  }
}

#Preview {
  FeedView(showSideMenu: .constant(false))
}
