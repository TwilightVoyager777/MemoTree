//
//  MapView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = MemoTree.LocationManager()
    @StateObject private var routeService = RouteService.shared
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551), // 杭州西湖
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route?
    @State private var showingFilters = false
    @State private var animateControls = false
    @State private var showingSearchSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 地图背景
                Map(coordinateRegion: $mapRegion, 
                    interactionModes: [.all],
                    showsUserLocation: true,
                    userTrackingMode: .none,
                    annotationItems: routeService.nearbyRoutes) { route in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: route.startLatitude,
                        longitude: route.startLongitude
                    )) {
                        AnimatedRoutePin(route: route) {
                            selectedRoute = route
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showingRouteDetail = true
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                // 控制按钮组
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // 搜索按钮
                            FloatingActionButton(
                                icon: "magnifyingglass",
                                color: .blue,
                                animationDelay: 0.1
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showingSearchSheet = true
                                }
                            }
                            
                            // 筛选按钮
                            FloatingActionButton(
                                icon: "slider.horizontal.3",
                                color: .purple,
                                animationDelay: 0.2
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showingFilters = true
                                }
                            }
                            
                            // 定位按钮
                            FloatingActionButton(
                                icon: "location.fill",
                                color: .green,
                                animationDelay: 0.3
                            ) {
                                centerOnUserLocation()
                            }
                            
                            // 刷新按钮
                            FloatingActionButton(
                                icon: "arrow.clockwise",
                                color: .orange,
                                animationDelay: 0.4
                            ) {
                                refreshNearbyRoutes()
                            }
                        }
                        .opacity(animateControls ? 1 : 0)
                        .offset(x: animateControls ? 0 : 50)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateControls)
                    }
                    .padding(.trailing, 20)
                    
                    Spacer()
                    
                    // 底部快速信息卡片
                    if !routeService.nearbyRoutes.isEmpty {
                        QuickInfoCard()
                            .opacity(animateControls ? 1 : 0)
                            .offset(y: animateControls ? 0 : 100)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateControls)
                    }
                }
                .padding(.bottom, 34) // Safe area bottom
                
                // 顶部状态栏
                VStack {
                    MapStatusBar()
                        .opacity(animateControls ? 1 : 0)
                        .offset(y: animateControls ? 0 : -50)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateControls)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRouteDetail) {
            if let route = selectedRoute {
                RouteDetailView(route: route)
            }
        }
        .sheet(isPresented: $showingFilters) {
            MapFiltersView()
        }
        .sheet(isPresented: $showingSearchSheet) {
            MapSearchView(searchText: $searchText)
        }
        .onAppear {
            loadNearbyRoutes()
            withAnimation {
                animateControls = true
            }
        }
        .onChange(of: locationManager.currentLocation) { _ in
            if let location = locationManager.currentLocation {
                updateMapRegion(for: location.coordinate)
            }
        }
    }
    
    // MARK: - 方法
    private func centerOnUserLocation() {
        guard let location = locationManager.currentLocation else { return }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            mapRegion.center = location.coordinate
        }
    }
    
    private func updateMapRegion(for coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion.center = coordinate
        }
    }
    
    private func loadNearbyRoutes() {
        guard let location = locationManager.currentLocation else { return }
        
        routeService.fetchNearbyRoutes(
            location: location.coordinate,
            radius: 5000
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &routeService.cancellables)
    }
    
    private func refreshNearbyRoutes() {
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        loadNearbyRoutes()
    }
}

// MARK: - 动画路线标记
struct AnimatedRoutePin: View {
    let route: Route
    let action: () -> Void
    @State private var scale: CGFloat = 0.8
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
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
                // 外圈动画
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scale)
                
                // 内圈
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // 路线图标
                Image(systemName: getDifficultyIcon(route.difficulty))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            scale = 1.2
        }
    }
    
    private func getDifficultyIcon(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        case .expert: return "star.fill"
        }
    }
}

// MARK: - 浮动操作按钮
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let animationDelay: Double
    let action: () -> Void
    
    @State private var animate = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
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
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .scaleEffect(animate ? 1.0 : 0.8)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                animate = true
            }
        }
    }
}

// MARK: - 地图状态栏
struct MapStatusBar: View {
    @StateObject private var routeService = RouteService.shared
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("附近 \(routeService.nearbyRoutes.count) 条路线")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 60) // Status bar + navigation bar height
    }
}

// MARK: - 快速信息卡片
struct QuickInfoCard: View {
    @StateObject private var routeService = RouteService.shared
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        if !routeService.nearbyRoutes.isEmpty {
            TabView(selection: $currentIndex) {
                ForEach(Array(routeService.nearbyRoutes.prefix(5).enumerated()), id: \.element.id) { index, route in
                    QuickRouteCard(route: route)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 120)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 20)
            .onAppear {
                startAutoSlide()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startAutoSlide() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % min(routeService.nearbyRoutes.count, 5)
            }
        }
    }
}

struct QuickRouteCard: View {
    let route: Route
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: RouteDetailView(route: route)) {
            HStack(spacing: 16) {
                // 路线缩略图
                SmartImageView(
                    imageSource: route.coverImage,
                    placeholder: Image(systemName: "map.fill"),
                    width: 60,
                    height: 60,
                    contentMode: .fill
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // 路线信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(route.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
                
                VStack {
                    Text(route.difficulty.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(route.difficulty.color, in: Capsule())
                    
                    Spacer()
                    
                    // 添加右箭头指示器
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .scaleEffect(isPressed ? 0.98 : 1.0)
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
    }
}

// MARK: - 路线详情页面占位符（已废弃，使用独立的RouteDetailView）
// 这个简单版本已被独立的RouteDetailView.swift文件替代

// MARK: - 地图筛选页面占位符
struct MapFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("筛选条件")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("按难度、类型、距离筛选路线")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("重置") {
                        // TODO: 重置筛选条件
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

// MARK: - 地图搜索页面
struct MapSearchView: View {
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索地点、景点或地址", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            searchPlaces()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // 搜索结果列表
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("搜索中...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("未找到相关地点")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("请尝试其他关键词")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { mapItem in
                        SearchResultRow(mapItem: mapItem) {
                            // 选择地点后的操作
                            dismiss()
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    // 默认推荐搜索
                    VStack(spacing: 24) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("搜索杭州地点")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("输入景点、地址或关键词进行搜索")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // 热门搜索建议
                        VStack(alignment: .leading, spacing: 12) {
                            Text("热门搜索")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(["西湖", "雷峰塔", "灵隐寺", "千岛湖", "钱塘江", "宋城"], id: \.self) { suggestion in
                                    Button(action: {
                                        searchText = suggestion
                                        searchPlaces()
                                    }) {
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(.blue.opacity(0.1), in: Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("搜索地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func searchPlaces() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        // 限制搜索区域为杭州附近
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.mapItems
                } else {
                    searchResults = []
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let mapItem: MKMapItem
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 地点类型图标
                Image(systemName: getPlaceTypeIcon())
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(.blue.opacity(0.1), in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "未知地点")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let address = mapItem.placemark.thoroughfare {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let category = mapItem.pointOfInterestCategory {
                        Text(getReadableCategory(category))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1), in: Capsule())
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getPlaceTypeIcon() -> String {
        guard let category = mapItem.pointOfInterestCategory else { return "mappin" }
        
        switch category {
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double"
        case .gasStation: return "fuelpump"
        case .hospital: return "cross"
        case .school: return "graduationcap"
        case .store: return "storefront"
        case .museum: return "building.columns"
        case .park: return "tree"
        case .beach: return "beach.umbrella"
        default: return "mappin"
        }
    }
    
    private func getReadableCategory(_ category: MKPointOfInterestCategory) -> String {
        switch category {
        case .restaurant: return "餐厅"
        case .hotel: return "酒店"
        case .gasStation: return "加油站"
        case .hospital: return "医院"
        case .school: return "学校"
        case .store: return "商店"
        case .museum: return "博物馆"
        case .park: return "公园"
        case .beach: return "海滩"
        default: return "地点"
        }
    }
}

#Preview {
    MapView()
} 
 