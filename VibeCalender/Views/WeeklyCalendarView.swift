//
//  WeeklyCalendarView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import EventKit
import SwiftUI

/// 週間カレンダービュー（Figmaデザイン + Liquid Glass）
struct WeeklyCalendarView: View {
  @EnvironmentObject var eventManager: EventManager
  @State private var currentDate = Date()
  @State private var events: [Date: [EKEvent]] = [:]

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 0) {
      // ヘッダー（Liquid Glass）
      headerView

      // 週間リスト（下部にスペースを追加してタブバーの後ろまでスクロール可能に）
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(daysInCurrentWeek, id: \.self) { date in
            DayRowView(
              date: date,
              events: events[calendar.startOfDay(for: date)] ?? []
            )
            .padding(.horizontal, 16)
          }

          // タブバーの後ろまでスクロールするための余白
          Spacer(minLength: 140)
        }
        .padding(.vertical, 8)
      }
    }
    .background(
      // 背景グラデーション
      LinearGradient(
        colors: [
          Color(.systemBackground),
          Color(.systemGray6).opacity(0.3),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onAppear {
      loadEvents()
    }
  }

  // MARK: - ヘッダー（Liquid Glass）

  private var headerView: some View {
    HStack {
      Button(action: previousWeek) {
        Image(systemName: "chevron.left")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .frame(width: 44, height: 44)
          .glassCard()
      }

      Spacer()

      Text(monthYearString)
        .font(.title)
        .fontWeight(.bold)

      Spacer()

      Button(action: nextWeek) {
        Image(systemName: "chevron.right")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .frame(width: 44, height: 44)
          .glassCard()
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }

  // MARK: - 週の日付

  private var daysInCurrentWeek: [Date] {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
      return []
    }

    var dates: [Date] = []
    var date = weekInterval.start

    while date < weekInterval.end {
      dates.append(date)
      date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    return dates
  }

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: currentDate)
  }

  // MARK: - Actions

  private func previousWeek() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
      loadEvents()
    }
  }

  private func nextWeek() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
      loadEvents()
    }
  }

  private func loadEvents() {
    guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
      return
    }

    let predicate = eventManager.store.predicateForEvents(
      withStart: weekInterval.start,
      end: weekInterval.end,
      calendars: nil
    )

    let ekEvents = eventManager.store.events(matching: predicate)

    // 日付ごとにグループ化
    var grouped: [Date: [EKEvent]] = [:]
    for event in ekEvents {
      guard let startDate = event.startDate else { continue }
      let dayStart = calendar.startOfDay(for: startDate)
      grouped[dayStart, default: []].append(event)
    }

    events = grouped
  }
}

// MARK: - 日付行ビュー（Liquid Glass適用）

struct DayRowView: View {
  let date: Date
  let events: [EKEvent]

  private let calendar = Calendar.current

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      // 日付バッジ
      dateBadge

      // 予定リスト
      VStack(spacing: 8) {
        if events.isEmpty {
          // 空の場合（Liquid Glass風）
          emptyEventCard
        } else {
          ForEach(events, id: \.eventIdentifier) { event in
            DayEventCardView(
              event: event,
              isAIGenerated: false
            )
          }
        }
      }
    }
  }

  // MARK: - 日付バッジ

  private var dateBadge: some View {
    VStack(spacing: 4) {
      Text(weekdayString)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      Text(dayString)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(isToday ? .white : .primary)
        .frame(width: 40, height: 40)
        .background(
          Group {
            if isToday {
              Circle()
                .fill(
                  LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
            } else {
              Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                  Circle()
                    .stroke(
                      LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                      lineWidth: 0.5
                    )
                )
            }
          }
        )
    }
    .frame(width: 48)
  }

  // MARK: - 空の予定カード

  private var emptyEventCard: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(.ultraThinMaterial)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(
            LinearGradient(
              colors: [
                Color.white.opacity(0.5),
                Color.white.opacity(0.1),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 0.5
          )
      )
      .frame(height: 52)
  }

  private var weekdayString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: date)
  }

  private var dayString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  private var isToday: Bool {
    calendar.isDateInToday(date)
  }
}

// MARK: - Liquid Glass Modifier

extension View {
  /// Liquid Glass風のカードスタイルを適用
  func glassCard() -> some View {
    self
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)

          RoundedRectangle(cornerRadius: 12)
            .fill(
              LinearGradient(
                colors: [
                  Color.white.opacity(0.3),
                  Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )

          RoundedRectangle(cornerRadius: 12)
            .stroke(
              LinearGradient(
                colors: [
                  Color.white.opacity(0.6),
                  Color.white.opacity(0.1),
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
}

#Preview {
  WeeklyCalendarView()
    .environmentObject(EventManager())
}
