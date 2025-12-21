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

  private var hostBaseURL: String {
    baseURL.replacingOccurrences(of: "/v1", with: "")
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
        request.httpBody = try createEncoder().encode(body)
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
      // Void対応
      if T.self == EmptyResponse.self {
        return try JSONDecoder().decode(T.self, from: "{}".data(using: .utf8)!)
      }

      return try createDecoder().decode(T.self, from: data)
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

    let emailEncoded =
      request.email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? request.email
    let passwordEncoded =
      request.password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      ?? request.password

    let bodyString = "username=\(emailEncoded)&password=\(passwordEncoded)"
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

    let user = try createDecoder().decode(User.self, from: userData)

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
      let iconUrl: String? = {
        guard let relativePath = res.post.icon_url else { return nil }
        if relativePath.hasPrefix("http") { return relativePath }
        return "\(hostBaseURL)\(relativePath)"
      }()

      return TimelineFeedItem(
        id: res.post.id,
        authorName: res.user.username,
        authorID: "@" + String(res.user.id.prefix(8)),
        content: res.post.content,
        timestamp: parseDate(res.post.created_at) ?? Date(),
        likes: res.likes,
        replies: 0,
        category: res.post.category ?? "日常",
        selectedReaction: res.my_reaction.flatMap { ReactionType(rawValue: $0) },
        iconUrl: iconUrl,
        eventDate: res.post.event_date,
        colorHex: res.post.color_hex
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

  func uploadIcon(postID: String, image: Data) async throws -> String {
    guard let url = URL(string: "\(baseURL)/timeline/posts/\(postID)/icon") else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue(
      "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append(
      "Content-Disposition: form-data; name=\"file\"; filename=\"icon.jpg\"\r\n".data(using: .utf8)!
    )
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(image)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw APIError.invalidResponse
    }

    struct UploadResponse: Decodable {
      let icon_url: String
    }

    let result = try JSONDecoder().decode(UploadResponse.self, from: data)
    return result.icon_url
  }

  // Helpers
  private func createEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    encoder.dateEncodingStrategy = .formatted(formatter)
    return encoder
  }

  private func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)
      if let date = self.parseDate(dateString) {
        return date
      }
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Expected date string to be ISO8601-formatted. Got: \(dateString)")
    }
    return decoder
  }

  private func parseDate(_ dateString: String) -> Date? {
    // 1. Try ISO8601 (with fractional seconds)
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: dateString) { return date }

    // 2. Try ISO8601 (without fractional seconds)
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: dateString) { return date }

    // 3. Fallback for naive or microsecond formats
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    let formats = [
      "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",
      "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
      "yyyy-MM-dd'T'HH:mm:ss",
    ]

    for format in formats {
      formatter.dateFormat = format
      if let date = formatter.date(from: dateString) { return date }
    }

    return nil
  }
}

// Helper Structures for Timeline Response
struct TimelineFeedResponse: Decodable {
  struct Post: Decodable {
    let id: String
    let content: String
    let created_at: String
    let icon_url: String?
    let event_date: String?
    let color_hex: String?
    let category: String?
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
