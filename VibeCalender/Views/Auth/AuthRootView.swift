//
//  AuthRootView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/21.
//

import SwiftUI

struct AuthRootView: View {
  var body: some View {
    NavigationStack {
      VStack(spacing: 30) {
        Spacer()

        HStack(spacing: 10) {
          Image(systemName: "calendar")
            .resizable()
            .scaledToFit()
            .frame(width: 75, height: 75)
            .foregroundColor(.blue)
        }
        .glassEffect(.clear)

        Text("身勝手カレンダー")
          .font(.system(size: 35, weight: .heavy, design: .rounded))
          .foregroundColor(.primary)

        Text("Vibe scheduling...")
          .font(.subheadline)
          .foregroundColor(.secondary)

        Spacer()

        NavigationLink(destination: LoginView()) {
          Text("ログイン")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
              LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .clipShape(Capsule())
            .glassEffect(.clear.interactive)
        }

        // NavigationLink(destination: SignUpView()) {
        //   Text("サインアップ")
        //     .font(.headline)
        //     .frame(maxWidth: .infinity)
        //     .padding()
        // }
        // .foregroundColor(.primary)
        // .glassEffect(LiquidGlassTheme.clear, in: Capsule())
        // .interactive()

        // ローカル環境切り替え用 (開発用ハック)
        //        Toggle(
        //          "Use Local API",
        //          isOn: Binding(
        //            get: { AppConfig.shared.shouldUseLocalAPI },
        //            set: { AppConfig.shared.shouldUseLocalAPI = $0 }
        //          )
        //        )
        //        .padding()
        //        .background(Color.gray.opacity(0.1))
        //        .cornerRadius(8)
      }
      .padding(30)
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
    }
  }
}

#Preview {
  AuthRootView()
}
