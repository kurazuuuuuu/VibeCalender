//
//  AILoadingView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import SwiftUI

struct AILoadingView: View {
  @State private var isAnimating = false
  let message: String

  var body: some View {
    ZStack {
      // 背景ブラー
      Color.clear
        .background(.ultraThinMaterial)
        .ignoresSafeArea()

      VStack(spacing: 30) {
        // AI ブレイン・アニメーション（比喩的な表現）
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 120, height: 120)
            .blur(radius: 20)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .animation(
              .easeInOut(duration: 2).repeatForever(autoreverses: true),
              value: isAnimating
            )

          Circle()
            .fill(
              LinearGradient(
                colors: [.purple.opacity(0.2), .orange.opacity(0.3)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
              )
            )
            .frame(width: 80, height: 80)
            .blur(radius: 20)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
              .linear(duration: 8).repeatForever(autoreverses: false),
              value: isAnimating
            )

          Image(systemName: "sparkles")
            .font(.system(size: 40))
            .foregroundStyle(.white)
            .shadow(color: .purple.opacity(0.6), radius: 5, x: 0, y: 0)
            .opacity(isAnimating ? 1.0 : 0.5)
            .animation(
              .easeInOut(duration: 1).repeatForever(autoreverses: true),
              value: isAnimating
            )
        }

        // ステータスメッセージ
        Text(message)
          .font(.headline)
          .foregroundStyle(.secondary)
          .transition(.opacity)
      }
    }
    .onAppear {
      isAnimating = true
    }
  }
}

#Preview {
  AILoadingView(message: "Generating...")
}
