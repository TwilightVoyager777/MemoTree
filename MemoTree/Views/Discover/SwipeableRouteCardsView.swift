//
//  SwipeableRouteCardsView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI

struct SwipeableRouteCardsView: View {
    let theme: RouteTag
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeService = RouteService.shared
    @State private var currentCardIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var isAnimating = false
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route?
    @State private var animateCards = false
    @State private var cardRotation: Double = 0
    @State private var nextCardScale: CGFloat = 0.9
    @State private var likedRoutes: [Route] = []
    @State private var dismissedRoutes: [Route] = []
    
    private var themeRoutes: [Route] {
        // 暂时返回所有路线，不按主题筛选
        return routeService.routes
    }
    
    private var currentRoute: Route? {
        guard currentCardIndex < themeRoutes.count else { return nil }
        return themeRoutes[currentCardIndex]
    }
    
    private var nextRoute: Route? {
        guard currentCardIndex + 1 < themeRoutes.count else { return nil }
        return themeRoutes[currentCardIndex + 1]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.color.opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部信息栏
                    HeaderInfoView(
                        theme: theme,
                        currentIndex: currentCardIndex + 1,
                        totalCount: themeRoutes.count,
                        likedCount: likedRoutes.count
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 卡片堆叠区域
                    ZStack {
                        if themeRoutes.isEmpty {
                            EmptyThemeView(theme: theme)
                        } else if currentCardIndex >= themeRoutes.count {
                            CompletionView(
                                theme: theme,
                                likedRoutes: likedRoutes,
                                onRestart: restartSwiping
                            )
                        } else {
                            // 下一张卡片（背景）
                            if let nextRoute = nextRoute {
                                RouteCard(route: nextRoute, theme: theme, dragOffset: .zero)
                                    .scaleEffect(nextCardScale)
                                    .opacity(0.8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: nextCardScale)
                            }
                            
                            // 当前卡片
                            if let currentRoute = currentRoute {
                                RouteCard(route: currentRoute, theme: theme, dragOffset: dragOffset)
                                    .offset(dragOffset)
                                    .rotationEffect(.degrees(cardRotation))
                                    .scaleEffect(animateCards ? 1.0 : 0.8)
                                    .opacity(animateCards ? 1.0 : 0.0)
                                    .gesture(
                                        DragGesture()
                                            .onChanged(handleDragChanged)
                                            .onEnded(handleDragEnded)
                                    )
                                    .onTapGesture {
                                        selectedRoute = currentRoute
                                        showingRouteDetail = true
                                    }
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateCards)
                            }
                        }
                    }
                    .frame(maxWidth: 400, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    
                    // 底部操作栏
                    if currentCardIndex < themeRoutes.count {
                        BottomActionBar(
                            onDislike: { dismissCurrentCard(liked: false) },
                            onLike: { dismissCurrentCard(liked: true) },
                            onDetail: { 
                                selectedRoute = currentRoute
                                showingRouteDetail = true
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingRouteDetail) {
            if let route = selectedRoute {
                RouteDetailView(route: route)
            }
        }
        .onAppear {
            loadThemeRoutes()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - 手势处理
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard !isAnimating else { return }
        
        dragOffset = value.translation
        
        // 计算旋转角度
        let rotationAngle = Double(dragOffset.width / 20)
        cardRotation = max(-15, min(15, rotationAngle))
        
        // 计算下一张卡片的缩放
        let progress = abs(dragOffset.width) / 300
        nextCardScale = 0.9 + (progress * 0.1)
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard !isAnimating else { return }
        
        let dragThreshold: CGFloat = 100
        let velocityThreshold: CGFloat = 500
        
        if abs(value.translation.width) > dragThreshold || abs(value.predictedEndTranslation.width) > velocityThreshold {
            // 达到阈值，执行滑走动画
            let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
            performSwipeAnimation(direction: direction)
        } else {
            // 未达到阈值，回弹
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                dragOffset = .zero
                cardRotation = 0
                nextCardScale = 0.9
            }
        }
    }
    
    private func performSwipeAnimation(direction: SwipeDirection) {
        isAnimating = true
        
        let finalOffset: CGSize = direction == .right 
            ? CGSize(width: 500, height: dragOffset.height * 2)
            : CGSize(width: -500, height: dragOffset.height * 2)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = finalOffset
            cardRotation = direction == .right ? 30 : -30
            nextCardScale = 1.0
        }
        
        // 延迟后切换到下一张卡片
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let route = currentRoute {
                if direction == .right {
                    likedRoutes.append(route)
                } else {
                    dismissedRoutes.append(route)
                }
            }
            
            nextCard()
        }
    }
    
    private func dismissCurrentCard(liked: Bool) {
        guard let route = currentRoute, !isAnimating else { return }
        
        if liked {
            likedRoutes.append(route)
            performSwipeAnimation(direction: .right)
        } else {
            dismissedRoutes.append(route)
            performSwipeAnimation(direction: .left)
        }
    }
    
    private func nextCard() {
        currentCardIndex += 1
        
        // 重置状态
        dragOffset = .zero
        cardRotation = 0
        nextCardScale = 0.9
        isAnimating = false
        
        // 如果还有卡片，重新触发动画
        if currentCardIndex < themeRoutes.count {
            animateCards = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
    }
    
    private func restartSwiping() {
        currentCardIndex = 0
        likedRoutes.removeAll()
        dismissedRoutes.removeAll()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animateCards = true
        }
    }
    
    private func loadThemeRoutes() {
        // 这里可以根据主题加载特定路线
        routeService.fetchAllRoutes()
    }
}

// MARK: - 滑动方向枚举
enum SwipeDirection {
    case left, right
}

// MARK: - 顶部信息栏
struct HeaderInfoView: View {
    let theme: RouteTag
    let currentIndex: Int
    let totalCount: Int
    let likedCount: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // 导航栏
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: theme.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.color)
                    
                    Text(theme.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text("探索路线")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 统计信息
            VStack(spacing: 2) {
                Text("\(likedCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.color)
                
                Text("喜欢")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 36)
        }
    }
}

// MARK: - 路线卡片
struct RouteCard: View {
    let route: Route
    let theme: RouteTag
    let dragOffset: CGSize
    
    private var swipeColorOverlay: some View {
        Group {
            if abs(dragOffset.width) > 30 {
                let progress = min(abs(dragOffset.width) / 200, 1.0)
                let isSwipingRight = dragOffset.width > 0
                
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                (isSwipingRight ? Color.green : Color.red).opacity(0.1 * progress),
                                (isSwipingRight ? Color.green : Color.red).opacity(0.3 * progress)
                            ]),
                            startPoint: isSwipingRight ? .leading : .trailing,
                            endPoint: isSwipingRight ? .trailing : .leading
                        )
                    )
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 路线图片区域
            routeImageView
            
            // 底部信息区域
            routeInfoView
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(swipeColorOverlay)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
    
    // 路线图片视图
    private var routeImageView: some View {
        Group {
            if let coverImage = route.coverImage, !coverImage.isEmpty {
                if coverImage.hasPrefix("http") {
                    AsyncImage(url: URL(string: coverImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 360)
                    } placeholder: {
                        placeholderView
                    }
                } else {
                    Image(coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                }
            } else {
                placeholderView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(imageGradientOverlay)
        .overlay(imageContentOverlay)
    }
    
    // 渐变遮罩
    private var imageGradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.clear,
                Color.black.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // 图片内容覆盖层
    private var imageContentOverlay: some View {
        VStack {
            // 难度标签
            HStack {
                Spacer()
                
                Text(route.difficulty.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(route.difficulty.color, in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 4)
            }
            
            Spacer()
            
            // 底部路线信息
            VStack(alignment: .leading, spacing: 12) {
                Text(route.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .multilineTextAlignment(.leading)
                
                if let description = route.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    RouteInfoBadge(icon: "location.fill", text: route.formattedDistance)
                    RouteInfoBadge(icon: "clock.fill", text: route.formattedDuration)
                    RouteInfoBadge(icon: "heart.fill", text: "\(route.likes)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
    }
    
    // 底部信息区域
    private var routeInfoView: some View {
        VStack(spacing: 18) {
            // 评分和标签
            HStack {
                // 评分
                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(route.averageRating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Text(String(format: "%.1f", route.averageRating))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 标签
                HStack(spacing: 6) {
                    ForEach(Array(route.tags.prefix(2)), id: \.rawValue) { tag in
                        Text(tag.displayName)
                            .font(.caption)
                            .foregroundColor(theme.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.color.opacity(0.1), in: Capsule())
                    }
                }
            }
            
            // 提示文本
            VStack(spacing: 6) {
                Text("👆 点击查看详情")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("👈 滑动选择路线 👉")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(24)
    }
    
    // 占位符视图
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.color.opacity(0.3),
                    theme.color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: theme.icon)
                .font(.system(size: 60))
                .foregroundColor(theme.color.opacity(0.6))
        }
        .frame(height: 300)
    }
}

struct RouteInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
    }
}

// MARK: - 底部操作栏
struct BottomActionBar: View {
    let onDislike: () -> Void
    let onLike: () -> Void
    let onDetail: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            // 不喜欢按钮
            ActionButton(
                icon: "xmark",
                color: .red,
                size: .medium,
                action: onDislike
            )
            
            // 详情按钮
            ActionButton(
                icon: "info.circle",
                color: .blue,
                size: .large,
                action: onDetail
            )
            
            // 喜欢按钮
            ActionButton(
                icon: "heart.fill",
                color: .green,
                size: .medium,
                action: onLike
            )
        }
        .padding(.vertical, 16)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let size: ButtonSize
    let action: () -> Void
    
    enum ButtonSize {
        case medium, large
        
        var frameSize: CGFloat {
            switch self {
            case .medium: return 56
            case .large: return 72
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .medium: return 20
            case .large: return 24
            }
        }
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
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
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: size.frameSize, height: size.frameSize)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 2)
                    .frame(width: size.frameSize, height: size.frameSize)
                
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 空状态视图
struct EmptyThemeView: View {
    let theme: RouteTag
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: theme.icon)
                .font(.system(size: 80))
                .foregroundColor(theme.color.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("暂无\(theme.displayName)路线")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("我们会尽快添加更多精彩路线")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 完成视图
struct CompletionView: View {
    let theme: RouteTag
    let likedRoutes: [Route]
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("探索完成！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("你喜欢了 \(likedRoutes.count) 条\(theme.displayName)路线")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !likedRoutes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("收藏的路线")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(likedRoutes.prefix(3)) { route in
                        HStack(spacing: 12) {
                            SmartImageView(
                                imageSource: route.coverImage,
                                placeholder: Image(systemName: theme.icon),
                                width: 40,
                                height: 40,
                                contentMode: .fill
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(route.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(route.formattedDistance)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
            
            VStack(spacing: 12) {
                Button("重新开始") {
                    onRestart()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.color, in: RoundedRectangle(cornerRadius: 16))
                
                Button("查看我的收藏") {
                    // TODO: 导航到收藏页面
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SwipeableRouteCardsView(theme: .architecture)
} 
