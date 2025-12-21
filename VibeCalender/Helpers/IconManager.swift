//
//  IconManager.swift
//  VibeCalender
//
//  Created by AI Assistant on 2025/12/21.
//

import Combine
import Foundation
import ImagePlayground
import SwiftUI

/// Image Playground と連携してアイコンを管理するクラス
@MainActor
class IconManager: ObservableObject {
  static let shared = IconManager()

  @Published var isShowingPlayground = false
  @Published var currentPostID: String?
  @Published var currentCategory: String?

  private init() {}

  /// カテゴリ名に基づいて Image Playground を起動する準備を行う
  func prepareIconGeneration(for postID: String, category: String) {
    self.currentPostID = postID
    self.currentCategory = category
    self.isShowingPlayground = true
  }

  /// 生成された画像を処理してアップロードする
  func handleGeneratedImage(url: URL) async {
    guard let postID = currentPostID else { return }

    print("📁 Image generated at: \(url)")

    do {
      // 1. 画像の読み込みと縮小・圧縮
      let imageData = try Data(contentsOf: url)
      guard let image = UIImage(data: imageData) else { return }

      // アイコンサイズにリサイズ (e.g. 512x512)
      let resizedImage = resizeImage(image, targetSize: CGSize(width: 512, height: 512))

      // 圧縮 (JPEG, quality 0.5)
      guard let compressedData = resizedImage.jpegData(compressionQuality: 0.5) else {
        print("❌ Failed to compress image")
        return
      }

      // 2. アップロード
      let iconUrl = try await APIClient.shared.uploadIcon(postID: postID, image: compressedData)
      print("✅ Icon uploaded successfully: \(iconUrl)")

      // クリーンアップ
      self.currentPostID = nil
      self.currentCategory = nil

    } catch {
      print("❌ Error handling generated image: \(error)")
    }
  }

  private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
  }
}

// MARK: - SwiftUI View Extension
extension View {
  /// Image Playground Sheet を表示するためのモディファイア
  func iconPlaygroundSheet() -> some View {
    self.modifier(IconPlaygroundModifier())
  }
}

struct IconPlaygroundModifier: ViewModifier {
  @StateObject private var manager = IconManager.shared

  func body(content: Content) -> some View {
    content
      .imagePlaygroundSheet(
        isPresented: $manager.isShowingPlayground,
        concepts: manager.currentCategory.map { [.text($0)] } ?? []
      ) { url in
        Task {
          await manager.handleGeneratedImage(url: url)
        }
      }
  }
}
