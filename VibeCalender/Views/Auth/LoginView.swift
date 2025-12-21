//
//  LoginView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/21.
//

import SwiftUI

struct LoginView: View {
  @Namespace private var namespace
  @Environment(\.dismiss) var dismiss
  @State private var isRegisterMode = false
  @State private var username = ""
  @State private var email = ""
  @State private var password = ""
  @State private var errorMessage = ""
  @State private var isLoading = false

  init(isRegisterMode: Bool = false) {
    _isRegisterMode = State(initialValue: isRegisterMode)
  }

  var body: some View {
    VStack(spacing: 20) {
      Spacer()
      HStack(spacing: 10) {
        Image(systemName: isRegisterMode ? "person.badge.plus" : "lock.iphone")
          .resizable()
          .scaledToFit()
          .frame(width: 45, height: 45)
          .foregroundColor(.blue)
          .contentTransition(.symbolEffect(.replace))
      }
      .padding(.bottom, 10)

      if isRegisterMode {
        TextField("ユーザー名", text: $username)
          .textFieldStyle(PlainTextFieldStyle())
          .padding()
          .autocapitalization(.none)
          .background(Color.primary.opacity(0.05))
          .cornerRadius(16)
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
          )
          .transition(.move(edge: .top).combined(with: .opacity))
      }

      TextField("メールアドレス", text: $email)
        .textFieldStyle(PlainTextFieldStyle())
        .padding()
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(16)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )

      SecureField("パスワード", text: $password)
        .textFieldStyle(PlainTextFieldStyle())
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(16)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )

      if !errorMessage.isEmpty {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
          .padding(.horizontal)
      }

      GlassEffectContainer {
        HStack {
          // Login Button
          Button(action: {
            if isRegisterMode {
              withAnimation(.spring()) { isRegisterMode = false }
            } else {
              performLogin()
            }
          }) {
            if isLoading && !isRegisterMode {
              ProgressView().tint(.white)
            } else {
              Text("ログイン")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
          .background {
            if !isRegisterMode {
              Capsule()
                .fill(Color.blue.opacity(0.8))
                .matchedGeometryEffect(id: "activeBackground", in: namespace)
            }
          }
          .foregroundStyle(!isRegisterMode ? .white : .primary)
          .glassEffect()
          // .glassEffectUnion(id: 1, namespace: namespace) // Simplified for clarity

          // Sign Up Button
          Button(action: {
            if !isRegisterMode {
              withAnimation(.spring()) { isRegisterMode = true }
            } else {
              performRegister()
            }
          }) {
            if isLoading && isRegisterMode {
              ProgressView().tint(.white)
            } else {
              Text("サインアップ")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
          .background {
            if isRegisterMode {
              Capsule()
                .fill(Color.blue.opacity(0.8))
                .matchedGeometryEffect(id: "activeBackground", in: namespace)
            }
          }
          .foregroundStyle(isRegisterMode ? .white : .primary)
          .glassEffect()
          // .glassEffectUnion(id: 1, namespace: namespace) // Simplified
        }
      }
      .disabled(isLoading)

      Spacer()
    }
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

  private func performRegister() {
    isLoading = true
    errorMessage = ""

    Task {
      do {
        let request = RegisterRequest(username: username, email: email, password: password)
        let response = try await APIClient.shared.register(request: request)

        await MainActor.run {
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
  LoginView()
}
