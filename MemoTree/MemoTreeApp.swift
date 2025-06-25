//
//  MemoTreeApp.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

@main
struct MemoTreeApp: App {
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasShownOnboarding") private var hasShownOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasShownOnboarding {
                    // 首次启动显示引导页
                    OnboardingView()
                } else if authService.isLoggedIn {
                    // 已登录用户显示主界面
                    MainTabView()
                } else {
                    // 未登录用户显示登录页
                    LoginView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authService.isLoggedIn)
            .animation(.easeInOut(duration: 0.3), value: hasShownOnboarding)
        }
    }
}
