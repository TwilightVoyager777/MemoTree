//
//  Image+Extensions.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI

// MARK: - 智能图片加载视图
struct SmartImageView: View {
    let imageSource: String?
    let placeholder: Image
    let width: CGFloat?
    let height: CGFloat?
    let contentMode: ContentMode
    
    init(
        imageSource: String?,
        placeholder: Image = Image(systemName: "photo"),
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.imageSource = imageSource
        self.placeholder = placeholder
        self.width = width
        self.height = height
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let imageSource = imageSource, !imageSource.isEmpty {
                if imageSource.hasPrefix("http") {
                    // 网络图片
                    AsyncImage(url: URL(string: imageSource)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    } placeholder: {
                        placeholder
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(width: width, height: height)
                    }
                } else {
                    // 本地图片
                    Image(imageSource)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            } else {
                // 占位符
                placeholder
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

// MARK: - 用户头像视图
struct UserAvatarView: View {
    let avatarSource: String?
    let size: CGFloat
    
    init(avatarSource: String?, size: CGFloat = 40) {
        self.avatarSource = avatarSource
        self.size = size
    }
    
    var body: some View {
        SmartImageView(
            imageSource: avatarSource,
            placeholder: Image(systemName: "person.circle.fill"),
            width: size,
            height: size,
            contentMode: .fill
        )
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.white, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
} 