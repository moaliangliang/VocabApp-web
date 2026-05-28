// Views/Store/CourseStoreView.swift
import SwiftUI

struct CourseStoreView: View {
    @State var viewModel: StoreViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            if viewModel.storeManager.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.storeManager.errorMessage {
                ContentUnavailableView("加载失败", systemImage: "wifi.slash",
                    description: Text(error))
            } else {
                List(viewModel.courses) { course in
                    NavigationLink(destination: CourseDetailView(
                        course: course,
                        isPurchased: viewModel.storeManager.isPurchased(course.productID),
                        onPurchase: { Task { await viewModel.purchase(course) } }
                    )) {
                        HStack(spacing: 16) {
                            // 课程图标
                            RoundedRectangle(cornerRadius: 12)
                                .fill(courseColor(course.id))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(course.id.prefix(2))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.name).font(.headline)
                                Text("\(course.wordCount) 词 · \(course.articleCount) 篇文章")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if viewModel.storeManager.isPurchased(course.productID) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("¥\(course.price)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("词库商店")
                .onAppear {
                    viewModel = StoreViewModel(
                        storeManager: StoreManager(),
                        modelContext: modelContext
                    )
                }
            }
        }
    }

    private func courseColor(_ id: String) -> Color {
        let colors: [String: Color] = [
            "CET4": .blue, "CET6": .purple, "Kaoyan": .red,
            "TOEFL": .orange, "IELTS": .green, "GRE": .indigo
        ]
        return colors[id] ?? .gray
    }
}
