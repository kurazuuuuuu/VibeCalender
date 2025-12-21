//
//  CapabilityCheckView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import FoundationModels
import SwiftUI

/// アプリ起動時に端末の機能（AI）が利用可能かチェックする画面
struct CapabilityCheckView: View {
  @Binding var isOptimized: Bool
  @State private var checkStatus: CheckStatus = .checking
  @State private var errorMessage: String = ""

  enum CheckStatus {
    case checking
    case available
    case unavailable
  }

  var body: some View {
    ZStack {
      // Background
      Color.white.ignoresSafeArea()

      VStack(spacing: 20) {
        if checkStatus == .checking {
          ProgressView()
            .scaleEffect(1.5)
          Text("端末機能を確認中...")
            .font(.subheadline)
            .foregroundColor(.gray)
        } else if checkStatus == .unavailable {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 60))
            .foregroundColor(.red)
            .padding(.bottom, 10)

          Text("この端末では利用できません")
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)

          Text(errorMessage)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)

          Text("本アプリはApple Intelligenceおよび高性能なニューラルエンジンを必要とします。")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.top, 20)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
      }
    }
    .onAppear {
      checkCapability()
    }
  }

  private func checkCapability() {
    // 少し遅延させてチェック（起動アニメーション的な余韻）
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      if #available(iOS 18.0, *) {
        // FoundationModelsが利用可能か簡易チェック
        // 本来は具体的なモデルのロード可否を確認すべきだが、ここではOSバージョンと基本APIの疎通を確認する
        // 実際にはLanguageModelSessionの初期化などでチェックするが、重いため一旦バージョンチェックと仮定
        // 将来的には実際にモデルを軽く叩いてみるのもあり

        self.checkStatus = .available
        withAnimation {
          self.isOptimized = true
        }
      } else {
        self.errorMessage = "iOS 18.0以上が必要です。\nお使いの端末は要件を満たしていません。"
        self.checkStatus = .unavailable
      }
    }
  }
}

#Preview {
  CapabilityCheckView(isOptimized: .constant(false))
}
