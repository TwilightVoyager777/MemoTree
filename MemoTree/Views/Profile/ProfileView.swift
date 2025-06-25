//
//  ProfileView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var animateCards = false
    @State private var showingAchievements = false
    @State private var showingMyRoutes = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 纯白色背景
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 32) {
                        // 用户头像和基本信息
                        ModernProfileHeaderView(showingEditProfile: $showingEditProfile)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        
                        // 统计数据卡片
                        ProfileStatsCardsView()
                            .padding(.horizontal, 24)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateCards)
                        
                        // 快速操作网格
                        QuickActionGridView(
                            showingAchievements: $showingAchievements,
                            showingMyRoutes: $showingMyRoutes
                        )
                        .padding(.horizontal, 24)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateCards)
                        
                        // 功能菜单列表
                        ProfileMenuListView(showingSettings: $showingSettings)
                            .padding(.horizontal, 24)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateCards)
                        
                        // 登出按钮
                        ModernLogoutButton {
                            authService.logout()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: animateCards)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showingMyRoutes) {
            MyRoutesView()
        }
        .onAppear {
            withAnimation {
                animateCards = true
            }
        }
    }
}

// MARK: - 现代化用户头部
struct ModernProfileHeaderView: View {
    @StateObject private var authService = AuthService.shared
    @Binding var showingEditProfile: Bool
    @State private var avatarPulse = false
    @State private var animateProfile = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 头像区域
            ZStack {
                // 外圈脉冲效果
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(avatarPulse ? 1.1 : 1.0)
                    .opacity(avatarPulse ? 0.7 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: avatarPulse)
                
                // 内圈光环
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                
                // 用户头像
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showingEditProfile = true
                    }
                }) {
                    SmartImageView(
                        imageSource: authService.currentUser?.avatar,
                        placeholder: Image(systemName: "person.fill"),
                        width: 100,
                        height: 100,
                        contentMode: .fill
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                    .scaleEffect(animateProfile ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateProfile)
                }
                
                // 编辑指示器
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(.green)
                            .frame(width: 32, height: 32)
                    )
                    .offset(x: 40, y: 35)
                    .scaleEffect(animateProfile ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateProfile)
            }
            
            // 用户信息
            VStack(spacing: 12) {
                // 用户名和认证
                HStack(spacing: 8) {
                    Text(authService.currentUser?.nickname ?? "城市探索者")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                        .symbolEffect(.pulse.wholeSymbol)
                }
                .opacity(animateProfile ? 1 : 0)
                .offset(y: animateProfile ? 0 : 10)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: animateProfile)
                
                // 个人简介
                Text(authService.currentUser?.bio ?? "热爱探索城市角落的旅行达人 🌟")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateProfile ? 1 : 0)
                    .offset(y: animateProfile ? 0 : 8)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: animateProfile)
                
                // 等级标签
                HStack(spacing: 12) {
                    LevelBadge(level: authService.currentUser?.level ?? 5)
                    JoinDateBadge(joinDate: authService.currentUser?.joinDate ?? "2023-01-15")
                }
                .opacity(animateProfile ? 1 : 0)
                .offset(y: animateProfile ? 0 : 6)
                .animation(.easeOut(duration: 0.8).delay(0.7), value: animateProfile)
            }
        }
        .onAppear {
            avatarPulse = true
            animateProfile = true
        }
    }
}

struct LevelBadge: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            Text("LV.\(level)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.gray.opacity(0.1), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct JoinDateBadge: View {
    let joinDate: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundColor(.green)
            
            Text(formatJoinDate(joinDate))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.gray.opacity(0.1), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatJoinDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let components = Calendar.current.dateComponents([.year, .month], from: date, to: now)
            
            if let years = components.year, years > 0 {
                return "\(years)年前加入"
            } else if let months = components.month, months > 0 {
                return "\(months)个月前加入"
            } else {
                return "新用户"
            }
        }
        return "探索者"
    }
}

// MARK: - 统计数据卡片
struct ProfileStatsCardsView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("我的数据")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                StatsCard(
                    title: "总里程",
                    value: formatDistance(authService.currentUser?.totalDistance ?? 125.6),
                    icon: "location.fill",
                    color: .blue,
                    delay: 0.1
                )
                
                StatsCard(
                    title: "完成路线",
                    value: "\(authService.currentUser?.completedRoutes ?? 45)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    delay: 0.2
                )
                
                StatsCard(
                    title: "创建路线",
                    value: "\(authService.currentUser?.routesCreated ?? 12)",
                    icon: "plus.circle.fill",
                    color: .orange,
                    delay: 0.3
                )
                
                StatsCard(
                    title: "获得点赞",
                    value: "\(authService.currentUser?.totalLikes ?? 2890)",
                    icon: "heart.fill",
                    color: .pink,
                    delay: 0.4
                )
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1fk公里", distance / 1000)
        } else {
            return String(format: "%.1f公里", distance)
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let delay: Double
    @State private var animate = false
    @State private var countValue = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // 数值和标题
            VStack(spacing: 6) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(countsDown: false))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(animate ? 1.0 : 0.8)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 快速操作网格
struct QuickActionGridView: View {
    @Binding var showingAchievements: Bool
    @Binding var showingMyRoutes: Bool
    
    let actions = [
        ("trophy.fill", "成就", "查看我的成就", Color.yellow),
        ("map.fill", "我的路线", "管理创建的路线", Color.green),
        ("heart.fill", "收藏", "我收藏的路线", Color.pink),
        ("clock.arrow.circlepath", "历史", "探索历史记录", Color.purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速操作")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(Array(actions.enumerated()), id: \.element.1) { index, action in
                    QuickActionButton(
                        icon: action.0,
                        title: action.1,
                        subtitle: action.2,
                        color: action.3,
                        delay: Double(index) * 0.1
                    ) {
                        handleAction(action.1)
                    }
                }
            }
        }
    }
    
    private func handleAction(_ actionTitle: String) {
        switch actionTitle {
        case "成就":
            showingAchievements = true
        case "我的路线":
            showingMyRoutes = true
        case "收藏":
            // TODO: 打开收藏页面
            break
        case "历史":
            // TODO: 打开历史页面
            break
        default:
            break
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let delay: Double
    let action: () -> Void
    
    @State private var animate = false
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
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : (animate ? 1.0 : 0.8))
            .opacity(animate ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 功能菜单列表
struct ProfileMenuListView: View {
    @Binding var showingSettings: Bool
    @State private var showingBadgeTest = false
    
    let menuItems = [
        ("person.crop.circle", "编辑资料", "更新个人信息", Color.blue),
        ("trophy.circle", "徽章测试", "测试徽章解锁功能", Color.orange),
        ("shield.checkered", "隐私设置", "管理隐私选项", Color.green),
        ("bell", "通知设置", "消息通知管理", Color.orange),
        ("questionmark.circle", "帮助支持", "常见问题解答", Color.purple),
        ("info.circle", "关于应用", "版本信息", Color.gray)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("更多功能")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(menuItems.enumerated()), id: \.element.1) { index, item in
                    ProfileMenuRow(
                        icon: item.0,
                        title: item.1,
                        subtitle: item.2,
                        color: item.3,
                        delay: Double(index) * 0.05
                    ) {
                        handleMenuAction(item.1)
                    }
                }
            }
        }
        .sheet(isPresented: $showingBadgeTest) {
            BadgeTestView()
        }
    }
    
    private func handleMenuAction(_ title: String) {
        switch title {
        case "编辑资料":
            // TODO: 打开编辑资料页面
            break
        case "徽章测试":
            showingBadgeTest = true
        case "隐私设置", "通知设置", "帮助支持", "关于应用":
            showingSettings = true
        default:
            break
        }
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let delay: Double
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
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(animate ? 1 : 0)
            .offset(x: animate ? 0 : -30)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - 现代化登出按钮
struct ModernLogoutButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
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
            HStack(spacing: 12) {
                Image(systemName: "power")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("退出登录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 占位符视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("设置")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("应用设置和个人偏好")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("编辑资料")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("更新您的个人信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var badgeManager = BadgeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部统计
                    achievementHeader
                    
                    // 徽章网格
                    achievementGrid
                    
                    // 测试按钮（开发调试用）
//                    testButtons
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("我的成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .alert("🎉 获得新徽章！", isPresented: $badgeManager.showBadgeAlert) {
            Button("太棒了！") {
                badgeManager.dismissBadgeAlert()
            }
        } message: {
            if let badge = badgeManager.newBadge {
                Text(badge.unlockMessage)
            }
        }
    }
    
    // MARK: - 头部统计区域
    private var achievementHeader: some View {
        VStack(spacing: 16) {
            // 主要图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange.opacity(0.3), .yellow.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // 统计信息
            VStack(spacing: 8) {
                Text("成就徽章")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 20) {
                    AchievementStatItem(
                        value: "\(unlockedCount)",
                        label: "已获得",
                        color: .green
                    )
                    
                    AchievementStatItem(
                        value: "\(totalCount)",
                        label: "总数量",
                        color: .blue
                    )
                    
                    AchievementStatItem(
                        value: "\(badgeManager.userStats.experience)",
                        label: "总经验",
                        color: .purple
                    )
                }
            }
        }
    }
    
    // MARK: - 徽章网格
    private var achievementGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("徽章收藏")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(achievementBadges, id: \.id) { badge in
                    AchievementBadgeCard(badge: badge)
                }
            }
        }
    }
    
//    // MARK: - 测试按钮区域
//    private var testButtons: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("快速解锁测试")
//                .font(.headline)
//                .fontWeight(.bold)
//                .foregroundColor(.primary)
//            
//            LazyVGrid(columns: [
//                GridItem(.flexible()),
//                GridItem(.flexible())
//            ], spacing: 12) {
//                TestButton(title: "端午徽章", color: .red) {
//                    badgeManager.recordRouteCompletion(isOfficial: true, festivalType: "dragon_boat")
//                }
//                
//                TestButton(title: "探索达人", color: .blue) {
//                    // 快速完成10条路线
//                    for _ in 0..<10 {
//                        badgeManager.recordRouteCompletion()
//                    }
//                }
//                
//                TestButton(title: "AR先锋", color: .purple) {
//                    badgeManager.recordARNavigation()
//                }
//                
//                TestButton(title: "分享达人", color: .green) {
//                    // 快速分享5次
//                    for _ in 0..<5 {
//                        badgeManager.recordSocialShare()
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(Color(.secondarySystemGroupedBackground))
//        .cornerRadius(12)
//    }
//    
    // MARK: - 计算属性
    private var achievementBadges: [AchievementBadge] {
        return [
            AchievementBadge(
                id: 1,
                imageName: "11",
                name: "端午安康",
                description: "完成端午节活动路线",
                isUnlocked: badgeManager.userBadges.contains(where: { $0.name == "端午安康" })
            ),
            AchievementBadge(
                id: 2,
                imageName: "2",
                name: "探索达人",
                description: "完成10条不同路线",
                isUnlocked: badgeManager.userBadges.contains(where: { $0.name == "路线达人" })
            ),
            AchievementBadge(
                id: 3,
                imageName: "3",
                name: "AR先锋",
                description: "首次使用AR导航",
                isUnlocked: badgeManager.userBadges.contains(where: { $0.name == "AR先锋" })
            ),
            AchievementBadge(
                id: 4,
                imageName: "4",
                name: "分享之星",
                description: "分享路线5次以上",
                isUnlocked: badgeManager.userBadges.contains(where: { $0.name == "分享达人" })
            )
        ]
    }
    
    private var unlockedCount: Int {
        return achievementBadges.filter { $0.isUnlocked }.count
    }
    
    private var totalCount: Int {
        return achievementBadges.count
    }
}

// MARK: - 徽章数据模型
struct AchievementBadge {
    let id: Int
    let imageName: String
    let name: String
    let description: String
    let isUnlocked: Bool
}

// MARK: - 成就统计项组件
struct AchievementStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 徽章卡片组件
struct AchievementBadgeCard: View {
    let badge: AchievementBadge
    
    var body: some View {
        VStack(spacing: 12) {
            // 徽章图片
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        badge.isUnlocked
                            ? LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                badge.isUnlocked ? Color.orange.opacity(0.6) : Color.gray.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                
                Image(badge.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .opacity(badge.isUnlocked ? 1.0 : 0.3)
                    .grayscale(badge.isUnlocked ? 0.0 : 1.0)
                
                // 解锁状态指示
                if badge.isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                        }
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                        }
                        Spacer()
                    }
                    .frame(width: 80, height: 80)
                }
            }
            
            // 徽章信息
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(badge.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                
                Text(badge.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(badge.isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: badge.isUnlocked)
    }
}

struct MyRoutesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("我的路线")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("管理您创建的所有路线")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("我的路线")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - 公共扩展
extension View {
    func backdrop(blur radius: CGFloat) -> some View {
        self.background(.ultraThinMaterial)
    }
}

#Preview {
    ProfileView()
} 
