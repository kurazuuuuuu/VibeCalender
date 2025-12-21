//
//  SideMenuView.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/21.
//

import SwiftUI

struct SideMenuView: View {
  @Binding var isShowing: Bool
  @State private var showLogoutAlert = false

  var body: some View {
    ZStack {
      if isShowing {
        // Dimmed background
        Color.black
          .opacity(0.3)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation {
              isShowing = false
            }
          }
          .zIndex(0)

        // Menu Content
        HStack {
          VStack(alignment: .leading, spacing: 32) {
            // Header
            HStack {
              Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(Color.blue)
              Text("身勝手カレンダー")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            }
            .padding(.top, 60)

            Divider()
              .background(Color.white.opacity(0.5))

            // Menu Items
            // VStack(alignment: .leading, spacing: 24) {
            //   MenuRow(icon: "person.circle", text: "プロフィール") {
            //     // Future implementation
            //   }

            //   MenuRow(icon: "gearshape", text: "設定") {
            //     // Future implementation
            //   }
            // }

            Spacer()

            // Logout Button
            Button(action: {
              showLogoutAlert = true
            }) {
              HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("ログアウト")
              }
              .font(.headline)
              .foregroundColor(.red)
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                RoundedRectangle(cornerRadius: 25)
                  .fill(Color.red.opacity(0.1))
              )
            }
            .glassEffect(.clear.interactive())
            .padding(.bottom, 40)
          }
          .padding(.horizontal, 24)
          .frame(maxWidth: 280)
          .background(
            ZStack {
              // Liquid Glass Effect
              Rectangle()
                .fill(.ultraThinMaterial)

              // Subtle Gradient Overlay
              LinearGradient(
                colors: [
                  .white.opacity(0.5),
                  .blue.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            }
            .ignoresSafeArea()
          )
          .shadow(color: .black.opacity(0.1), radius: 10, x: 5, y: 0)

          Spacer()
        }
        .transition(.move(edge: .leading))
        .zIndex(1)
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
    .alert("ログアウト", isPresented: $showLogoutAlert) {
      Button("キャンセル", role: .cancel) {}
      Button("ログアウト", role: .destructive) {
        performLogout()
      }
    } message: {
      Text("本当にログアウトしますか？")
    }
  }

  private func performLogout() {
    withAnimation {
      isShowing = false
    }
    // 少し遅延させてからログアウト処理（アニメーション待ち）
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      APIClient.shared.logout()
    }
  }
}

// Helper View for Menu Items
struct MenuRow: View {
  let icon: String
  let text: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundStyle(.secondary)
          .frame(width: 24)

        Text(text)
          .font(.body)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
      }
    }
  }
}

#Preview {
  ZStack {
    Color.green.ignoresSafeArea()  // Background to test translucency
    SideMenuView(isShowing: .constant(true))
  }
}
