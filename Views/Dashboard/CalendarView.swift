// Views/Dashboard/CalendarView.swift
import SwiftUI

struct CalendarView: View {
    let logs: [DailyLog]
    let streak: Int

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("学习日历")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak) 天连续")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // 星期头
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                let days = monthDays()
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        dayCell(date: date)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
    }

    private func dayCell(date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isCompleted = logs.contains { calendar.isDate($0.date, inSameDayAs: date) && $0.isCompleted }
        let isToday = calendar.isDateInToday(date)

        return Text("\(day)")
            .font(.caption)
            .frame(width: 32, height: 32)
            .background(isCompleted ? Color.green.opacity(0.3) : Color.clear)
            .clipShape(Circle())
            .overlay(isToday ? Circle().stroke(Color.blue, lineWidth: 1.5) : nil)
            .foregroundColor(isToday ? .blue : .primary)
    }

    private func monthDays() -> [Date?] {
        let today = Date()
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let range = calendar.range(of: .day, in: .month, for: today)!
        let weekday = calendar.component(.weekday, from: firstDay) - 1

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}
