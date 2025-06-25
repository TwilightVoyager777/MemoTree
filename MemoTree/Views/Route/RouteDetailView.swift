//
//  RouteDetailView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import MapKit
import Combine

struct RouteDetailView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var isLoading = false
    @State private var isFavorited = false
    @State private var showingShareSheet = false
    @State private var showingComments = false
    @State private var showingNavigation = false
    @State private var animateContent = false
    @State private var selectedTab = 0
    @State private var isFollowing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isNavigating = false
    @State private var showingRouteNavigation = false
    @State private var mapRegion: MKCoordinateRegion
    @State private var mapUpdateTrigger = false
    
    init(route: Route) {
        self.route = route
        self._mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: route.startLatitude,
                longitude: route.startLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 顶部图片和基本信息
                    HeroImageSection(route: route)
                    
                    // 主要内容区域
                    VStack(spacing: 24) {
                        // 路线基本信息
                        RouteInfoSection(route: route, isFavorited: $isFavorited)
                        
                        // 创建者信息
                        CreatorInfoSection(route: route)
                        
                        // 标签页切换
                        TabSelectionView(selectedTab: $selectedTab)
                        
                        // 内容区域
                        TabContentView(route: route, selectedTab: selectedTab)
                        
                        // 底部间距
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .navigationBarHidden(true)
            .overlay(
                // 浮动操作栏
                FloatingActionBar(
                    route: route,
                    isFavorited: $isFavorited,
                    showingShareSheet: $showingShareSheet,
                    showingNavigation: $showingNavigation,
                    isNavigating: $isNavigating,
                    showingRouteNavigation: $showingRouteNavigation,
                    onDismiss: { dismiss() },
                    onStartNavigation: { startNavigation() }
                ),
                alignment: .bottom
            )
        }
        .sheet(isPresented: $showingComments) {
            RouteCommentsView(route: route)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetView(route: route)
        }
        .sheet(isPresented: $showingNavigation) {
            RouteNavigationView(route: route)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animateContent = true
            }
            // 检查是否已收藏
            isFavorited = authService.isRouteFavorited(route.id)
        }
        .alert("导航提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .actionSheet(isPresented: $showingRouteNavigation) {
            ActionSheet(
                title: Text("导航选项"),
                message: Text("选择导航方式"),
                buttons: [
                    .default(Text("导航到起点")) {
                        startNavigation()
                    },
                    .default(Text("查看完整路线")) {
                        showFullRouteNavigation()
                    },
                    .default(Text("逐景点导航")) {
                        startStepByStepNavigation()
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
    
    private func loadRouteDetails() {
        isFavorited = authService.isRouteFavorited(route.id)
    }
    
    // MARK: - 导航功能
    
    private func startNavigation() {
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        guard let firstPoint = route.routePoints?.first(where: { $0.pointType == .start }) ??
              route.routePoints?.first else {
            // 如果没有路线点，使用路线起点坐标
            navigateToCoordinate(
                latitude: route.startLatitude,
                longitude: route.startLongitude,
                name: route.startAddress ?? "路线起点",
                mode: getRecommendedNavigationMode()
            )
            return
        }
        
        // 导航到第一个点位
        navigateToCoordinate(
            latitude: firstPoint.latitude,
            longitude: firstPoint.longitude,
            name: firstPoint.name ?? "路线起点",
            mode: getRecommendedNavigationMode()
        )
    }
    
    private func getRecommendedNavigationMode() -> String {
        // 根据路线标签推荐导航模式
        if route.tags.contains(.cycling) {
            return MKLaunchOptionsDirectionsModeDefault // 默认模式，可以选择
        } else if route.distance < 2.0 {
            return MKLaunchOptionsDirectionsModeWalking // 短距离推荐步行
        } else {
            return MKLaunchOptionsDirectionsModeDriving // 长距离推荐开车
        }
    }
    
    private func navigateToCoordinate(latitude: Double, longitude: Double, name: String, mode: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        
        // 设置启动选项
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: mode,
            MKLaunchOptionsShowsTrafficKey: true
        ] as [String : Any]
        
        // 在苹果地图中打开导航
        mapItem.openInMaps(launchOptions: launchOptions)
        
        // 显示成功消息
        let modeText = getModeDisplayName(mode)
        alertMessage = "正在启动苹果地图 (\(modeText)) 导航到 \(name)..."
        showingAlert = true
        
        // 记录导航开始
        isNavigating = true
        
        // 3秒后重置导航状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isNavigating = false
        }
    }
    
    private func getModeDisplayName(_ mode: String) -> String {
        switch mode {
        case MKLaunchOptionsDirectionsModeWalking:
            return "步行"
        case MKLaunchOptionsDirectionsModeDriving:
            return "驾车"
        case MKLaunchOptionsDirectionsModeTransit:
            return "公交"
        default:
            return "默认"
        }
    }
    
    private func showFullRouteNavigation() {
        // 显示包含所有路线点的完整导航
        guard let routePoints = route.routePoints, !routePoints.isEmpty else {
            alertMessage = "该路线暂无详细路径信息"
            showingAlert = true
            return
        }
        
        // 创建包含所有景点的地图项目数组
        let mapItems = routePoints.compactMap { point -> MKMapItem? in
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = point.name ?? point.pointType.displayName
            return mapItem
        }
        
        // 设置启动选项
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: getRecommendedNavigationMode(),
            MKLaunchOptionsShowsTrafficKey: true
        ] as [String : Any]
        
        // 在苹果地图中打开完整路线
        MKMapItem.openMaps(with: mapItems, launchOptions: launchOptions)
        
        alertMessage = "正在启动苹果地图显示完整路线..."
        showingAlert = true
    }
    
    private func startStepByStepNavigation() {
        // 逐个景点导航
        guard let routePoints = route.routePoints, !routePoints.isEmpty else {
            alertMessage = "该路线暂无详细路径信息"
            showingAlert = true
            return
        }
        
        // 导航到第一个景点，并提示用户可以逐个导航
        let firstPoint = routePoints.first!
        navigateToCoordinate(
            latitude: firstPoint.latitude,
            longitude: firstPoint.longitude,
            name: firstPoint.name ?? "第一个景点",
            mode: getRecommendedNavigationMode()
        )
        
        alertMessage = "已导航到第一个景点。到达后可在苹果地图中搜索下一个景点: \(routePoints.count > 1 ? (routePoints[1].name ?? "下一个景点") : "终点")"
        showingAlert = true
    }
    
    private func jumpToLocation(_ coordinate: CLLocationCoordinate2D) {
        // 先更新地图区域（不带动画）
        mapRegion.center = coordinate
        mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        // 触发地图更新
        mapUpdateTrigger.toggle()
        
        // 然后添加平滑动画
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion.center = coordinate
        }
        
        // 添加触觉反馈和调试信息
    }
    
    // MARK: - 操作方法
}

// MARK: - 顶部图片区域
struct HeroImageSection: View {
    let route: Route
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let height: CGFloat = 300
            
            Group {
                if let coverImage = route.coverImage, !coverImage.isEmpty {
                    if coverImage.hasPrefix("http") {
                        // 网络图片
                        AsyncImage(url: URL(string: coverImage)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: height + (offset > 0 ? offset : 0))
                                .offset(y: offset > 0 ? -offset : 0)
                        } placeholder: {
                            placeholderView
                        }
                    } else {
                        // 本地图片
                        Image(coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: height + (offset > 0 ? offset : 0))
                            .offset(y: offset > 0 ? -offset : 0)
                    }
                } else {
                    placeholderView
                }
            }
            .overlay(
                // 渐变遮罩
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                // 路线基本信息覆盖层
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(route.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            HStack(spacing: 16) {
                                RouteStatsBadge(icon: "location.fill", text: route.formattedDistance)
                                RouteStatsBadge(icon: "clock.fill", text: route.formattedDuration)
                                RouteStatsBadge(icon: "heart.fill", text: "\(route.likes)")
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            )
        }
        .frame(height: 300)
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.4),
                    Color.blue.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "map.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct RouteStatsBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 路线信息区域
struct RouteInfoSection: View {
    let route: Route
    @Binding var isFavorited: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 难度和标签
            HStack {
                DifficultyBadge(difficulty: route.difficulty)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(Array(route.tags.prefix(3)), id: \.rawValue) { tag in
                        TagBadge(tag: tag)
                    }
                    if route.tags.count > 3 {
                        Text("+\(route.tags.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 描述
            Text(route.description ?? "暂无描述")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
            
            // 统计数据
            RouteStatsGrid(route: route)
        }
        .padding(.horizontal, 4)
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(difficulty.color, in: Capsule())
            .shadow(color: difficulty.color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct TagBadge: View {
    let tag: RouteTag
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.icon)
                .font(.caption2)
            Text(tag.displayName)
                .font(.caption)
        }
        .foregroundColor(.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.green.opacity(0.1), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RouteStatsGrid: View {
    let route: Route
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            StatItem(icon: "eye.fill", value: "\(route.views)", label: "浏览", color: .blue)
            StatItem(icon: "heart.fill", value: "\(route.likes)", label: "点赞", color: .pink)
            StatItem(icon: "bookmark.fill", value: "\(route.collections)", label: "收藏", color: .orange)
            StatItem(icon: "flag.checkered", value: "\(route.completions)", label: "完成", color: .green)
        }
        .padding(.horizontal, 8)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 创建者信息区域
struct CreatorInfoSection: View {
    let route: Route
    
    var body: some View {
        HStack(spacing: 16) {
            // 创建者头像
            UserAvatarView(
                avatarSource: route.creator?.avatar,
                size: 50
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(route.creator?.nickname ?? "未知用户")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("创建于 \(formatDate(route.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    if let creator = route.creator {
                        Label("\(creator.completedRoutes)", systemImage: "figure.walk")
                        Label("\(creator.totalLikes)", systemImage: "heart")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 关注按钮
            Button(action: {
                // TODO: 关注功能
            }) {
                Text("关注")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.green, in: Capsule())
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM月dd日"
            return displayFormatter.string(from: date)
        }
        
        return "未知"
    }
}

// MARK: - 标签页选择
struct TabSelectionView: View {
    @Binding var selectedTab: Int
    
    let tabs = ["路线", "地图", "评论"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? .green : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? .green : .clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - 标签页内容
struct TabContentView: View {
    let route: Route
    let selectedTab: Int
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                RoutePointsView(route: route)
            case 1:
                RouteMapView(route: route)
            case 2:
                RouteCommentsPreview(route: route)
            default:
                RoutePointsView(route: route)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
}

// MARK: - 路线点位视图
struct RoutePointsView: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let routePoints = route.routePoints, !routePoints.isEmpty {
                ForEach(Array(routePoints.enumerated()), id: \.element.id) { index, point in
                    RoutePointCard(point: point, index: index)
                }
            } else {
                EmptyStateView(
                    icon: "location.slash",
                    title: "暂无路线点位",
                    message: "这条路线还没有详细的点位信息"
                )
            }
        }
    }
}

struct RoutePointCard: View {
    let point: RoutePoint
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // 点位图标
            ZStack {
                Circle()
                    .fill(pointColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: point.pointType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(pointColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(point.name ?? "位置点 \(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let description = point.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(point.pointType.displayName)
                    .font(.caption)
                    .foregroundColor(pointColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(pointColor.opacity(0.1), in: Capsule())
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var pointColor: Color {
        switch point.pointType {
        case .start: return .green
        case .end: return .red
        case .viewpoint: return .blue
        case .food: return .orange
        case .photo: return .purple
        default: return .gray
        }
    }
}

// MARK: - 路线地图视图
struct RouteMapView: View {
    let route: Route
    @State private var mapRegion: MKCoordinateRegion
    
    init(route: Route) {
        self.route = route
        self._mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: route.startLatitude,
                longitude: route.startLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 地图
            Map(coordinateRegion: $mapRegion, annotationItems: route.routePoints ?? []) { point in
                MapAnnotation(coordinate: point.coordinate) {
                    MapPointAnnotation(point: point)
                }
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.primary.opacity(0.1), lineWidth: 1)
            )
            
            // 地图操作按钮
            HStack(spacing: 16) {
                MapActionButton(icon: "location.fill", text: "定位起点") {
                    centerOnStart()
                }
                
                MapActionButton(icon: "map.fill", text: "查看全程") {
                    showFullRoute()
                }
                
                MapActionButton(icon: "arrow.triangle.turn.up.right.diamond", text: "导航") {
                    // TODO: 打开导航
                }
            }
        }
    }
    
    private func centerOnStart() {
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion.center = CLLocationCoordinate2D(
                latitude: route.startLatitude,
                longitude: route.startLongitude
            )
        }
    }
    
    private func showFullRoute() {
        // TODO: 计算包含所有点位的地图区域
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }
}

struct MapPointAnnotation: View {
    let point: RoutePoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            Circle()
                .fill(pointColor)
                .frame(width: 16, height: 16)
        }
    }
    
    private var pointColor: Color {
        switch point.pointType {
        case .start: return .green
        case .end: return .red
        case .viewpoint: return .blue
        case .food: return .orange
        case .photo: return .purple
        default: return .gray
        }
    }
}

struct MapActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(text)
                    .font(.caption)
            }
            .foregroundColor(.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 评论预览视图
struct RouteCommentsPreview: View {
    let route: Route
    
    // 模拟评论数据
    private let mockComments = [
        RouteComment(
            id: 1,
            userId: 2,
            userName: "镜头下的城市",
            userAvatar: "user_avatar_1",
            content: "这条路线的摄影点位标记得很准确，特别是外滩观景台的角度建议非常棒！推荐日落时分前往。",
            rating: 5,
            createdAt: "2024-01-01T19:30:00Z",
            images: ["community_1"]
        ),
        RouteComment(
            id: 2,
            userId: 3,
            userName: "小食光",
            userAvatar: "user_avatar_2",
            content: "路线很棒，不过建议在南翔小笼包店附近增加一些其他美食推荐，这样体验会更丰富。",
            rating: 4,
            createdAt: "2024-01-01T15:20:00Z",
            images: []
        ),
        RouteComment(
            id: 3,
            userId: 4,
            userName: "老上海故事",
            userAvatar: "user_avatar_3",
            content: "非常有历史文化价值的路线，每个点位的历史背景介绍都很详细。建议慢慢走，细细品味。",
            rating: 5,
            createdAt: "2024-01-01T11:45:00Z",
            images: []
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 评分概览
            RatingOverview(route: route)
            
            // 评论列表
            VStack(spacing: 12) {
                ForEach(mockComments.prefix(3)) { comment in
                    RouteCommentCard(comment: comment)
                }
            }
            
            // 查看更多按钮
            Button(action: {
                // TODO: 显示完整评论页面
            }) {
                HStack {
                    Text("查看全部 \(route.ratingCount) 条评论")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.green)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

struct RatingOverview: View {
    let route: Route
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", route.averageRating))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < Int(route.averageRating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text("\(route.ratingCount) 条评价")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("写评价") {
                    // TODO: 打开评价界面
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.green, in: Capsule())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RouteCommentCard: View {
    let comment: RouteComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息和评分
            HStack(spacing: 12) {
                UserAvatarView(
                    avatarSource: comment.userAvatar,
                    size: 32
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < comment.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption2)
                        }
                        
                        Text(formatDate(comment.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 评论内容
            Text(comment.content)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            // 评论图片
            if !comment.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(comment.images, id: \.self) { imageUrl in
                            SmartImageView(
                                imageSource: imageUrl,
                                placeholder: Image(systemName: "photo"),
                                width: 60,
                                height: 60,
                                contentMode: .fill
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            if timeInterval < 3600 { // 1小时内
                let minutes = Int(timeInterval / 60)
                return "\(minutes)分钟前"
            } else if timeInterval < 86400 { // 24小时内
                let hours = Int(timeInterval / 3600)
                return "\(hours)小时前"
            } else {
                let days = Int(timeInterval / 86400)
                return "\(days)天前"
            }
        }
        
        return "未知时间"
    }
}

// MARK: - 浮动操作栏
struct FloatingActionBar: View {
    let route: Route
    @Binding var isFavorited: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingNavigation: Bool
    @Binding var isNavigating: Bool
    @Binding var showingRouteNavigation: Bool
    let onDismiss: () -> Void
    let onStartNavigation: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                // 返回按钮
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.6), in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
                
                // 收藏按钮
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isFavorited.toggle()
                    }
                    // TODO: 调用收藏API
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFavorited ? .white : .pink)
                        .frame(width: 44, height: 44)
                        .background(isFavorited ? .pink : .white, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                // 分享按钮
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                // 开始导航按钮
                Button(action: onStartNavigation) {
                    HStack(spacing: 8) {
                        if isNavigating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(isNavigating ? "启动中..." : "开始探索")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.green, in: Capsule())
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isNavigating)
                .onLongPressGesture {
                    // 长按显示导航选项
                    showingRouteNavigation = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area bottom
        }
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 数据模型
struct RouteComment: Identifiable, Codable {
    let id: Int64
    let userId: Int64
    let userName: String
    let userAvatar: String
    let content: String
    let rating: Int
    let createdAt: String
    let images: [String]
}

// MARK: - 辅助视图（占位符）
struct RouteCommentsView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("完整评论页面")
                .navigationTitle("评论")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") { dismiss() }
                    }
                }
        }
    }
}

struct ShareSheetView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("分享页面")
                .navigationTitle("分享路线")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") { dismiss() }
                    }
                }
        }
    }
}

struct RouteNavigationView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("导航页面")
                .navigationTitle("路线导航")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") { dismiss() }
                    }
                }
        }
    }
} 
 