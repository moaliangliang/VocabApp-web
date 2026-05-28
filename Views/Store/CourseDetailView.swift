// Views/Store/CourseDetailView.swift
import SwiftUI

struct CourseDetailView: View {
    let course: Course
    let isPurchased: Bool
    let onPurchase: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 课程头部
                VStack(spacing: 8) {
                    Text(course.name)
                        .font(.largeTitle).bold()
                    Text(course.desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // 信息卡片
                VStack(spacing: 12) {
                    infoRow(title: "词汇量", value: "\(course.wordCount) 词")
                    infoRow(title: "阅读文章", value: "\(course.articleCount) 篇")
                    infoRow(title: "免费体验", value: "前 \(Constants.freeWordLimit) 词")
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                // 购买/已购按钮
                if isPurchased {
                    Label("已购买", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Button(action: onPurchase) {
                        Text("¥\(course.price) — 立即购买")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}
