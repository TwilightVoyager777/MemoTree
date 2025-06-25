//
//  CreateRouteSharedComponents.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

// MARK: - 流式布局组件
struct FlowLayout<T: Hashable, Content: View>: View {
    let items: [T]
    let content: (T) -> Content
    
    init(_ items: [T], @ViewBuilder content: @escaping (T) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        let chunked = items.chunked(into: 3) // 简化实现，每行3个
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(chunked.enumerated()), id: \.offset) { _, chunk in
                HStack(spacing: 8) {
                    ForEach(chunk, id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - 数组分块扩展
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - 颜色扩展（兼容性）
extension Color {
    static var compatibleTertiary: Color {
        if #available(iOS 13.0, *) {
            return Color(.tertiaryLabel)
        } else {
            return Color.gray.opacity(0.6)
        }
    }
    
    static var compatibleQuaternary: Color {
        if #available(iOS 13.0, *) {
            return Color(.quaternaryLabel)
        } else {
            return Color.gray.opacity(0.4)
        }
    }
} 