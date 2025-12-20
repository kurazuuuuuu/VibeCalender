//
//  OnboardingView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import Combine
import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject var appConfig: AppConfig

  // States suitable for 3-stage funnel
  @State private var currentStage: Int = 1
  @State private var isLoading: Bool = true

  // Data
  @State private var suggestedWords: [String] = []  // Current displayed bubbles
  @State private var selectedWords: Set<String> = []  // Currently selected in this stage

  // Accumulation
  @State private var selectedCategories: [String] = []  // Result of Stage 1
  @State private var selectedGenres: [String] = []  // Result of Stage 2
  @State private var finalKeywords: [String] = []  // Result of Stage 3 (Master Profile)

  enum ViewState {
    case loading
    case selection
    case confirmation
  }

  @State private var viewState: ViewState = .loading

  var body: some View {
    ZStack {
      // Background: Liquid Gradients (Colors change by stage)
      LinearGradient(
        colors: backgroundColors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      // Blobs
      GeometryReader { proxy in
        Circle()
          .fill(blobColor1)
          .frame(width: 300, height: 300)
          .blur(radius: 50)
          .offset(x: -100, y: -100)

        Circle()
          .fill(blobColor2)
          .frame(width: 250, height: 250)
          .blur(radius: 50)
          .offset(x: proxy.size.width - 150, y: proxy.size.height - 200)
      }
      .ignoresSafeArea()

      VStack(spacing: 30) {
        // Header
        Text(headerTitle)
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .multilineTextAlignment(.center)
          .padding(.top, 50)
          .transition(.opacity)
          .id("header-\(currentStage)-\(viewState)")  // Force transition

        Spacer()

        // Content Area
        ZStack {
          if viewState == .loading {
            VStack {
              ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
              Text("AIが分析中...")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 20)
            }
          } else if viewState == .selection {
            BubbleCloudView(
              words: suggestedWords,
              selectedWords: $selectedWords,
              onTap: toggleSelection
            )
            .transition(.scale.combined(with: .opacity))

            // 右上のシャッフルボタン削除
          } else if viewState == .confirmation {
            VStack(alignment: .leading, spacing: 10) {
              ForEach(finalKeywords, id: \.self) { word in
                HStack {
                  Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                  Text(word)
                    .font(.body)
                    .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
              }
            }
            .padding()
            .transition(.move(edge: .bottom))
          }
        }
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewState)

        Spacer()

        // Footer Action
        if viewState == .selection {
          // 再生成ボタン
          Button(action: {
            fetchSuggestions()
          }) {
            HStack(spacing: 4) {
              Image(systemName: "arrow.triangle.2.circlepath")
              Text("再生成")
            }
            .font(.caption)
            .foregroundStyle(.black.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
          }
          .padding(.bottom, 4)

          Text("\(selectedWords.count) / 1-3 選択中")
            .font(.caption)
            .foregroundStyle(.secondary)

          Button(action: proceedToNextStage) {
            Text(currentStage < 3 ? "次へ" : "決定")
              .font(.headline)
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                canProceed
                  ? LinearGradient(
                    colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                  : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
              )
              .clipShape(Capsule())
              .opacity(canProceed ? 1.0 : 0.5)
              .animation(.easeInOut, value: canProceed)
          }
          .disabled(!canProceed)
          .padding(.horizontal)
        } else if viewState == .confirmation {
          Button(action: finishOnboarding) {
            Text("これで始める")
              .font(.headline)
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.black)
              .clipShape(Capsule())
          }
          .padding(.horizontal)
        }
      }
      .padding()
    }
    .onAppear {
      startStage1()
    }
  }

  // MARK: - Logic & Props

  private var headerTitle: String {
    if viewState == .loading { return "Analyzing..." }
    if viewState == .confirmation { return "プロファイルが完成しました" }

    switch currentStage {
    case 1: return "興味のある\n「ジャンル」を選んでください"
    case 2: return "具体的に何が好きですか？"
    case 3: return "最後に、\n気になるキーワードを選んでください"
    default: return ""
    }
  }

  private var backgroundColors: [Color] {
    switch currentStage {
    case 1: return [.blue.opacity(0.1), .purple.opacity(0.1)]
    case 2: return [.orange.opacity(0.1), .pink.opacity(0.1)]
    case 3: return [.green.opacity(0.1), .mint.opacity(0.1)]
    default: return [.gray.opacity(0.1), .gray.opacity(0.1)]
    }
  }

  private var blobColor1: Color {
    switch currentStage {
    case 1: return .blue.opacity(0.2)
    case 2: return .orange.opacity(0.2)
    case 3: return .green.opacity(0.2)
    default: return .gray
    }
  }

  private var blobColor2: Color {
    switch currentStage {
    case 1: return .pink.opacity(0.2)
    case 2: return .red.opacity(0.2)
    case 3: return .teal.opacity(0.2)
    default: return .gray
    }
  }

  private var canProceed: Bool {
    !selectedWords.isEmpty  // 少なくとも1つ選べばOK
  }

  private func toggleSelection(_ word: String) {
    if selectedWords.contains(word) {
      selectedWords.remove(word)
    } else {
      // 選択上限: 3つまで
      if selectedWords.count < 3 {
        selectedWords.insert(word)
      }
    }
  }

  // MARK: - Flow Management

  // 現在のステージのデータを再取得する
  private func fetchSuggestions() {
    viewState = .loading
    Task {
      var words: [String] = []

      switch currentStage {
      case 1:
        words = await UserProfileAnalyzer.shared.generateStage1Categories()
      case 2:
        words = await UserProfileAnalyzer.shared.generateStage2Genres(
          selectedCategories: selectedCategories)
      case 3:
        words = await UserProfileAnalyzer.shared.generateStage3Keywords(
          selectedGenres: selectedGenres)
      default:
        break
      }

      await MainActor.run {
        self.suggestedWords = words
        self.selectedWords = []
        self.viewState = .selection
      }
    }
  }

  private func startStage1() {
    fetchSuggestions()
  }

  private func proceedToNextStage() {
    let selection = Array(selectedWords)

    if currentStage == 1 {
      selectedCategories = selection
      currentStage = 2
      fetchSuggestions()
    } else if currentStage == 2 {
      selectedGenres = selection
      currentStage = 3
      fetchSuggestions()
    } else if currentStage == 3 {
      finalKeywords = selection
      viewState = .confirmation
    }
  }

  private func finishOnboarding() {
    UserProfileAnalyzer.shared.saveMasterProfile(words: finalKeywords)
    withAnimation {
      appConfig.isOnboardingCompleted = true
    }
  }
}

// MARK: - Bubble UI Component

// MARK: - Safe Grid Layout Engine
class BubbleLayoutEngine: ObservableObject {
  struct Node: Identifiable {
    let id: Int
    var position: CGPoint
    let word: String
  }

  @Published var nodes: [Node] = []

  // グリッド配置アルゴリズム (2列 x 3行 = 6個)
  func initialize(words: [String], in containerSize: CGSize) {
    var newNodes: [Node] = []

    // セーフエリア定義: 利用可能領域を広げるためにマージンを調整
    let topMargin: CGFloat = 130
    let bottomMargin: CGFloat = 100  // フッターとの被りを防ぎつつ広げる
    let sideMargin: CGFloat = 15

    let availableWidth = containerSize.width - (sideMargin * 2)
    let availableHeight = containerSize.height - topMargin - bottomMargin

    // グリッド設定
    let columns = 2
    let rows = 3
    let cellWidth = availableWidth / CGFloat(columns)
    let cellHeight = availableHeight / CGFloat(rows)

    // ランダム性を出すためにシャッフル
    let shuffledWords = words.shuffled()

    for (index, word) in shuffledWords.enumerated() {
      if index >= columns * rows { break }  // 最大6個まで

      // グリッドインデックス
      let col = index % columns
      let row = index / columns

      // セルの中心計算（ジグザグ配置を廃止して単純なグリッドに）
      let centerX = sideMargin + (CGFloat(col) * cellWidth) + (cellWidth / 2)
      let centerY = topMargin + (CGFloat(row) * cellHeight) + (cellHeight / 2)

      // 中心から少しだけずらして「手作業感」を出す (物理演算なしの揺らぎ)
      // 重なりを防ぐため、ランダム幅を少し抑える
      let randomX = CGFloat.random(in: -5...5)
      let randomY = CGFloat.random(in: -5...5)

      let position = CGPoint(x: centerX + randomX, y: centerY + randomY)

      newNodes.append(Node(id: index, position: position, word: word))
    }

    self.nodes = newNodes
  }
}

struct BubbleCloudView: View {
  let words: [String]
  @Binding var selectedWords: Set<String>
  let onTap: (String) -> Void

  @StateObject private var engine = BubbleLayoutEngine()

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(engine.nodes) { node in
          FloatingBubble(
            text: node.word,
            isSelected: selectedWords.contains(node.word),
            basePosition: node.position
          )
          .onTapGesture {
            onTap(node.word)
          }
        }
      }
      .onAppear {
        engine.initialize(words: words, in: geometry.size)
      }
      .onChange(of: geometry.size) { newSize in
        engine.initialize(words: words, in: newSize)
      }
      .onChange(of: words) { newWords in
        engine.initialize(words: newWords, in: geometry.size)
      }
    }
  }
}

struct FloatingBubble: View {
  let text: String
  let isSelected: Bool
  let basePosition: CGPoint

  // ゆらゆらアニメーション用のオフセット
  @State private var floatOffset: CGSize = .zero
  @State private var appearScale: CGFloat = 0.0

  var body: some View {
    Text(text)
      .font(.system(size: 16, weight: .bold, design: .rounded))
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
      .foregroundStyle(isSelected ? .white : .primary)
      .background(
        ZStack {
          if isSelected {
            LinearGradient(
              colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
          } else {
            Rectangle().fill(.ultraThinMaterial)
          }
        }
      )
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .strokeBorder(
            isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.3), lineWidth: 1.5)
      )
      .shadow(color: isSelected ? .blue.opacity(0.4) : .black.opacity(0.1), radius: 10, x: 0, y: 5)
      .scaleEffect(isSelected ? 1.15 : 1.0)
      .scaleEffect(appearScale)
      .position(x: basePosition.x, y: basePosition.y)  // ベース位置は固定
      .offset(floatOffset)  // オフセットでゆらゆらさせる
      .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
      .onAppear {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
          appearScale = 1.0
        }
        startFloating()
      }
  }

  func startFloating() {
    // ゆらゆら: 範囲を少し広げて、ゆっくり動かすことで「液体的」な感じを出す
    let duration = Double.random(in: 3.0...6.0)
    let randomX = CGFloat.random(in: -15...15)
    let randomY = CGFloat.random(in: -15...15)

    withAnimation(
      .easeInOut(duration: duration)
        .repeatForever(autoreverses: true)
    ) {
      floatOffset = CGSize(width: randomX, height: randomY)
    }
  }
}

#Preview {
  OnboardingView()
    .environmentObject(AppConfig.shared)
}
