// Utilities/View+Extensions.swift
import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
