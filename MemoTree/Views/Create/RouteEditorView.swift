//
//  RouteEditorView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import MapKit
import CoreLocation

struct RouteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = MemoTree.LocationManager()
    @StateObject private var routeService = RouteService.shared
    @StateObject private var authService = AuthService.shared
    
    // 地图状态
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551), // 杭州西湖
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // 路线数据
    @State private var routeName = ""
    @State private var routeDescription = ""
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var selectedTags: Set<RouteTag> = []
    @State private var routePoints: [EditableRoutePoint] = []
    @State private var isPublic = true
    @State private var estimatedDuration = 60
    
    // UI状态
    @State private var currentStep = 0
    @State private var isAddingPoint = false
    @State private var selectedPointIndex: Int?
    @State private var showingPointEditor = false
    @State private var showingPreview = false
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var mapFrame: CGRect = .zero
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingSearchResults = false
    @State private var mapUpdateTrigger = false
    
    let steps = ["地图编辑", "路线信息", "预览发布"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主要内容区域
                TabView(selection: $currentStep) {
                    // 步骤1: 地图编辑
                    MapEditingView(
                        mapRegion: $mapRegion,
                        routePoints: $routePoints,
                        isAddingPoint: $isAddingPoint,
                        selectedPointIndex: $selectedPointIndex,
                        showingPointEditor: $showingPointEditor
                    )
                    .tag(0)
                    
                    // 步骤2: 路线信息
                    RouteInfoEditingView(
                        routeName: $routeName,
                        routeDescription: $routeDescription,
                        selectedDifficulty: $selectedDifficulty,
                        selectedTags: $selectedTags,
                        estimatedDuration: $estimatedDuration,
                        isPublic: $isPublic
                    )
                    .tag(1)
                    
                    // 步骤3: 预览发布
                    RoutePreviewView(
                        routeName: routeName,
                        routeDescription: routeDescription,
                        difficulty: selectedDifficulty,
                        tags: Array(selectedTags),
                        routePoints: routePoints,
                        estimatedDuration: estimatedDuration,
                        isPublic: isPublic
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 顶部导航栏
                VStack {
                    RouteEditorNavigationBar(
                        currentStep: currentStep,
                        steps: steps,
                        onDismiss: { dismiss() },
                        onNext: handleNextStep,
                        onPrevious: handlePreviousStep,
                        canGoNext: canGoToNextStep,
                        isCreating: isCreating
                    )
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPointEditor) {
            if let index = selectedPointIndex {
                RoutePointEditorView(
                    point: $routePoints[index],
                    onSave: {
                        showingPointEditor = false
                        selectedPointIndex = nil
                    },
                    onDelete: {
                        routePoints.remove(at: index)
                        showingPointEditor = false
                        selectedPointIndex = nil
                    }
                )
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            centerOnUserLocation()
        }
    }
    
    // MARK: - 方法
    
    private func centerOnUserLocation() {
        // TODO: 实现定位到当前位置
        // 这里可以集成LocationManager来获取用户位置
        // 暂时使用默认的杭州西湖位置
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion.center = CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551)
        }
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
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 调试信息
        print("📍 跳转到位置: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    private func handleNextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            createRoute()
        }
    }
    
    private func handlePreviousStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep -= 1
            }
        }
    }
    
    private var canGoToNextStep: Bool {
        switch currentStep {
        case 0: return routePoints.count >= 2 // 至少需要起点和终点
        case 1: return !routeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return true
        default: return false
        }
    }
    
    private func createRoute() {
        guard let currentUser = authService.currentUser else {
            alertMessage = "请先登录"
            showingAlert = true
            return
        }
        
        isCreating = true
        
        // 计算总距离
        let totalDistance = calculateTotalDistance()
        
        // 将EditableRoutePoint转换为RoutePoint
        let convertedPoints = routePoints.enumerated().map { index, point in
            RoutePoint(
                id: Int64(index + 1),
                latitude: point.coordinate.latitude,
                longitude: point.coordinate.longitude,
                name: point.name,
                description: point.description,
                imageUrl: nil,
                pointType: point.pointType,
                order: index
            )
        }
        
        // 创建路线请求
        let createRequest = CreateRouteRequest(
            name: routeName,
            description: routeDescription,
            difficulty: selectedDifficulty,
            distance: totalDistance,
            estimatedDuration: estimatedDuration,
            startLatitude: routePoints.first?.coordinate.latitude ?? 0,
            startLongitude: routePoints.first?.coordinate.longitude ?? 0,
            endLatitude: routePoints.last?.coordinate.latitude ?? 0,
            endLongitude: routePoints.last?.coordinate.longitude ?? 0,
            waypoints: convertedPoints,
            tags: selectedTags.map { $0.rawValue },
            isPublic: isPublic,
            coverImage: nil,
            creatorId: currentUser.id,
            creatorName: currentUser.nickname ?? currentUser.username,
            startLocation: routePoints.first?.name ?? "起点",
            endLocation: routePoints.last?.name ?? "终点"
        )
        
        // 调用创建服务
        routeService.createRoute(createRequest)
            .sink(
                receiveCompletion: { completion in
                    isCreating = false
                    switch completion {
                    case .failure(let error):
                        alertMessage = "创建路线失败：\(error.localizedDescription)"
                        showingAlert = true
                    case .finished:
                        break
                    }
                },
                receiveValue: { route in
                    alertMessage = "路线创建成功！"
                    showingAlert = true
                    
                    // 延迟关闭页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            )
            .store(in: &routeService.cancellables)
    }
    
    private func calculateTotalDistance() -> Double {
        guard routePoints.count >= 2 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 0..<routePoints.count - 1 {
            let point1 = routePoints[i].coordinate
            let point2 = routePoints[i + 1].coordinate
            
            let location1 = CLLocation(latitude: point1.latitude, longitude: point1.longitude)
            let location2 = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
            
            totalDistance += location1.distance(from: location2)
        }
        
        return totalDistance / 1000.0 // 转换为公里
    }
}

// MARK: - 可编辑的路线点模型
struct EditableRoutePoint: Identifiable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var name: String
    var description: String
    var pointType: PointType
    
    init(coordinate: CLLocationCoordinate2D, name: String = "", description: String = "", pointType: PointType = .waypoint) {
        self.coordinate = coordinate
        self.name = name
        self.description = description
        self.pointType = pointType
    }
    
    // 实现Equatable协议
    static func == (lhs: EditableRoutePoint, rhs: EditableRoutePoint) -> Bool {
        return lhs.id == rhs.id &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.name == rhs.name &&
               lhs.description == rhs.description &&
               lhs.pointType == rhs.pointType
    }
}

// MARK: - 地图编辑视图
struct MapEditingView: View {
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var routePoints: [EditableRoutePoint]
    @Binding var isAddingPoint: Bool
    @Binding var selectedPointIndex: Int?
    @Binding var showingPointEditor: Bool
    
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var mapFrame: CGRect = .zero
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingSearchResults = false
    @State private var mapUpdateTrigger = false
    
    var body: some View {
        ZStack {
            // 地图
            Map(coordinateRegion: $mapRegion, annotationItems: mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    if annotation.isTemporary {
                        // 临时选中位置标记（可拖拽）
                        DraggableSelectedLocationMarker(
                            coordinate: annotation.coordinate,
                            onDragChanged: { newCoordinate in
                                selectedLocation = newCoordinate
                            }
                        )
                    } else {
                        // 已添加的路线点位
                        RoutePointAnnotation(
                            point: annotation.routePoint!,
                            index: routePoints.firstIndex(where: { $0.id == annotation.routePoint!.id }) ?? 0,
                            isSelected: selectedPointIndex == routePoints.firstIndex(where: { $0.id == annotation.routePoint!.id })
                        ) {
                            selectedPointIndex = routePoints.firstIndex(where: { $0.id == annotation.routePoint!.id })
                            showingPointEditor = true
                        }
                    }
                }
            }
            .id(mapUpdateTrigger)
            .ignoresSafeArea(edges: .bottom)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            mapFrame = geometry.frame(in: .local)
                        }
                        .onChange(of: geometry.frame(in: .local)) { newFrame in
                            mapFrame = newFrame
                        }
                }
            )
            .onTapGesture { location in
                // 将屏幕坐标转换为地图坐标
                selectLocationAt(screenPoint: location)
            }
            
            // 搜索框
            VStack {
                LocationSearchBar(
                    searchText: $searchText,
                    searchResults: $searchResults,
                    isSearching: $isSearching,
                    showingSearchResults: $showingSearchResults,
                    onLocationSelected: { location in
                        // 立即跳转到选中的位置
                        jumpToLocation(location.placemark.coordinate)
                        
                        // 延迟清除搜索状态，确保地图更新完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingSearchResults = false
                            searchText = ""
                            searchResults = []
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 200) // 为顶部导航预留空间
                
                Spacer()
            }
            
            // 路线连线（简化版本，实际应该使用MKPolyline）
            if routePoints.count >= 2 {
                RoutePathOverlay(points: routePoints)
            }
            
            // 控制按钮
            VStack {
                Spacer()
                
                HStack {
                    // 添加点位按钮
                    FloatingControlButton(
                        icon: selectedLocation != nil ? "plus.circle.fill" : "plus",
                        color: selectedLocation != nil ? .green : .blue,
                        action: {
                            if let location = selectedLocation {
                                addPointAtLocation(location)
                            }
                        }
                    )
                    .disabled(selectedLocation == nil)
                    .opacity(selectedLocation != nil ? 1.0 : 0.6)
                    
                    Spacer()
                    
                    // 定位按钮
                    FloatingControlButton(
                        icon: "location.fill",
                        color: .green,
                        action: {
                            centerOnUserLocation()
                        }
                    )
                    
                    // 清除所有点位按钮
                    if !routePoints.isEmpty {
                        FloatingControlButton(
                            icon: "trash",
                            color: .red,
                            action: {
                                routePoints.removeAll()
                                selectedPointIndex = nil
                                selectedLocation = nil
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // 为底部导航预留空间
            }
            
            // 顶部信息栏
            VStack {
                MapInfoBar(
                    pointsCount: routePoints.count,
                    isAddingPoint: selectedLocation != nil,
                    selectedLocation: selectedLocation
                )
                Spacer()
            }
        }
    }
    
    // 计算地图标注项
    private var mapAnnotations: [MapAnnotationItem] {
        var annotations = routePoints.map { point in
            MapAnnotationItem(coordinate: point.coordinate, routePoint: point, isTemporary: false)
        }
        
        // 添加临时选中位置
        if let location = selectedLocation {
            annotations.append(MapAnnotationItem(coordinate: location, routePoint: nil, isTemporary: true))
        }
        
        return annotations
    }
    
    private func selectLocationAt(screenPoint: CGPoint) {
        // 改进的坐标转换逻辑
        let coordinate = screenPointToMapCoordinate(screenPoint)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedLocation = coordinate
        }
    }
    
    private func screenPointToMapCoordinate(_ screenPoint: CGPoint) -> CLLocationCoordinate2D {
        // 计算屏幕点在地图区域中的相对位置
        let relativeX = screenPoint.x / mapFrame.width
        let relativeY = screenPoint.y / mapFrame.height
        
        // 考虑地图的span和center计算实际坐标
        let longitudeDelta = mapRegion.span.longitudeDelta
        let latitudeDelta = mapRegion.span.latitudeDelta
        
        // 从左上角(0,0)到右下角(1,1)的映射
        let longitude = mapRegion.center.longitude - longitudeDelta / 2 + relativeX * longitudeDelta
        let latitude = mapRegion.center.latitude + latitudeDelta / 2 - relativeY * latitudeDelta
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private func addPointAtLocation(_ coordinate: CLLocationCoordinate2D) {
        let pointType: PointType
        if routePoints.isEmpty {
            pointType = .start
        } else {
            pointType = .waypoint
        }
        
        let newPoint = EditableRoutePoint(
            coordinate: coordinate,
            name: pointType == .start ? "起点" : "点位 \(routePoints.count + 1)",
            description: "",
            pointType: pointType
        )
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            routePoints.append(newPoint)
            
            // 如果添加了第二个点，设置为终点
            if routePoints.count == 2 {
                routePoints[1].pointType = .end
                routePoints[1].name = "终点"
            } else if routePoints.count > 2 {
                // 更新最后一个点为终点
                for i in 1..<routePoints.count-1 {
                    routePoints[i].pointType = .waypoint
                    if routePoints[i].name == "终点" {
                        routePoints[i].name = "点位 \(i + 1)"
                    }
                }
                routePoints[routePoints.count-1].pointType = .end
                routePoints[routePoints.count-1].name = "终点"
            }
            
            // 清除选中位置
            selectedLocation = nil
        }
    }
    
    private func centerOnUserLocation() {
        // TODO: 实现定位到当前位置
        // 这里可以集成LocationManager来获取用户位置
        // 暂时使用默认的杭州西湖位置
        withAnimation(.easeInOut(duration: 1.0)) {
            mapRegion.center = CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551)
        }
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
        
        // 添加触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 调试信息
        print("📍 跳转到位置: \(coordinate.latitude), \(coordinate.longitude)")
    }
}

// MARK: - 可拖拽的选中位置标记
struct DraggableSelectedLocationMarker: View {
    let coordinate: CLLocationCoordinate2D
    let onDragChanged: (CLLocationCoordinate2D) -> Void
    
    @State private var pulseAnimation = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // 外圈脉冲效果
            Circle()
                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                .frame(width: isDragging ? 60 : 50, height: isDragging ? 60 : 50)
                .scaleEffect(pulseAnimation && !isDragging ? 1.4 : 1.0)
                .opacity(pulseAnimation && !isDragging ? 0.3 : 0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            
            // 内圈
            Circle()
                .fill(Color.blue.opacity(isDragging ? 0.4 : 0.3))
                .frame(width: isDragging ? 35 : 30, height: isDragging ? 35 : 30)
            
            // 中心点
            Circle()
                .fill(Color.blue)
                .frame(width: isDragging ? 20 : 16, height: isDragging ? 20 : 16)
                .overlay(
                    Image(systemName: isDragging ? "hand.raised.fill" : "plus")
                        .font(.system(size: isDragging ? 10 : 8, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.3), radius: isDragging ? 6 : 4, x: 0, y: 2)
        }
        .offset(dragOffset)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        withAnimation(.easeIn(duration: 0.2)) {
                            isDragging = true
                        }
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isDragging = false
                        dragOffset = .zero
                    }
                    
                    // 计算新的坐标位置
                    // 这里需要将拖拽的偏移量转换为地图坐标偏移量
                    let newCoordinate = calculateNewCoordinate(from: coordinate, dragOffset: value.translation)
                    onDragChanged(newCoordinate)
                }
        )
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func calculateNewCoordinate(from original: CLLocationCoordinate2D, dragOffset: CGSize) -> CLLocationCoordinate2D {
        // 简化计算：将像素偏移转换为经纬度偏移
        // 这个比例需要根据当前地图的缩放级别和屏幕尺寸来调整
        let latitudeOffset = -dragOffset.height * 0.0001 // Y轴向上为正，纬度增加
        let longitudeOffset = dragOffset.width * 0.0001
        
        return CLLocationCoordinate2D(
            latitude: original.latitude + latitudeOffset,
            longitude: original.longitude + longitudeOffset
        )
    }
}

// MARK: - 地图标注项模型
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let routePoint: EditableRoutePoint?
    let isTemporary: Bool
}

// MARK: - 路线点标注
struct RoutePointAnnotation: View {
    let point: EditableRoutePoint
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(pointColor.opacity(0.2))
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                
                Circle()
                    .fill(pointColor)
                    .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
                    .overlay(
                        Image(systemName: point.pointType.icon)
                            .font(.system(size: isSelected ? 12 : 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                if isSelected {
                    Circle()
                        .stroke(pointColor, lineWidth: 2)
                        .frame(width: 35, height: 35)
                }
            }
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

// MARK: - 路线路径覆盖层（简化版）
struct RoutePathOverlay: View {
    let points: [EditableRoutePoint]
    
    var body: some View {
        // 这是一个简化的实现，实际应该使用MKPolyline
        Path { path in
            if let firstPoint = points.first {
                // 这里需要将地图坐标转换为视图坐标
                // 简化实现，仅作示意
            }
        }
        .stroke(Color.blue.opacity(0.6), lineWidth: 3)
    }
}

// MARK: - 浮动控制按钮
struct FloatingControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 地图信息栏
struct MapInfoBar: View {
    let pointsCount: Int
    let isAddingPoint: Bool
    let selectedLocation: CLLocationCoordinate2D?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("路线编辑")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if pointsCount >= 2 {
                    Text("✓ 可以继续")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1), in: Capsule())
                } else if selectedLocation != nil {
                    Text("点击 + 添加")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 100) // 为顶部导航预留空间
    }
    
    private var helperText: String {
        if selectedLocation != nil {
            return "已选择位置，点击加号添加点位"
        } else if pointsCount == 0 {
            return "点击地图选择第一个点位（起点）"
        } else if pointsCount == 1 {
            return "继续点击地图添加更多点位"
        } else {
            return "已添加 \(pointsCount) 个点位"
        }
    }
}

// MARK: - 地点搜索栏
struct LocationSearchBar: View {
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    @Binding var isSearching: Bool
    @Binding var showingSearchResults: Bool
    let onLocationSelected: (MKMapItem) -> Void
    
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchSuggestions: [MKLocalSearchCompletion] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("搜索地点...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { text in
                        if text.isEmpty {
                            showingSearchResults = false
                            searchSuggestions = []
                        } else {
                            searchCompleter.queryFragment = text
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        showingSearchResults = false
                        searchSuggestions = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
            
            // 搜索结果/建议
            if !searchSuggestions.isEmpty || showingSearchResults {
                VStack(spacing: 0) {
                    if !searchSuggestions.isEmpty && !showingSearchResults {
                        // 搜索建议
                        LazyVStack(spacing: 0) {
                            ForEach(Array(searchSuggestions.prefix(5).enumerated()), id: \.element.title) { index, suggestion in
                                RouteSearchSuggestionRow(
                                    suggestion: suggestion,
                                    onTap: {
                                        searchText = suggestion.title
                                        performSearchWithSuggestion(suggestion)
                                    }
                                )
                                
                                if index < min(4, searchSuggestions.count - 1) {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    } else if showingSearchResults {
                        // 搜索结果
                        if isSearching {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("搜索中...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else if searchResults.isEmpty {
                            Text("未找到相关地点")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(searchResults.enumerated()), id: \.element.placemark.name) { index, result in
                                    RouteSearchResultRow(
                                        result: result,
                                        onTap: {
                                            onLocationSelected(result)
                                        }
                                    )
                                    
                                    if index < searchResults.count - 1 {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 4)
            }
        }
        .onAppear {
            setupSearchCompleter()
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = RouteSearchCompleterDelegate { suggestions in
            searchSuggestions = suggestions
        }
        searchCompleter.resultTypes = [.pointOfInterest, .address]
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        showingSearchResults = true
        searchSuggestions = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = [.pointOfInterest, .address]
        
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
    
    private func performSearchWithSuggestion(_ suggestion: MKLocalSearchCompletion) {
        isSearching = true
        showingSearchResults = true
        searchSuggestions = []
        
        let request = MKLocalSearch.Request(completion: suggestion)
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

// MARK: - 路线搜索建议行
struct RouteSearchSuggestionRow: View {
    let suggestion: MKLocalSearchCompletion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 路线搜索结果行
struct RouteSearchResultRow: View {
    let result: MKMapItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name ?? "未知地点")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let address = formatAddress(result.placemark) {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(2)
                    }
                    
                    if let category = result.pointOfInterestCategory?.rawValue {
                        Text(formatCategory(category))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1), in: Capsule())
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        let components = [
            placemark.thoroughfare,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    private func formatCategory(_ category: String) -> String {
        // 简化分类名称显示
        switch category {
        case "MKPOICategoryRestaurant": return "餐厅"
        case "MKPOICategoryGasStation": return "加油站"
        case "MKPOICategoryHospital": return "医院"
        case "MKPOICategorySchool": return "学校"
        case "MKPOICategoryPark": return "公园"
        case "MKPOICategoryMuseum": return "博物馆"
        case "MKPOICategoryLibrary": return "图书馆"
        case "MKPOICategoryAmusementPark": return "游乐园"
        case "MKPOICategoryTheater": return "剧院"
        case "MKPOICategoryStore": return "商店"
        default: return "地点"
        }
    }
}

// MARK: - 路线搜索完成器代理
class RouteSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: ([MKLocalSearchCompletion]) -> Void
    
    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate([])
    }
}

#Preview {
    RouteEditorView()
} 