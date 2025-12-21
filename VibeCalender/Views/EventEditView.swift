//
//  EventEditView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/19.
//

import EventKit
import SwiftUI

/// 予定追加・編集画面（Liquid Glass）
struct EventEditView: View {
  @EnvironmentObject var eventManager: EventManager
  @Environment(\.dismiss) var dismiss

  // 編集対象（nilの場合は新規作成）
  var event: EKEvent?

  @State private var title: String = ""
  @State private var startDate: Date = Date()
  @State private var endDate: Date = Date().addingTimeInterval(3600)
  @State private var selectedCalendar: EKCalendar?
  @State private var notes: String = ""

  @State private var showError = false
  @State private var errorMessage = ""

  var isNewEvent: Bool {
    event == nil
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          // タイトル入力
          titleSection

          // 日時選択
          dateTimeSection

          // カレンダー選択
          calendarSection

          // メモ
          notesSection

          // 保存ボタン
          saveButton

          Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
      }
      .background(
        LinearGradient(
          colors: [
            Color(.systemBackground),
            Color(.systemGray6).opacity(0.3),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .navigationTitle(isNewEvent ? "予定を追加" : "予定を編集")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("キャンセル") {
            dismiss()
          }
        }
      }
      .onAppear {
        loadEventData()
      }
      .alert("エラー", isPresented: $showError) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
    }
  }

  // MARK: - タイトルセクション

  private var titleSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("タイトル", systemImage: "pencil")
        .font(.caption)
        .foregroundColor(.secondary)

      TextField("予定のタイトル", text: $title)
        .font(.body)
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .glassEffect(.standard, in: RoundedRectangle(cornerRadius: 16))
        )
    }
  }

  // MARK: - 日時セクション

  private var dateTimeSection: some View {
    VStack(spacing: 16) {
      // 開始日時
      VStack(alignment: .leading, spacing: 8) {
        Label("開始", systemImage: "clock")
          .font(.caption)
          .foregroundColor(.secondary)

        DatePicker("", selection: $startDate)
          .datePickerStyle(.compact)
          .labelsHidden()
          .padding(12)
          .background(
            glassBackground
          )
          .onChange(of: startDate) { _, newValue in
            // 開始時間が終了時間を超えたら調整
            if newValue >= endDate {
              endDate = newValue.addingTimeInterval(3600)
            }
          }
      }

      // 終了日時
      VStack(alignment: .leading, spacing: 8) {
        Label("終了", systemImage: "clock.badge.checkmark")
          .font(.caption)
          .foregroundColor(.secondary)

        DatePicker("", selection: $endDate, in: startDate...)
          .datePickerStyle(.compact)
          .labelsHidden()
          .padding(12)
          .background(
            glassBackground
          )
      }
    }
  }

  // MARK: - カレンダーセクション

  private var calendarSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("カレンダー", systemImage: "calendar")
        .font(.caption)
        .foregroundColor(.secondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(eventManager.calendars, id: \.calendarIdentifier) { calendar in
            CalendarChip(
              calendar: calendar,
              isSelected: selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
            ) {
              selectedCalendar = calendar
            }
          }
        }
        .padding(.horizontal, 4)
      }
    }
  }

  // MARK: - メモセクション

  private var notesSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("メモ", systemImage: "note.text")
        .font(.caption)
        .foregroundColor(.secondary)

      TextEditor(text: $notes)
        .font(.body)
        .frame(minHeight: 100)
        .padding(12)
        .scrollContentBackground(.hidden)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .glassEffect(.standard, in: RoundedRectangle(cornerRadius: 16))
        )
    }
  }

  // MARK: - 保存ボタン

  private var saveButton: some View {
    Button(action: saveEvent) {
      HStack {
        Image(systemName: isNewEvent ? "plus.circle.fill" : "checkmark.circle.fill")
        Text(isNewEvent ? "予定を追加" : "変更を保存")
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
    .disabled(title.isEmpty)
    .opacity(title.isEmpty ? 0.6 : 1.0)
  }

  // MARK: - Helpers

  private var glassBackground: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(.ultraThinMaterial)
      .glassEffect(.standard, in: RoundedRectangle(cornerRadius: 16))
  }

  private func loadEventData() {
    if let event = event {
      title = event.title ?? ""
      startDate = event.startDate ?? Date()
      endDate = event.endDate ?? Date().addingTimeInterval(3600)
      selectedCalendar = event.calendar
      notes = event.notes?.replacingOccurrences(of: "\n[AI Generated]", with: "") ?? ""
    } else {
      selectedCalendar = eventManager.defaultCalendar
    }
  }

  private func saveEvent() {
    do {
      if let existingEvent = event {
        // 更新
        try eventManager.updateEvent(
          existingEvent,
          title: title,
          startDate: startDate,
          endDate: endDate,
          calendar: selectedCalendar,
          notes: notes
        )
      } else {
        // 新規作成
        _ = try eventManager.createEvent(
          title: title,
          startDate: startDate,
          endDate: endDate,
          calendar: selectedCalendar,
          notes: notes.isEmpty ? nil : notes
        )
      }
      dismiss()
    } catch {
      errorMessage = "保存に失敗しました: \(error.localizedDescription)"
      showError = true
    }
  }
}

// MARK: - カレンダー選択チップ

struct CalendarChip: View {
  let calendar: EKCalendar
  let isSelected: Bool
  let action: () -> Void

  var calendarColor: Color {
    Color(cgColor: calendar.cgColor)
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Circle()
          .fill(calendarColor.gradient)
          .frame(width: 12, height: 12)

        Text(calendar.title)
          .font(.subheadline)
          .fontWeight(isSelected ? .semibold : .regular)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        ZStack {
          if isSelected {
            RoundedRectangle(cornerRadius: 20)
              .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 20)
              .fill(calendarColor.opacity(0.15))

            RoundedRectangle(cornerRadius: 20)
              .stroke(calendarColor.opacity(0.5), lineWidth: 1.5)
          } else {
            RoundedRectangle(cornerRadius: 20)
              .fill(.ultraThinMaterial)
              .glassEffect(.standard, in: RoundedRectangle(cornerRadius: 20))
          }
        }
      )
      .foregroundColor(isSelected ? calendarColor : .primary)
    }
  }
}

#Preview {
  EventEditView()
    .environmentObject(EventManager())
}
