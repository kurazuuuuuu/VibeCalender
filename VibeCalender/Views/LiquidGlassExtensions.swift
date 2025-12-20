//
//  LiquidGlassExtensions.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/19.
//

import SwiftUI

// MARK: - Liquid Glass API Extensions

/// Liquid Glass デザインシステムを SwiftUI 標準のように扱うための拡張
extension ShapeStyle where Self == LiquidGlassStyle {
  /// Liquid Glass 効果を適用するスタイル
  static func vibeGlassEffectStyle(tint: Color = .clear) -> LiquidGlassStyle {
    LiquidGlassStyle(tint: tint)
  }

  /// Liquid Glass 効果を適用するスタイル（引数なし）
  static func vibeGlassEffectStyle() -> LiquidGlassStyle {
    LiquidGlassStyle(tint: .clear)
  }
}

/// Liquid Glass の内部実装用スタイル
struct LiquidGlassStyle: ShapeStyle {
  let tint: Color

  func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
    // AnyShapeStyle を戻り値として直接返す
    AnyShapeStyle(.ultraThinMaterial.opacity(0.95))
  }
}

extension View {
  /// 形状に対して Liquid Glass 効果を適用するバックグラウンド設定
  func vibeGlassEffect<S: Shape>(_ style: LiquidGlassStyle = .vibeGlassEffectStyle(), in shape: S)
    -> some View
  {
    self.background {
      ZStack {
        // 基本のマテリアル
        shape.fill(.ultraThinMaterial)

        // 色相の反映
        if style.tint != .clear {
          shape.fill(style.tint.opacity(0.12))
        }

        // 表面の反射光（ハイライト）
        shape.fill(
          LinearGradient(
            stops: [
              .init(color: .white.opacity(0.4), location: 0),
              .init(color: .white.opacity(0.05), location: 0.4),
              .init(color: .clear, location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

        // 外縁の光
        shape.stroke(
          LinearGradient(
            colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 0.5
        )
      }
    }
  }

  /// インタラクティブなフィードバックを有効化
  func interactive(_ enabled: Bool = true) -> some View {
    self.buttonStyle(LiquidGlassButtonStyle(enabled: enabled))
  }
}

/// Liquid Glass 専用のボタンスタイル
struct LiquidGlassButtonStyle: ButtonStyle {
  let enabled: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(enabled && configuration.isPressed ? 0.94 : 1.0)
      .opacity(enabled && configuration.isPressed ? 0.9 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
  }
}

// MARK: - Compatibility Aliases

extension View {
  /// Alias for vibeGlassEffect to match existing usage
  func glassEffect<S: Shape>(_ style: LiquidGlassStyle = .vibeGlassEffectStyle(), in shape: S)
    -> some View
  {
    self.vibeGlassEffect(style, in: shape)
  }

  /// Convenience overload defaulting to RoundedRectangle
  func glassEffect(_ style: LiquidGlassStyle = .vibeGlassEffectStyle(), cornerRadius: CGFloat = 12)
    -> some View
  {
    self.vibeGlassEffect(
      style, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

extension LiquidGlassStyle {
  static var regular: LiquidGlassStyle { .vibeGlassEffectStyle() }
  static var clear: LiquidGlassStyle { .vibeGlassEffectStyle(tint: .clear) }
}
