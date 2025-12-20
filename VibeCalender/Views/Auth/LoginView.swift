//
//  LoginView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/21.
//

import SwiftUI

struct LoginView: View {
  @Environment(\.dismiss) var dismiss
  @State private var email = ""
  @State private var password = ""
  @State private var errorMessage = ""
  @State private var isLoading = false

  var body: some View {
    VStack(spacing: 20) {
      Spacer()
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

      Button(action: performLogin) {
        if isLoading {
          ProgressView()
            .tint(.white)
        } else {
          Text("ログイン")
            .bold()
            .frame(maxWidth: .infinity)
            .padding()
        }
      }
      .foregroundColor(Color.blue)
      .glassEffect(SwiftUI.Glass.regular, in: Capsule())
      .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
      .disabled(email.isEmpty || password.isEmpty || isLoading)
      .interactive()

      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)
        .glassEffect(
          SwiftUI.Glass.clear, in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 30, x: 0, y: 15)
    )
    .padding()
    .background(
      // 同じグラデーションを適用して統一感を出す（NavigationStackの背景が透過されない場合用）
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
    .onAppear {
      errorMessage = ""
    }
  }

  private func performLogin() {
    isLoading = true
    errorMessage = ""

    Task {
      do {
        let request = LoginRequest(email: email, password: password)
        let response = try await APIClient.shared.login(request: request)

        await MainActor.run {
          // EventManager用にユーザーIDを保存
          UserDefaults.standard.set(response.user.id, forKey: "currentUserId")
          isLoading = false
        }
      } catch {
        await MainActor.run {
          isLoading = false
          if let apiError = error as? APIError {
            switch apiError {
            case .httpError(let statusCode):
              errorMessage = "Login failed: \(statusCode). Check your credentials."
            default:
              errorMessage = "An error occurred: \(error.localizedDescription)"
            }
          } else {
            errorMessage = "Unknown error: \(error.localizedDescription)"
          }
        }
      }
    }
  }
}

#Preview {
  LoginView()
}
