//
//  DayEventCardView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import SwiftUI
import EventKit

/// 予定カードビュー（Liquid Glass + カレンダー色別）
struct DayEventCardView: View {
    @EnvironmentObject var eventManager: EventManager
    let event: EKEvent
    
    @State private var showDetail = false
    
    var isAIGenerated: Bool {
        eventManager.isAIGenerated(event)
    }
    
    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(spacing: 12) {
                // カラーインジケーター
                RoundedRectangle(cornerRadius: 2)
                    .fill(cardColor.gradient)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title ?? "予定")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let startDate = event.startDate {
                        Text(timeString(from: startDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isAIGenerated {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                // Liquid Glass風背景
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardColor.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    cardColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: cardColor.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            EventDetailView(event: event)
        }
    }
    
    /// カレンダーの色を取得
    private var cardColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 12) {
        // プレビュー用のダミービュー
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.green.gradient)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("会議")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("10:00")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.green.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
