// Views/Reading/ArticleListView.swift
import SwiftUI

struct ArticleListView: View {
    let articles: [Article]

    var body: some View {
        List(articles) { article in
            NavigationLink(destination: ArticleReaderView(article: article)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title).font(.headline)
                    HStack {
                        Text(article.level)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        Text("课程: \(article.courseID)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle("阅读")
    }
}
