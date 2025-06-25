//
//  DiscussView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

struct DiscussView: View {
    @State private var selectedTab = 0
    @State private var animateContent = false
    @State private var showingNewPost = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 纯白色背景
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 头部区域
                    CommunityHeaderView(showingNewPost: $showingNewPost)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    // 分类选择器
                    CommunityTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    
                    // 内容区域
                    TabView(selection: $selectedTab) {
                        CommunityFeedView()
                            .tag(0)
                        
                        DiscussionListView()
                            .tag(1)
                        
                        NotificationView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateContent)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewPost) {
            NewPostView()
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}

// MARK: - 社区头部
struct CommunityHeaderView: View {
    @Binding var showingNewPost: Bool
    @State private var animateHeader = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("社区")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(animateHeader ? 1 : 0)
                    .offset(x: animateHeader ? 0 : -20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateHeader)
                
                Text("与探索者们分享精彩时刻")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(animateHeader ? 1 : 0)
                    .offset(x: animateHeader ? 0 : -15)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: animateHeader)
            }
            
            Spacer()
            
            // 发布按钮
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingNewPost = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green.opacity(0.2), .blue.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            .scaleEffect(animateHeader ? 1 : 0.8)
            .opacity(animateHeader ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateHeader)
        }
        .onAppear {
            animateHeader = true
        }
    }
}

// MARK: - 分类选择器
struct CommunityTabSelector: View {
    @Binding var selectedTab: Int
    
    let tabs = ["动态", "讨论", "通知"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == index ? .green : .secondary)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.green)
                            .frame(width: selectedTab == index ? 24 : 0, height: 3)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 社区动态
struct CommunityFeedView: View {
    @State private var animatePosts = false
    
    // 添加基本的模拟动态数据（第三步测试）
    let mockPosts: [CommunityPost] = [
        CommunityPost(
            id: 1,
            author: AuthService.shared.demoUser!,
            content: "今天在外滩看到了最美的日落！黄浦江的波光粼粼配上远处的高楼大厦，真的是城市漫步的绝佳时刻 🌅✨",
            images: ["community_1", "community_2"],
            location: "外滩滨江步道",
            likes: 42,
            comments: 18,
            shares: 5,
            timestamp: "2小时前"
        ),
        CommunityPost(
            id: 2,
            author: AuthService.shared.demoUser!,
            content: "豫园的小笼包真的太香了！推荐大家走完豫园老街路线后一定要尝尝这家老字号，配上一壶好茶，完美！🥟🍵",
            images: ["community_3"],
            location: "豫园商城",
            likes: 28,
            comments: 12,
            shares: 3,
            timestamp: "4小时前"
        ),
        CommunityPost(
            id: 3,
            author: AuthService.shared.demoUser!,
            content: "田子坊的艺术氛围太棒了！每一个小角落都有惊喜，建议大家慢慢逛，细细品味每一件艺术品和创意小店 🎨",
            images: [],
            location: "田子坊",
            likes: 35,
            comments: 9,
            shares: 7,
            timestamp: "1天前"
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(mockPosts.enumerated()), id: \.element.id) { index, post in
                    CommunityPostCard(post: post, delay: Double(index) * 0.1)
                }
                
                // 底部空间
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
}

struct CommunityPost {
    let id: Int
    let author: User
    let content: String
    let images: [String]
    let location: String?
    let likes: Int
    let comments: Int
    let shares: Int
    let timestamp: String
}

struct CommunityPostCard: View {
    let post: CommunityPost
    let delay: Double
    @State private var animate = false
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 用户信息头部
            HStack(spacing: 12) {
                UserAvatarView(
                    avatarSource: post.author.avatar,
                    size: 44
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.nickname ?? post.author.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        if let location = post.location {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(post.timestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // 内容文本
            Text(post.content)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // 图片网格
            if !post.images.isEmpty {
                ImageGridView(images: post.images)
            }
            
            // 交互按钮
            HStack(spacing: 24) {
                PostActionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    text: "\(post.likes + (isLiked ? 1 : 0))",
                    color: isLiked ? .pink : .secondary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }
                
                PostActionButton(
                    icon: "message",
                    text: "\(post.comments)",
                    color: .secondary
                ) {
                    // TODO: 打开评论
                }
                
                PostActionButton(
                    icon: "arrowshape.turn.up.right",
                    text: "\(post.shares)",
                    color: .secondary
                ) {
                    // TODO: 分享
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .scaleEffect(animate ? 1.0 : 0.9)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

struct PostActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImageGridView: View {
    let images: [String]
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(images.count, 2))
        
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                SmartImageView(
                    imageSource: imageUrl,
                    placeholder: Image(systemName: "photo"),
                    width: nil,
                    height: images.count == 1 ? 200 : 120,
                    contentMode: .fill
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - 讨论列表
struct DiscussionListView: View {
    // 添加基本的模拟讨论数据（第三步测试）
    let mockDiscussions: [DiscussionTopic] = [
        DiscussionTopic(
            id: 1,
            title: "新手求助：城市漫步时拍照有什么技巧？",
            author: "城市探索者",
            replies: 15,
            lastReply: "2小时前",
            isHot: true
        ),
        DiscussionTopic(
            id: 2,
            title: "分享一条超赞的雨天路线，适合文艺青年",
            author: "城市探索者",
            replies: 8,
            lastReply: "4小时前",
            isHot: false
        ),
        DiscussionTopic(
            id: 3,
            title: "大家都是用什么APP记录漫步轨迹的？",
            author: "城市探索者",
            replies: 23,
            lastReply: "1天前",
            isHot: true
        ),
        DiscussionTopic(
            id: 4,
            title: "外滩最佳拍照时间和角度推荐",
            author: "城市探索者",
            replies: 12,
            lastReply: "2天前",
            isHot: false
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(mockDiscussions.enumerated()), id: \.element.id) { index, discussion in
                    DiscussionTopicCard(discussion: discussion, delay: Double(index) * 0.1)
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
}

struct DiscussionTopic {
    let id: Int
    let title: String
    let author: String
    let replies: Int
    let lastReply: String
    let isHot: Bool
}

struct DiscussionTopicCard: View {
    let discussion: DiscussionTopic
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 热门标识
            if discussion.isHot {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(discussion.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Text("by \(discussion.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("\(discussion.replies) 回复")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(discussion.lastReply)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : -30)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 通知视图
struct NotificationView: View {
    // 添加基本的模拟通知数据（第三步测试）
    private let mockNotifications = [
        NotificationItem(
            id: 1,
            type: .like,
            title: "有人点赞了你的动态",
            content: "用户 @探索者小王 点赞了你在西湖的探索记录",
            timestamp: "5分钟前",
            isRead: false
        ),
        NotificationItem(
            id: 2,
            type: .comment,
            title: "新的评论",
            content: "用户 @城市漫步者 评论了你的路线：这条路线真的很棒！",
            timestamp: "30分钟前",
            isRead: false
        ),
        NotificationItem(
            id: 3,
            type: .follow,
            title: "新的关注者",
            content: "用户 @城市行者 关注了你",
            timestamp: "2小时前",
            isRead: true
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(mockNotifications.enumerated()), id: \.element.id) { index, notification in
                    NotificationCard(notification: notification, delay: Double(index) * 0.1)
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
}

struct NotificationItem {
    let id: Int
    let type: NotificationType
    let title: String
    let content: String
    let timestamp: String
    let isRead: Bool
    
    enum NotificationType {
        case like, comment, follow, system
        
        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .comment: return "message.fill"
            case .follow: return "person.badge.plus"
            case .system: return "bell.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .like: return .pink
            case .comment: return .blue
            case .follow: return .green
            case .system: return .orange
            }
        }
    }
}

struct NotificationCard: View {
    let notification: NotificationItem
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(notification.type.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !notification.isRead {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(notification.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.timestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 新建动态视图
struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postContent = ""
    @State private var selectedLocation = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 内容输入
                VStack(alignment: .leading, spacing: 12) {
                    Text("分享你的探索")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $postContent)
                        .font(.subheadline)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // 位置选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("添加位置")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        
                        TextField("当前位置", text: $selectedLocation)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("新动态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") { 
                        // TODO: 发布动态
                        dismiss() 
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .disabled(postContent.isEmpty)
                }
            }
        }
    }
}

#Preview {
    DiscussView()
} 