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

        Image(systemName: "calendar")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
          .foregroundColor(.blue)

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
        }
        .foregroundColor(.blue)
        .glassEffect(SwiftUI.Glass.regular, in: Capsule())
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        .interactive()

        NavigationLink(destination: SignUpView()) {
          Text("サインアップ")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .foregroundColor(.primary)
        .glassEffect(SwiftUI.Glass.clear, in: Capsule())
        .interactive()

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
