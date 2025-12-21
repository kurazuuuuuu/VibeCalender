//
//  APIClient.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import Foundation

enum APIError: Error {
  case invalidURL
  case invalidResponse
  case httpError(statusCode: Int)
  case decodingError
  case encodingError
  case serverError(message: String)
}

extension APIError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "無効なURLです。"
    case .invalidResponse:
      return "サーバーからの応答が無効です。"
    case .httpError(let statusCode):
      return "HTTPエラーが発生しました。ステータスコード: \(statusCode)"
    case .decodingError:
      return "データの解析に失敗しました。"
    case .encodingError:
      return "データのエンコードに失敗しました。"
    case .serverError(let message):
      return "サーバーエラー: \(message)"
    }
  }
}

class APIClient {
  static let shared = APIClient()

  private init() {}

  private var baseURL: String {
    AppConfig.shared.apiBaseURL
  }

  private var authToken: String? {
    AuthManager.shared.getAuthToken()
  }

  // MARK: - Generic Request Handler

  private func request<T: Decodable>(
    endpoint: String,
    method: String = "GET",
    body: Encodable? = nil
  ) async throws -> T {
    // 認証トークンがない場合、認証が必要なエンドポイントへのリクエストをブロックする
    let isAuthEndpoint =
      endpoint.contains("/auth/") || endpoint.contains("/login") || endpoint.contains("/register")
    if !isAuthEndpoint && authToken == nil {
      print("🛑 Request blocked: No auth token for \(endpoint)")
      throw APIError.httpError(statusCode: 401)
    }

    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    if let body = body {
      do {
        request.httpBody = try JSONEncoder().encode(body)
      } catch {
        throw APIError.encodingError
      }
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      // 401 Unauthorizedの場合、かつ既にログアウト済み（authTokenなし）なら
      // ログを出力せずに静かにエラーを投げる（画面遷移後の残骸リクエスト対策）
      if httpResponse.statusCode == 401 {
        if authToken == nil {
          throw APIError.httpError(statusCode: 401)
        } else {
          // トークンがあるのに401が返ってきた -> セッション切れ
          // ログアウト処理を走らせる
          print("👮‍♀️ 401 detected with token. Logging out...")
          AuthManager.shared.logout()
          throw APIError.httpError(statusCode: 401)
        }
      }

      // デバッグ用: エラーレスポンスの内容を出力
      if let errorText = String(data: data, encoding: .utf8) {
        print("API Error: \(errorText)")
      }
      throw APIError.httpError(statusCode: httpResponse.statusCode)
    }

    do {
      // Void対応 (204 No Contentなど)
      if T.self == EmptyResponse.self {
        // 無理やり空のJSONとしてパースさせるか、呼び出し側でGenericsを工夫する必要があるが、
        // ここでは簡易的に空オブジェクトを返す
        // Hack: EmptyResponse struct must be Decodable
        return try JSONDecoder().decode(T.self, from: "{}".data(using: .utf8)!)
      }

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        // 1. Try ISO8601 with Fractional Seconds (standard)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) { return date }

        // 2. Try ISO8601 without Fractional Seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) { return date }

        // 3. Fallback for Python/FastAPI microseconds (e.g., 6 digits)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        // With timezone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        if let date = formatter.date(from: dateString) { return date }

        // Without timezone (naive)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = formatter.date(from: dateString) { return date }

        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Expected date string to be ISO8601-formatted. Got: \(dateString)")
      }

      return try decoder.decode(T.self, from: data)
    } catch {
      print("Decoding error: \(error)")
      throw APIError.decodingError
    }
  }
}

// MARK: - API Methods

extension APIClient {

  // Auth
  func login(request: LoginRequest) async throws -> AuthResponse {
    // fastapi-users /auth/jwt/login expects OAuth2PasswordRequestForm (x-www-form-urlencoded)
    // username field is mapped to email

    guard let url = URL(string: "\(baseURL)/auth/jwt/login") else {
      throw APIError.invalidURL
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let bodyString = "username=\(request.email)&password=\(request.password)"
    urlRequest.httpBody = bodyString.data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      if let errorText = String(data: data, encoding: .utf8) {
        print("Login Error: \(errorText)")
      }
      throw APIError.httpError(statusCode: httpResponse.statusCode)
    }

    // Response is typically {"access_token": "...", "token_type": "bearer"}
    // Our AuthResponse expects { token, user } but the default endpoint only returns token info.
    // So we need to fetch user info separately after login.

    // TokenResponse expects access_token
    struct TokenResponse: Decodable {
      let access_token: String
      let token_type: String
    }

    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

    // Fetch user info using the new token
    // We cannot use self.request here because the token is not yet in Keychain/AuthManager
    // So we manually constructs the request for user info
    let userEndpoint = "/users/me"
    guard let userUrl = URL(string: "\(baseURL)\(userEndpoint)") else {
      throw APIError.invalidURL
    }
    var userRequest = URLRequest(url: userUrl)
    userRequest.httpMethod = "GET"
    userRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    userRequest.setValue(
      "Bearer \(tokenResponse.access_token)", forHTTPHeaderField: "Authorization")

    let (userData, userResponse) = try await URLSession.shared.data(for: userRequest)

    guard let httpUserResponse = userResponse as? HTTPURLResponse,
      (200...299).contains(httpUserResponse.statusCode)
    else {
      throw APIError.invalidResponse
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      // 1. Try ISO8601 with Fractional Seconds (standard)
      let isoFormatter = ISO8601DateFormatter()
      isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = isoFormatter.date(from: dateString) { return date }

      // 2. Try ISO8601 without Fractional Seconds
      isoFormatter.formatOptions = [.withInternetDateTime]
      if let date = isoFormatter.date(from: dateString) { return date }

      // 3. Fallback for Manual
      let formatter = DateFormatter()
      formatter.calendar = Calendar(identifier: .iso8601)
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)

      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
      if let date = formatter.date(from: dateString) { return date }

      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
      if let date = formatter.date(from: dateString) { return date }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Expected date string to be ISO8601-formatted. Got: \(dateString)")
    }

    let user = try decoder.decode(User.self, from: userData)

    // AuthManagerに保存と状態更新を依頼
    AuthManager.shared.setAuthenticated(token: tokenResponse.access_token, userId: user.id)

    return AuthResponse(token: tokenResponse.access_token, user: user)
  }

  func register(request: RegisterRequest) async throws -> AuthResponse {
    let user: User = try await self.request(
      endpoint: "/auth/register", method: "POST", body: request)

    // Registration successful. Now try to login to get the token.
    let loginReq = LoginRequest(email: request.email, password: request.password)
    return try await login(request: loginReq)
  }

  func validateSession() async -> Bool {
    guard authToken != nil else { return false }
    do {
      let _: User = try await request(endpoint: "/users/me")
      return true
    } catch {
      print("Session validation failed: \(error)")
      return false
    }
  }

  func logout() {
    AuthManager.shared.logout()
  }

  // Events
  func fetchEvents() async throws -> [ScheduleEvent] {
    return try await request(endpoint: "/events/")
  }

  func createEvent(event: ScheduleEvent) async throws -> ScheduleEvent {
    return try await request(endpoint: "/events/", method: "POST", body: event)
  }

  func updateEvent(event: ScheduleEvent) async throws -> ScheduleEvent {
    return try await request(endpoint: "/events/\(event.id)", method: "PUT", body: event)
  }

  func deleteEvent(id: String) async throws {
    let _: EmptyResponse = try await request(endpoint: "/events/\(id)", method: "DELETE")
  }

  // Profile
  func fetchProfile() async throws -> UserProfile {
    return try await request(endpoint: "/profile/")
  }

  func updateProfile(profile: UserProfile) async throws -> UserProfile {
    return try await request(endpoint: "/profile/", method: "PUT", body: profile)
  }

  // Timeline
  // Timeline
  func fetchTimeline(limit: Int = 20, offset: Int = 0) async throws -> [TimelineFeedItem] {
    // API returns [TimelineFeedResponse]
    let responses: [TimelineFeedResponse] = try await request(
      endpoint: "/timeline/posts?limit=\(limit)&offset=\(offset)"
    )

    // Map to TimelineFeedItem
    return responses.map { res in
      TimelineFeedItem(
        id: res.post.id,
        authorName: res.user.username,
        authorID: "@" + String(res.user.id.prefix(8)),  // Shorten ID for display
        content: res.post.content,
        timestamp: parseDate(res.post.created_at) ?? Date(),
        likes: res.likes,
        replies: 0,  // Not implemented yet
        category: .daily,  // Default for now
        selectedReaction: res.my_reaction.flatMap { ReactionType(rawValue: $0) }
      )
    }
  }

  func toggleReaction(postID: String, type: ReactionType) async throws {
    // POST /timeline/posts/{id}/reactions?reaction_type=...
    let _: EmptyResponse = try await request(
      endpoint: "/timeline/posts/\(postID)/reactions?reaction_type=\(type.rawValue)",
      method: "POST"
    )
  }

  func removeReaction(postID: String) async throws {
    let _: EmptyResponse = try await request(
      endpoint: "/timeline/posts/\(postID)/reactions",
      method: "DELETE"
    )
  }

  func createPost(post: TimelinePost) async throws -> TimelinePost {
    return try await request(endpoint: "/timeline/posts", method: "POST", body: post)
  }

  func deletePost(id: String) async throws {
    let _: EmptyResponse = try await request(endpoint: "/timeline/posts/\(id)", method: "DELETE")
  }

  // Helpers
  private func parseDate(_ dateString: String) -> Date? {
    // 1. Try ISO8601 with Fractional Seconds
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: dateString) { return date }

    // 2. Try ISO8601 without Fractional Seconds
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: dateString) { return date }

    // 3. Fallback for manual formats
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
    if let date = formatter.date(from: dateString) { return date }

    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    return formatter.date(from: dateString)
  }

  // parseDateFallback is no longer needed as parseDate is robust
  private func parseDateFallback(_ dateString: String) -> Date? {
    return parseDate(dateString)
  }
}

// Helper Structures for Timeline Response
struct TimelineFeedResponse: Decodable {
  struct Post: Decodable {
    let id: String
    let content: String
    let created_at: String
  }
  struct User: Decodable {
    let id: String
    let username: String
  }

  let post: Post
  let user: User
  let likes: Int
  let my_reaction: String?
}

// 204 No Contentなどのためのダミー構造体
struct EmptyResponse: Decodable {}
