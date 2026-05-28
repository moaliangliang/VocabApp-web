// Views/Dashboard/ProgressCharts.swift
import SwiftUI

struct ProgressCharts: View {
    let masteredFraction: Double
    let masteredCount: Int
    let learningCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 20) {
            // 掌握度分布
            VStack(alignment: .leading, spacing: 8) {
                Text("掌握度分布").font(.headline)

                HStack(spacing: 16) {
                    donutChart

                    VStack(alignment: .leading, spacing: 8) {
                        legendItem(color: .green, label: "已掌握", count: masteredCount)
                        legendItem(color: .orange, label: "学习中", count: learningCount)
                        let unlearned = totalCount - masteredCount - learningCount
                        legendItem(color: .gray.opacity(0.4), label: "未学习", count: max(0, unlearned))
                    }
                }
            }

            // 课程进度条（示例）
            if totalCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("总体进度").font(.headline)
                    ProgressView(value: masteredFraction)
                        .tint(.green)
                    Text("已掌握 \(masteredCount)/\(totalCount) 词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var donutChart: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            if masteredFraction > 0 {
                Circle()
                    .trim(from: 0, to: masteredFraction)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text("\(Int(masteredFraction * 100))%")
                .font(.title3).bold()
        }
        .frame(width: 100, height: 100)
    }

    private func legendItem(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundColor(.secondary)
            Text("\(count)").font(.caption).bold()
        }
    }
}
