//
//  RoutePreviewView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import MapKit

struct RoutePreviewView: View {
    let routeName: String
    let routeDescription: String
    let difficulty: Difficulty
    let tags: [RouteTag]
    let routePoints: [EditableRoutePoint]
    let estimatedDuration: Int
    let isPublic: Bool
    
    @State private var animateContent = false
    @State private var selectedTab = 0
    
    private var totalDistance: Double {
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
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题区域
            PreviewHeader(routeName: routeName)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : -20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateContent)
            
            // 分段控制器
            PreviewSegmentedControl(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateContent)
            
            // 内容区域
            TabView(selection: $selectedTab) {
                // 路线概览
                RouteOverviewTab(
                    routeDescription: routeDescription,
                    difficulty: difficulty,
                    tags: tags,
                    totalDistance: totalDistance,
                    estimatedDuration: estimatedDuration,
                    isPublic: isPublic,
                    pointsCount: routePoints.count
                )
                .tag(0)
                
                // 地图预览
                RouteMapPreviewTab(routePoints: routePoints)
                .tag(1)
                
                // 点位列表
                RoutePointsListTab(routePoints: routePoints)
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateContent)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
        .padding(.vertical, 20)
        .padding(.top, 180) // 为顶部导航预留足够空间
    }
}

// MARK: - 预览头部
struct PreviewHeader: View {
    let routeName: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text("路线预览")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(routeName.isEmpty ? "未命名路线" : routeName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("确认信息无误后即可发布")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .padding(.top, 180) // 为顶部导航预留足够空间
    }
}

// MARK: - 分段控制器
struct PreviewSegmentedControl: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        ("概览", "info.circle.fill"),
        ("地图", "map.fill"),
        ("点位", "list.bullet.circle.fill")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.1)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(tab.0)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == index ? .white : .purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == index ? .purple : .clear)
                    )
                }
            }
        }
        .padding(4)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 路线概览标签页
struct RouteOverviewTab: View {
    let routeDescription: String
    let difficulty: Difficulty
    let tags: [RouteTag]
    let totalDistance: Double
    let estimatedDuration: Int
    let isPublic: Bool
    let pointsCount: Int
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 基本信息
                RouteBasicInfoCard(
                    totalDistance: totalDistance,
                    estimatedDuration: estimatedDuration,
                    difficulty: difficulty,
                    pointsCount: pointsCount
                )
                
                // 路线描述
                if !routeDescription.isEmpty {
                    RouteDescriptionCard(description: routeDescription)
                }
                
                // 标签
                if !tags.isEmpty {
                    RouteTagsCard(tags: tags)
                }
                
                // 隐私设置
                PrivacyInfoCard(isPublic: isPublic)
                
                // 底部间距
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - 基本信息卡片
struct RouteBasicInfoCard: View {
    let totalDistance: Double
    let estimatedDuration: Int
    let difficulty: Difficulty
    let pointsCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("基本信息")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                InfoGridItem(
                    icon: "map",
                    value: String(format: "%.1f km", totalDistance),
                    label: "总距离",
                    color: .blue
                )
                
                InfoGridItem(
                    icon: "clock",
                    value: formatDuration(estimatedDuration),
                    label: "预估时长",
                    color: .green
                )
                
                InfoGridItem(
                    icon: "speedometer",
                    value: difficulty.displayName,
                    label: "难度等级",
                    color: difficulty.color
                )
                
                InfoGridItem(
                    icon: "mappin.and.ellipse",
                    value: "\(pointsCount) 个",
                    label: "途经点位",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

struct InfoGridItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 路线描述卡片
struct RouteDescriptionCard: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("路线描述", systemImage: "text.alignleft.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 标签卡片
struct RouteTagsCard: View {
    let tags: [RouteTag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("路线标签", systemImage: "tag.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(tags.count) 个标签")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            FlowLayout(tags) { tag in
                HStack(spacing: 6) {
                    Image(systemName: tag.icon)
                        .font(.caption)
                    
                    Text(tag.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.purple.opacity(0.1), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 隐私信息卡片
struct PrivacyInfoCard: View {
    let isPublic: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill((isPublic ? Color.green : Color.blue).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: isPublic ? "globe" : "lock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isPublic ? .green : .blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isPublic ? "公开路线" : "私人路线")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(isPublic ? "所有人都可以发现和使用" : "只有你自己可以看到")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 地图预览标签页
struct RouteMapPreviewTab: View {
    let routePoints: [EditableRoutePoint]
    
    @State private var mapRegion: MKCoordinateRegion
    
    init(routePoints: [EditableRoutePoint]) {
        self.routePoints = routePoints
        
        // 计算地图区域
        let coordinates = routePoints.map { $0.coordinate }
        if coordinates.isEmpty {
            self._mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            let latitudes = coordinates.map { $0.latitude }
            let longitudes = coordinates.map { $0.longitude }
            
            let minLat = latitudes.min() ?? 0
            let maxLat = latitudes.max() ?? 0
            let minLng = longitudes.min() ?? 0
            let maxLng = longitudes.max() ?? 0
            
            let centerLat = (minLat + maxLat) / 2
            let centerLng = (minLng + maxLng) / 2
            let spanLat = (maxLat - minLat) * 1.3 // 留一些边距
            let spanLng = (maxLng - minLng) * 1.3
            
            self._mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
                span: MKCoordinateSpan(
                    latitudeDelta: max(spanLat, 0.005),
                    longitudeDelta: max(spanLng, 0.005)
                )
            ))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 地图
            Map(coordinateRegion: .constant(mapRegion), annotationItems: routePoints) { point in
                MapAnnotation(coordinate: point.coordinate) {
                    RoutePointPreviewAnnotation(
                        point: point,
                        index: routePoints.firstIndex(where: { $0.id == point.id }) ?? 0
                    )
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 地图信息
            MapPreviewInfo(pointsCount: routePoints.count)
                .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - 路线点预览标注
struct RoutePointPreviewAnnotation: View {
    let point: EditableRoutePoint
    let index: Int
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(pointColor.opacity(0.3))
                    .frame(width: 30, height: 30)
                
                Circle()
                    .fill(pointColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: point.pointType.icon)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            Text(point.name.isEmpty ? "点位 \(index + 1)" : point.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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

// MARK: - 地图预览信息
struct MapPreviewInfo: View {
    let pointsCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("路线地图")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("共 \(pointsCount) 个点位")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("预览模式")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.purple.opacity(0.1), in: Capsule())
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 点位列表标签页
struct RoutePointsListTab: View {
    let routePoints: [EditableRoutePoint]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack {
                    Text("点位列表")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("共 \(routePoints.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ForEach(Array(routePoints.enumerated()), id: \.element.id) { index, point in
                    RoutePointPreviewCard(
                        point: point,
                        index: index,
                        isLast: index == routePoints.count - 1
                    )
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - 点位预览卡片
struct RoutePointPreviewCard: View {
    let point: EditableRoutePoint
    let index: Int
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 点位图标和连线
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(pointColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .fill(pointColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: point.pointType.icon)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    if !isLast {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 2, height: 20)
                    }
                }
                
                // 点位信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(point.name.isEmpty ? "点位 \(index + 1)" : point.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(point.pointType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(pointColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(pointColor.opacity(0.1), in: Capsule())
                    }
                    
                    if !point.description.isEmpty {
                        Text(point.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("纬度: \(String(format: "%.4f", point.coordinate.latitude))  经度: \(String(format: "%.4f", point.coordinate.longitude))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .monospaced()
                }
                
                Spacer()
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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

#Preview {
    RoutePreviewView(
        routeName: "西湖漫步之旅",
        routeDescription: "这是一条经典的西湖环湖路线，带您领略杭州最美的湖光山色。",
        difficulty: .easy,
        tags: [.nature, .photography, .couple],
        routePoints: [
            EditableRoutePoint(
                coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
                name: "西湖断桥",
                description: "著名的断桥残雪景点",
                pointType: .start
            ),
            EditableRoutePoint(
                coordinate: CLLocationCoordinate2D(latitude: 30.2731, longitude: 120.1561),
                name: "白堤",
                description: "美丽的白堤景色",
                pointType: .viewpoint
            ),
            EditableRoutePoint(
                coordinate: CLLocationCoordinate2D(latitude: 30.2721, longitude: 120.1571),
                name: "苏堤",
                description: "苏堤春晓美景",
                pointType: .end
            )
        ],
        estimatedDuration: 120,
        isPublic: true
    )
} 