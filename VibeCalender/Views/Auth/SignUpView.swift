//
//  SignUpView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/21.
//

import SwiftUI

struct SignUpView: View {
  @Environment(\.dismiss) var dismiss
  @State private var username = ""
  @State private var email = ""
  @State private var password = ""
  @State private var errorMessage = ""
  @State private var isLoading = false

  var body: some View {
    VStack(spacing: 20) {
      Spacer()
      TextField("ユーザー名", text: $username)
        .textFieldStyle(PlainTextFieldStyle())
        .padding()
        .autocapitalization(.none)
        .glassEffect(.clear, cornerRadius: 16)

      TextField("メールアドレス", text: $email)
        .textFieldStyle(PlainTextFieldStyle())
        .padding()
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
        .glassEffect(.clear, cornerRadius: 16)

      SecureField("パスワード", text: $password)
        .textFieldStyle(PlainTextFieldStyle())
        .padding()
        .glassEffect(.clear, cornerRadius: 16)

      if !errorMessage.isEmpty {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
          .padding(.horizontal)
      }

      Button(action: performRegister) {
        if isLoading {
          ProgressView()
            .tint(.white)
        } else {
          Text("サインアップ")
            .bold()
            .frame(maxWidth: .infinity)
            .padding()
        }
      }
      .foregroundColor(Color.blue)
      .glassEffect(SwiftUI.Glass.regular, in: Capsule())
      .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
      .disabled(username.isEmpty || email.isEmpty || password.isEmpty || isLoading)
      .interactive()

      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)
        .glassEffect(SwiftUI.Glass.clear, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 30, x: 0, y: 15)
    )
    .padding()
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
    .navigationBarTitleDisplayMode(.inline)
  }

  private func performRegister() {
    isLoading = true
    errorMessage = ""

    Task {
      do {
        let request = RegisterRequest(username: username, email: email, password: password)
        let response = try await APIClient.shared.register(request: request)

        await MainActor.run {
          // EventManager用にユーザーIDを保存
          UserDefaults.standard.set(response.user.id, forKey: "currentUserId")
          isLoading = false
        }
      } catch {
        await MainActor.run {
          isLoading = false
          errorMessage = "Registration failed: \(error.localizedDescription)"
        }
      }
    }
  }
}

#Preview {
  SignUpView()
}
