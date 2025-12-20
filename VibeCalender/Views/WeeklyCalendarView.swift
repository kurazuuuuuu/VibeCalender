//
//  WeeklyCalendarView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import EventKit
import SwiftUI

/// カレンダービュー（月間スクロール形式）
struct WeeklyCalendarView: View {
  @EnvironmentObject var eventManager: EventManager
  @State private var currentDate = Date()
  @State private var events: [Date: [EKEvent]] = [:]

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 0) {
      // ヘッダー（月切り替え）
      headerView

      // 月間リスト（スクロール可能）
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(daysInCurrentMonth, id: \.self) { date in
              DayRowView(
                date: date,
                events: events[calendar.startOfDay(for: date)] ?? []
              )
              .id(date)
              .padding(.horizontal, 16)
            }

            // タブバーの後ろまでスクロールするための余白
            Spacer(minLength: 140)
          }
          .padding(.vertical, 8)
        }
        .onAppear {
          // 今日の日付にスクロール
          if let today = daysInCurrentMonth.first(where: { calendar.isDateInToday($0) }) {
            proxy.scrollTo(today, anchor: .top)
          }
        }
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
    .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
      // 外部での変更を検知してリロード
      loadEvents()
    }
  }

  // MARK: - ヘッダー（月切り替え）

  private var headerView: some View {
    HStack {
      Button(action: previousMonth) {
        Image(systemName: "chevron.left")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .frame(width: 44, height: 44)
          .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
      }

      Spacer()

      Text(monthYearString)
        .font(.title2)
        .fontWeight(.bold)

      Spacer()

      Button(action: nextMonth) {
        Image(systemName: "chevron.right")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .frame(width: 44, height: 44)
          .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }

  // MARK: - 月の日付

  private var daysInCurrentMonth: [Date] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
      return []
    }

    var dates: [Date] = []
    var date = monthInterval.start

    while date < monthInterval.end {
      dates.append(date)
      date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    return dates
  }

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年 M月"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: currentDate)
  }

  // MARK: - Actions

  private func previousMonth() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
      loadEvents()
    }
  }

  private func nextMonth() {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
      loadEvents()
    }
  }

  private func loadEvents() {
    guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
      return
    }

    let predicate = eventManager.store.predicateForEvents(
      withStart: monthInterval.start,
      end: monthInterval.end,
      calendars: nil
    )

    let ekEvents = eventManager.store.events(matching: predicate)

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
          emptyEventCard
        } else {
          ForEach(events, id: \.eventIdentifier) { event in
            DayEventCardView(event: event)
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
        .foregroundColor(isWeekend ? .red.opacity(0.8) : .secondary)

      Text(dayString)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(isToday ? .white : .primary)
        .frame(width: 44, height: 44)
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
    .frame(width: 50)
  }

  // MARK: - 空の予定カード

  private var emptyEventCard: some View {
    HStack {
      Spacer()
    }
    .frame(height: 20)  // スクロール主体の月間表示では高さを抑える
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

  private var isWeekend: Bool {
    let weekday = calendar.component(.weekday, from: date)
    return weekday == 1 || weekday == 7  // 日曜日 or 土曜日
  }
}

// MARK: - Liquid Glass Modifier (Temporary helper if not global)

#Preview {
  WeeklyCalendarView()
    .environmentObject(EventManager())
}
