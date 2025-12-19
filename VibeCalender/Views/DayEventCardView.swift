//
//  DayEventCardView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import EventKit
import SwiftUI

/// 予定カードビュー（カレンダー色別）
struct DayEventCardView: View {
  let event: EKEvent
  let isAIGenerated: Bool

  var body: some View {
    HStack {
      Text(event.title ?? "予定")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .lineLimit(1)

      Spacer()

      if isAIGenerated {
        Image(systemName: "sparkles")
          .font(.caption)
          .foregroundColor(.white.opacity(0.8))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(cardColor.gradient)
    )
  }

  /// カレンダーの色を取得
  private var cardColor: Color {
    if let cgColor = event.calendar?.cgColor {
      return Color(cgColor: cgColor)
    }
    return .blue
  }
}

/// 予定カードのプレビュー用
struct DayEventCardView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 8) {
      // プレビュー用のダミービュー
      HStack {
        Text("会議")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.white)
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.green.gradient)
      )

      HStack {
        Text("AI生成の予定")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.white)
        Spacer()
        Image(systemName: "sparkles")
          .font(.caption)
          .foregroundColor(.white.opacity(0.8))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.blue.gradient)
      )
    }
    .padding()
  }
}
