//
//  DiscoverView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//  首页 - 主要展示精选路线、热门探索和主题分类
//

import SwiftUI
import Combine

struct DiscoverView: View {
    @StateObject private var routeService = RouteService.shared
    @State private var searchText = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var animateCards = false
    @State private var showSearchResults = false
    @State private var showTutorial = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 纯白色背景
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 28) {
                        // 顶部欢迎区域
                        WelcomeHeaderView(showTutorial: $showTutorial)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // 增强搜索栏
                        EnhancedSearchBar(text: $searchText, showResults: $showSearchResults)
                            .padding(.horizontal, 20)
                            .opacity(animateCards ? 1 : 0)
                            .scaleEffect(animateCards ? 1 : 0.9)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateCards)
                        
                        // 主题探索 - 移到前面，更突出
                        ThemeRoutesSection()
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 40)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
                        
                        // 精选路线
                        FeaturedRoutesSection()
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 40)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateCards)
                        
                        // 热门探索
                        PopularRoutesSection()
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 40)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateCards)
                        
                        // 底部安全间距
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 20)
                    }
                    .padding(.bottom, 80) // 为底部导航栏留出空间
                }
                .refreshable {
                    await loadDataWithAnimation()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // 确保在iPad上正确显示
        .sheet(isPresented: $showTutorial) {
            TutorialView()
        }
        .onAppear {
            loadData()
            withAnimation {
                animateCards = true
            }
        }
    }
    
    private func loadData() {
        // 加载精选路线
        routeService.fetchFeaturedRoutes()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // 加载热门路线
        routeService.fetchPopularRoutes()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    private func loadDataWithAnimation() async {
        // 重置动画状态
        withAnimation(.easeOut(duration: 0.3)) {
            animateCards = false
        }
        
        // 加载数据
        loadData()
        
        // 重新触发动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animateCards = true
            }
        }
    }
}

// MARK: - 欢迎头部视图
struct WelcomeHeaderView: View {
    @Binding var showTutorial: Bool
    @State private var currentTime = Date()
    @State private var animateWelcome = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(getGreeting())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(animateWelcome ? 1 : 0)
                        .offset(x: animateWelcome ? 0 : -20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateWelcome)
                    
                    Text("准备开始今天的城市探索吗？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(animateWelcome ? 1 : 0)
                        .offset(x: animateWelcome ? 0 : -15)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateWelcome)
                }
                
                Spacer()
                
                // 教程按钮
                Button(action: {
                    showTutorial = true
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
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                .scaleEffect(animateWelcome ? 1 : 0.8)
                .opacity(animateWelcome ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateWelcome)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
            
            withAnimation {
                animateWelcome = true
            }
        }
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "早上好，欢迎来到MemoTree 👋"
        case 12..<18: return "下午好，探索精彩路线 ☀️"
        case 18..<22: return "晚上好，发现夜景之美 🌆"
        default: return "夜深了，明天再来探索 🌙"
        }
    }
}

// MARK: - 增强搜索栏
struct EnhancedSearchBar: View {
    @Binding var text: String
    @Binding var showResults: Bool
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(isEditing ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isEditing)
                }
                
                TextField("搜索路线、地点或探索灵感", text: $text)
                    .focused($isFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
                    .font(.system(size: 16, weight: .medium))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isEditing = true
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            text = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.green.opacity(isEditing ? 0.6 : 0.2), lineWidth: 1.5)
            )
            .scaleEffect(isEditing ? 1.02 : 1.0)
            .shadow(color: .black.opacity(isEditing ? 0.1 : 0.05), 
                   radius: isEditing ? 12 : 6, 
                   x: 0, y: isEditing ? 6 : 3)
            
            if isEditing {
                Button("取消") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isEditing = false
                        text = ""
                        isFocused = false
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.green)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEditing)
    }
}

struct ModernActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let delay: Double
    @State private var isPressed = false
    @State private var animate = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .backdrop(blur: 10)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.96 : (animate ? 1.0 : 0.8))
            .opacity(animate ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 统一区域标题组件
struct SectionHeaderView: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let buttonColor: Color
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(buttonText)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(buttonColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(buttonColor.opacity(0.1), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                )
            }
            .scaleEffect(0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: false)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 精选路线区域（保持原有逻辑但更新样式）
struct FeaturedRoutesSection: View {
    @StateObject private var routeService = RouteService.shared
    @State private var showingAllRoutes = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(
                title: "精选路线",
                subtitle: "编辑精选，品质保证",
                buttonText: "查看全部",
                buttonColor: .green
            ) {
                showingAllRoutes = true
            }
            
            if routeService.featuredRoutes.isEmpty {
                LoadingView(message: "寻找精选路线...")
                    .frame(height: 220)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(routeService.featuredRoutes.enumerated()), id: \.element.id) { index, route in
                            EnhancedRouteCard(route: route, style: .featured, animationDelay: Double(index) * 0.1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.trailing, 4) // 右侧额外间距，防止阴影被裁剪
                }
            }
        }
        .sheet(isPresented: $showingAllRoutes) {
            AllRoutesView()
        }
    }
}

// MARK: - 热门路线区域（保持原有逻辑但更新样式）
struct PopularRoutesSection: View {
    @StateObject private var routeService = RouteService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(
                title: "热门探索",
                subtitle: "大家都在走的路线",
                buttonText: "查看排行",
                buttonColor: .orange
            ) {
                // TODO: 导航到热门路线排行榜
            }
            
            if routeService.popularRoutes.isEmpty {
                LoadingView(message: "加载热门路线...")
                    .frame(height: 180)
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(routeService.popularRoutes.prefix(3).enumerated()), id: \.element.id) { index, route in
                        EnhancedRouteListItem(route: route, rank: index + 1, animationDelay: Double(index) * 0.1)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - 主题路线区域（保持原有逻辑但更新样式）
struct ThemeRoutesSection: View {
    let themes: [(RouteTag, String, Color, String)] = [
        (.architecture, "建筑美学", .blue, "发现城市建筑之美"),
        (.nature, "自然治愈", .green, "在自然中找到宁静"),
        (.food, "美食探店", .orange, "品味城市烟火气"),
        (.art, "文艺探索", .purple, "感受艺术的魅力")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeaderView(
                title: "主题探索",
                subtitle: "按兴趣分类的精彩路线",
                buttonText: "更多主题",
                buttonColor: .purple
            ) {
                // TODO: 导航到所有主题
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: 12
            ) {
                ForEach(Array(themes.enumerated()), id: \.element.0) { index, theme in
                    ThemeCard(
                        tag: theme.0,
                        title: theme.1,
                        color: theme.2,
                        description: theme.3,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ThemeCard: View {
    let tag: RouteTag
    let title: String
    let color: Color
    let description: String
    let delay: Double
    @State private var animate = false
    @State private var isPressed = false
    @State private var showingSwipeableCards = false
    
    var body: some View {
        Button(action: {
            // 触觉反馈
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
                // 导航到翻卡界面
                showingSwipeableCards = true
            }
        }) {
            VStack(spacing: 16) {
                // 图标区域
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.25),
                                    color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 72)
                    
                    Image(systemName: tag.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3), value: isPressed)
                }
                
                // 文字信息
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: color.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.96 : (animate ? 1.0 : 0.8))
            .opacity(animate ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingSwipeableCards) {
            SwipeableRouteCardsView(theme: tag)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 增强路线卡片
struct EnhancedRouteCard: View {
    let route: Route
    let style: CardStyle
    let animationDelay: Double
    @State private var animate = false
    @State private var isPressed = false
    
    enum CardStyle {
        case featured, normal
    }
    
    var body: some View {
        NavigationLink(destination: RouteDetailView(route: route)) {
            VStack(alignment: .leading, spacing: 0) {
                // 路线图片
                SmartImageView(
                    imageSource: route.coverImage,
                    placeholder: Image(systemName: "photo"),
                    width: nil,
                    height: 120,
                    contentMode: .fill
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(width: style == .featured ? 280 : 240, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    // 渐变遮罩
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
                .overlay(
                    // 难度标签
                    VStack {
                        HStack {
                            Spacer()
                            Text(route.difficulty.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(route.difficulty.color, in: Capsule())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .padding(16)
                )
                
                // 路线信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(route.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 16) {
                        Label(route.formattedDistance, systemImage: "location.fill")
                        Label(route.formattedDuration, systemImage: "clock.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        // 评分星星
                        HStack(spacing: 2) {
                            ForEach(0..<5) { star in
                                Image(systemName: star < Int(route.averageRating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        
                        Text("(\(route.likes))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // 点赞数
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                                .font(.caption)
                            
                            Text("\(route.likes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .frame(width: style == .featured ? 280 : 240)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
            .scaleEffect(isPressed ? 0.96 : (animate ? 1.0 : 0.8))
            .opacity(animate ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(animationDelay)) {
                animate = true
            }
        }
    }
}

// MARK: - 增强路线列表项
struct EnhancedRouteListItem: View {
    let route: Route
    let rank: Int
    let animationDelay: Double
    @State private var animate = false
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: RouteDetailView(route: route)) {
            HStack(spacing: 16) {
                // 排名
                ZStack {
                    Circle()
                        .fill(getRankColor(rank))
                        .frame(width: 32, height: 32)
                    
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // 路线缩略图
                SmartImageView(
                    imageSource: route.coverImage,
                    placeholder: Image(systemName: "photo"),
                    width: 70,
                    height: 70,
                    contentMode: .fill
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
                
                // 路线信息
                VStack(alignment: .leading, spacing: 8) {
                    Text(route.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        Label(route.formattedDistance, systemImage: "location.fill")
                        Label(route.formattedDuration, systemImage: "clock.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < Int(route.averageRating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        Text("(\(route.likes))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(route.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(route.difficulty.color, in: Capsule())
                    
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        
                        Text("\(route.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.98 : (animate ? 1.0 : 0.9))
            .opacity(animate ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(animationDelay)) {
                animate = true
            }
        }
    }
    
    private func getRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .green
        }
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    let message: String
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // 外层圆环
                Circle()
                    .stroke(.green.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                // 内层加载圆环
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        .linear(duration: 1.2)
                        .repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
                
                // 中心图标
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("请稍候...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onAppear {
            rotationAngle = 360
            isAnimating = true
        }
    }
}

#Preview {
    DiscoverView()
} 
