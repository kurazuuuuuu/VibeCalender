//
//  EventDetailView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/19.
//

import SwiftUI
import EventKit

/// 予定詳細表示画面（Liquid Glass）
struct EventDetailView: View {
    @EnvironmentObject var eventManager: EventManager
    @Environment(\.dismiss) var dismiss
    
    let event: EKEvent
    
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダーカード
                    headerCard
                    
                    // 詳細情報
                    detailsCard
                    
                    // アクションボタン
                    actionButtons
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("予定詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        showEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EventEditView(event: event)
        }
        .alert("予定を削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("この予定を削除しますか？")
        }
    }
    
    // MARK: - ヘッダーカード
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // カラーインジケーター
                RoundedRectangle(cornerRadius: 4)
                    .fill(calendarColor.gradient)
                    .frame(width: 6, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title ?? "予定")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(event.calendar?.title ?? "カレンダー")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if eventManager.isAIGenerated(event) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(calendarColor.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                calendarColor.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: calendarColor.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - 詳細カード
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            // 日時
            DetailRow(
                icon: "clock",
                title: "日時",
                value: dateTimeString
            )
            
            Divider()
                .padding(.leading, 52)
            
            // 期間
            DetailRow(
                icon: "hourglass",
                title: "期間",
                value: durationString
            )
            
            if let notes = event.notes, !notes.isEmpty {
                Divider()
                    .padding(.leading, 52)
                
                DetailRow(
                    icon: "note.text",
                    title: "メモ",
                    value: notes.replacingOccurrences(of: "\n[AI Generated]", with: "")
                )
            }
        }
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - アクションボタン
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 編集ボタン
            Button(action: { showEditSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("予定を編集")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    }
                )
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            // 削除ボタン
            Button(action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("予定を削除")
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.05))
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    }
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private var calendarColor: Color {
        if let cgColor = event.calendar?.cgColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }
    
    private var dateTimeString: String {
        guard let startDate = event.startDate else { return "" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 (E) HH:mm"
        
        var result = formatter.string(from: startDate)
        
        if let endDate = event.endDate {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            result += " - " + timeFormatter.string(from: endDate)
        }
        
        return result
    }
    
    private var durationString: String {
        guard let startDate = event.startDate, let endDate = event.endDate else { return "" }
        
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)時間\(minutes)分"
        } else if hours > 0 {
            return "\(hours)時間"
        } else {
            return "\(minutes)分"
        }
    }
    
    private func deleteEvent() {
        do {
            try eventManager.deleteEvent(event)
            dismiss()
        } catch {
            print("Error deleting event: \(error)")
        }
    }
}

// MARK: - 詳細行

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
