//
//  AllRoutesView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/1.
//

import SwiftUI
import Combine

struct AllRoutesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeService = RouteService.shared
    @State private var searchText = ""
    @State private var selectedFilter: RouteFilter = .all
    @State private var showingFilters = false
    @State private var animateList = false
    
    enum RouteFilter: String, CaseIterable {
        case all = "全部"
        case featured = "精选"
        case popular = "热门"
        case newest = "最新"
        case nearby = "附近"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .featured: return "star.fill"
            case .popular: return "flame.fill"
            case .newest: return "clock.fill"
            case .nearby: return "location.fill"
            }
        }
    }
    
    var filteredRoutes: [Route] {
        var routes = routeService.routes
        
        // 按过滤器筛选
        switch selectedFilter {
        case .all:
            break
        case .featured:
            routes = routeService.featuredRoutes
        case .popular:
            routes = routeService.popularRoutes
        case .newest:
            routes = routes.sorted { $0.createdAt > $1.createdAt }
        case .nearby:
            // TODO: 实现附近路线逻辑
            break
        }
        
        // 按搜索词筛选
        if !searchText.isEmpty {
            routes = routes.filter { route in
                route.name.localizedCaseInsensitiveContains(searchText) ||
                (route.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return routes
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.98, blue: 0.95),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏
                    VStack(spacing: 16) {
                        HStack {
                            // 搜索框
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("搜索路线...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                            
                            // 筛选按钮
                            Button(action: {
                                showingFilters.toggle()
                            }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                                    .frame(width: 44, height: 44)
                                    .background(.green.opacity(0.1), in: Circle())
                            }
                        }
                        
                        // 筛选标签
                        if showingFilters {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(RouteFilter.allCases, id: \.self) { filter in
                                        FilterChip(
                                            filter: filter,
                                            isSelected: selectedFilter == filter
                                        ) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedFilter = filter
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    // 路线列表
                    if filteredRoutes.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: searchText.isEmpty ? "map" : "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text(searchText.isEmpty ? "暂无路线" : "未找到相关路线")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(searchText.isEmpty ? "快去创建第一条路线吧！" : "试试其他关键词")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(filteredRoutes.enumerated()), id: \.element.id) { index, route in
                                    RouteListCard(route: route)
                                        .opacity(animateList ? 1 : 0)
                                        .offset(y: animateList ? 0 : 30)
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.8)
                                                .delay(Double(index) * 0.05),
                                            value: animateList
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("全部路线")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            loadAllRoutes()
            withAnimation {
                animateList = true
            }
        }
    }
    
    private func loadAllRoutes() {
        // 加载所有类型的路线
        routeService.fetchAllRoutes()
        routeService.fetchFeaturedRoutes()
        routeService.fetchPopularRoutes()
    }
}

// MARK: - 筛选芯片
struct FilterChip: View {
    let filter: AllRoutesView.RouteFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .green)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? .green : .green.opacity(0.1),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : .green.opacity(0.3), lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - 路线列表卡片
struct RouteListCard: View {
    let route: Route
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: RouteDetailView(route: route)) {
            HStack(spacing: 16) {
                // 路线图片
                SmartImageView(
                    imageSource: route.coverImage,
                    placeholder: Image(systemName: "map.fill"),
                    width: 80,
                    height: 80,
                    contentMode: .fill
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 路线信息
                VStack(alignment: .leading, spacing: 8) {
                    // 路线名称和评分
                    HStack {
                        Text(route.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", route.averageRating))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // 路线描述
                    if let description = route.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // 路线统计信息
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text(route.formattedDistance)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            
                            Text(route.formattedDuration)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.pink)
                            
                            Text("\(route.likes)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // 路线标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(route.tags.prefix(3)), id: \.rawValue) { tag in
                                Text(tag.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.green.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
                
                // 箭头指示器
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.primary.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
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

#Preview {
    AllRoutesView()
} 