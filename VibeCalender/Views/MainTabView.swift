//
//  MainTabView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import SwiftUI

/// メインタブビュー（Liquid Glass - 浮遊タブバー）
struct MainTabView: View {
  @State private var selectedTab = 0
  @State private var showAddSheet = false

  var body: some View {
    Group {
      switch selectedTab {
      case 0:
        WeeklyCalendarView()
      case 1:
        TimelineView()
      case 2:
        MemoListView()
      default:
        WeeklyCalendarView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .bottom) {
      // 下部のブラーグラデーション
      gradientBackground
    }
    .overlay(alignment: .bottom) {
      // Apple 標準スタイルの浮遊タブバー
      floatingTabBar
        .padding(.bottom, 20)
    }
    .preferredColorScheme(.light)
    .sheet(isPresented: $showAddSheet) {
      AIDateInputView()
        .preferredColorScheme(.light)
    }
  }

  private var gradientBackground: some View {
    Color.clear
      .background(.ultraThinMaterial)
      .compositingGroup()  // レンダリングを平滑化し、境界線のアーティファクトを防ぐ
      .mask(
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0), location: 0),
            .init(color: .black.opacity(0), location: 0.45),  // 画面中央付近まで完全に透明
            .init(color: .black.opacity(0.01), location: 0.5),  // 極めて薄いグラデーションから開始
            .init(color: .black.opacity(0.05), location: 0.55),
            .init(color: .black.opacity(0.15), location: 0.65),
            .init(color: .black.opacity(0.4), location: 0.8),
            .init(color: .black.opacity(0.8), location: 0.95),
            .init(color: .black, location: 1.0),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)
  }

  // MARK: - Apple 標準 Liquid Glass タブバー

  private var floatingTabBar: some View {
    HStack(spacing: 8) {
      GlassTabButton(
        icon: "calendar",
        title: "カレンダー",
        isSelected: selectedTab == 0
      ) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          selectedTab = 0
        }
      }

      GlassTabButton(
        icon: "clock",
        title: "タイムライン",
        isSelected: selectedTab == 1
      ) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          selectedTab = 1
        }
      }

      GlassTabButton(
        icon: "note.text",
        title: "メモ",
        isSelected: selectedTab == 2
      ) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          selectedTab = 2
        }
      }

      Divider()
        .frame(height: 30)
        .padding(.horizontal, 4)

      floatingAddButton
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: Capsule())
    .overlay(
      Capsule()
        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    .padding(.horizontal, 20)
    .padding(.bottom, 20)
  }

  // MARK: - 浮遊追加ボタン

  private var floatingAddButton: some View {
    Button(action: { showAddSheet = true }) {
      Image(systemName: "plus")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundStyle(Color.blue)
        .frame(width: 44, height: 44)
        .background(
          Circle()
            .fill(.ultraThinMaterial)
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
        )
    }
    .interactive(true)
  }
}

// MARK: - Liquid Glass タブボタン

struct GlassTabButton: View {
  let icon: String
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .symbolVariant(isSelected ? .fill : .none)

        Text(title)
          .font(.system(size: 10, weight: isSelected ? .bold : .medium))
      }
      .foregroundStyle(isSelected ? Color.blue : Color.primary.opacity(0.6))
      .padding(.horizontal, 20)
      .padding(.vertical, 8)
      .background {
        if isSelected {
          Capsule()
            .fill(Color.blue.opacity(0.12))
        } else {
          Capsule()
            .fill(Color.black.opacity(0.001))  // 透明だがヒットテスト可能な背景
        }
      }
      .contentShape(Capsule())  // 全域をタップ可能にする
    }
    .buttonStyle(LiquidGlassButtonStyle(enabled: true))  // 常にインタラクションを有効にする
  }
}

// MARK: - プレースホルダービュー

struct TimelineView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Spacer(minLength: 100)
        ZStack {
          Circle()
            .glassEffect(.regular, in: Circle())
            .frame(width: 100, height: 100)

          Image(systemName: "clock.arrow.circlepath")
            .font(.system(size: 40))
            .foregroundStyle(Color.gray)
        }
        Text("タイムライン")
          .font(.title2)
          .fontWeight(.bold)
        Text("Coming soon...")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity)
    }
    .background(Color(.systemBackground))
  }
}

#Preview {
  MainTabView()
    .environmentObject(EventManager())
}
