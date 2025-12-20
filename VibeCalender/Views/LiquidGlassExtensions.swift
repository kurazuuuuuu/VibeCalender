//
//  LiquidGlassExtensions.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/19.
//

import SwiftUI

// MARK: - Liquid Glass API Extensions

// MARK: - Core Definitions

enum LiquidGlassTheme {
  case standard  // Blue/Cyan/White (General)
  case ai  // Purple/Pink/Orange (AI Features)
  case clear  // Minimal (Transparent tint, just gloss)

  var tintColor: Color {
    switch self {
    case .standard: return .blue
    case .ai: return .purple
    case .clear: return .clear
    }
  }

  var gradientColors: [Color] {
    switch self {
    case .standard:
      return [.blue.opacity(0.08), .cyan.opacity(0.08)]
    case .ai:
      return [.purple.opacity(0.15), .pink.opacity(0.1)]
    case .clear:
      return [.clear]
    }
  }

  var rimColors: [Color] {
    switch self {
    case .standard:
      return [Color.white.opacity(0.6), Color.white.opacity(0.2)]
    case .ai:
      return [Color.white.opacity(0.7), Color.purple.opacity(0.4)]
    case .clear:
      return [Color.white.opacity(0.3), Color.white.opacity(0.05)]
    }
  }
}

extension ShapeStyle where Self == LiquidGlassStyle {
  /// Theme-based Liquid Glass Style
  static func vibeGlassEffectStyle(theme: LiquidGlassTheme = .standard) -> LiquidGlassStyle {
    LiquidGlassStyle(theme: theme)
  }
}

/// Liquid Glass Internal Style Definition
struct LiquidGlassStyle: ShapeStyle {
  let theme: LiquidGlassTheme

  func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
    // Return base material, opacity slightly adjusted for "Liquid" feel
    AnyShapeStyle(.ultraThinMaterial.opacity(0.95))
  }
}

extension View {
  /// Base Modifier for Liquid Glass Effect
  func vibeGlassEffect<S: Shape>(_ theme: LiquidGlassTheme = .standard, in shape: S) -> some View {
    self.background {
      ZStack {
        // 1. Base Material
        shape.fill(.ultraThinMaterial)

        // 2. Theme Tint (Subtle Color Layer)
        if theme != .clear {
          shape.fill(
            LinearGradient(
              colors: theme.gradientColors,
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
        }

        // 3. Surface Gloss (Reflection)
        shape.fill(
          LinearGradient(
            stops: [
              .init(color: .white.opacity(0.35), location: 0),
              .init(color: .white.opacity(0.05), location: 0.45),
              .init(color: .clear, location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

        // 4. Rim Light (Edge Highlight)
        shape.stroke(
          LinearGradient(
            colors: theme.rimColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 0.5
        )
      }
      // Soft Shadow based on theme
      .shadow(
        color: theme == .ai ? .purple.opacity(0.2) : .black.opacity(0.05),
        radius: 15, x: 0, y: 8
      )
    }
  }

  /// Enable Interactive Feedback
  func interactive(_ enabled: Bool = true) -> some View {
    self.buttonStyle(LiquidGlassButtonStyle(enabled: enabled))
  }
}

/// Liquid Glass Button Style (Motion)
struct LiquidGlassButtonStyle: ButtonStyle {
  let enabled: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(enabled && configuration.isPressed ? 0.96 : 1.0)
      .opacity(enabled && configuration.isPressed ? 0.9 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
  }
}

// MARK: - Compatibility Aliases & Helpers

extension View {
  /// Global Alias for standard use
  func glassEffect<S: Shape>(_ theme: LiquidGlassTheme = .standard, in shape: S) -> some View {
    self.vibeGlassEffect(theme, in: shape)
  }

  /// Convenience overload (defaults to Standard theme, RoundedRectangle)
  func glassEffect(_ theme: LiquidGlassTheme = .standard, cornerRadius: CGFloat = 12) -> some View {
    self.vibeGlassEffect(
      theme, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

// Extension to allow .regular / .clear syntax if strictly needed by existing code
// However, it is recommended to migrate to .standard / .ai / .clear cases.
extension LiquidGlassTheme {
  static var regular: LiquidGlassTheme { .standard }
}
