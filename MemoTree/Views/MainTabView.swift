//
//  MainTabView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var routeService = RouteService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            DiscoverView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .font(.system(size: 20, weight: .medium))
                        Text("首页")
                            .font(.caption)
                    }
                }
                .tag(0)
            
            // 地图页
            MapView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                            .font(.system(size: 20, weight: .medium))
                        Text("地图")
                            .font(.caption)
                    }
                }
                .tag(1)
            
            // 创建页
            CreateRouteView()
                .tabItem {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(selectedTab == 2 ? Color.green : Color.clear)
                                .frame(width: 32, height: 32)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(selectedTab == 2 ? .white : .primary)
                        }
                        Text("创建")
                            .font(.caption)
                    }
                }
                .tag(2)
            
            // 消息页
            DiscussView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "message.fill" : "message")
                            .font(.system(size: 20, weight: .medium))
                        Text("消息")
                            .font(.caption)
                    }
                }
                .tag(3)
            
            // 个人页
            ProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                            .font(.system(size: 20, weight: .medium))
                        Text("我的")
                            .font(.caption)
                    }
                }
                .tag(4)
        }
        .tint(Color.green)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        
        // 设置正常状态的颜色
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // 设置选中状态的颜色
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemGreen,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // 添加模糊效果
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // 添加顶部边框
        UITabBar.appearance().layer.borderWidth = 0.5
        UITabBar.appearance().layer.borderColor = UIColor.systemGray5.cgColor
    }
}

#Preview {
    MainTabView()
} 
