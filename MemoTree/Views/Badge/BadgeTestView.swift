//
//  BadgeTestView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI

struct BadgeTestView: View {
    @StateObject private var badgeManager = BadgeManager.shared
    @State private var showBadgeCollection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前统计
                    currentStatsSection
                    
                    // 测试按钮
                    testButtonsSection
                    
                    // 最近解锁的徽章
                    recentBadgesSection
                }
                .padding()
            }
            .navigationTitle("徽章测试")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("查看收藏") {
                        showBadgeCollection = true
                    }
                }
            }
            .sheet(isPresented: $showBadgeCollection) {
                BadgeCollectionView()
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
    }
    
    // MARK: - 当前统计
    private var currentStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前统计")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatRow(label: "完成路线", value: "\(badgeManager.userStats.completedRoutes)")
                StatRow(label: "官方路线", value: "\(badgeManager.userStats.completedOfficialRoutes)")
                StatRow(label: "步行距离", value: String(format: "%.0fm", badgeManager.userStats.totalDistance))
                StatRow(label: "访问地点", value: "\(badgeManager.userStats.visitedLocations)")
                StatRow(label: "社交分享", value: "\(badgeManager.userStats.socialShares)")
                StatRow(label: "AR导航", value: "\(badgeManager.userStats.arNavigationUsed)")
                StatRow(label: "拍照次数", value: "\(badgeManager.userStats.photosTaken)")
                StatRow(label: "连续天数", value: "\(badgeManager.userStats.consecutiveDays)")
                StatRow(label: "总经验", value: "\(badgeManager.userStats.experience)")
                StatRow(label: "已获徽章", value: "\(badgeManager.userBadges.count)")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 测试按钮
    private var testButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("测试功能")
                .font(.headline)
            
            VStack(spacing: 12) {
                // 路线完成测试
                VStack(spacing: 8) {
                    Text("路线完成")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        TestButton(title: "普通路线", color: .blue) {
                            badgeManager.recordRouteCompletion()
                        }
                        
                        TestButton(title: "官方路线", color: .green) {
                            badgeManager.recordRouteCompletion(isOfficial: true)
                        }
                        
                        TestButton(title: "端午路线", color: .red) {
                            badgeManager.recordRouteCompletion(
                                isOfficial: true,
                                festivalType: "dragon_boat"
                            )
                        }
                    }
                }
                
                // 行为记录测试
                VStack(spacing: 8) {
                    Text("行为记录")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        TestButton(title: "步行100m", color: .orange) {
                            badgeManager.recordWalkDistance(100)
                        }
                        
                        TestButton(title: "访问地点", color: .purple) {
                            badgeManager.recordLocationVisit()
                        }
                        
                        TestButton(title: "社交分享", color: .pink) {
                            badgeManager.recordSocialShare()
                        }
                        
                        TestButton(title: "AR导航", color: .cyan) {
                            badgeManager.recordARNavigation()
                        }
                        
                        TestButton(title: "拍照打卡", color: .brown) {
                            badgeManager.recordPhotoTaken()
                        }
                        
                        TestButton(title: "刷新检查", color: .gray) {
                            badgeManager.checkForNewBadges()
                        }
                    }
                }
                
                // 快速解锁测试
                VStack(spacing: 8) {
                    Text("快速解锁测试")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        TestButton(title: "首探徽章", color: .green) {
                            // 模拟完成第一条路线
                            if badgeManager.userStats.completedRoutes == 0 {
                                badgeManager.recordRouteCompletion()
                            }
                        }
                        
                        TestButton(title: "AR先锋", color: .blue) {
                            // 模拟首次AR导航
                            if badgeManager.userStats.arNavigationUsed == 0 {
                                badgeManager.recordARNavigation()
                            }
                        }
                        
                        TestButton(title: "端午徽章", color: .red) {
                            // 模拟端午节路线
                            badgeManager.recordRouteCompletion(
                                isOfficial: true,
                                festivalType: "dragon_boat"
                            )
                        }
                    }
                }
                
                // 批量操作
                VStack(spacing: 8) {
                    Text("批量操作")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        TestButton(title: "10条路线", color: .orange) {
                            for _ in 0..<10 {
                                badgeManager.recordRouteCompletion()
                            }
                        }
                        
                        TestButton(title: "5次分享", color: .purple) {
                            for _ in 0..<5 {
                                badgeManager.recordSocialShare()
                            }
                        }
                        
                        TestButton(title: "重置数据", color: .red) {
                            resetAllData()
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 最近解锁徽章
    private var recentBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近解锁")
                .font(.headline)
            
            if badgeManager.recentlyUnlocked.isEmpty {
                Text("暂无解锁的徽章")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(badgeManager.recentlyUnlocked.suffix(5), id: \.id) { badge in
                            RecentBadgeCard(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - 重置数据
    private func resetAllData() {
        // 清除UserDefaults中的数据
        UserDefaults.standard.removeObject(forKey: "user_badges")
        UserDefaults.standard.removeObject(forKey: "badge_progress")
        UserDefaults.standard.removeObject(forKey: "user_stats")
        
        // 重新初始化badgeManager
        badgeManager.userBadges.removeAll()
        badgeManager.badgeProgress.removeAll()
        badgeManager.recentlyUnlocked.removeAll()
        badgeManager.userStats = UserStats()
        
        // 重新初始化
        badgeManager.checkForNewBadges()
    }
}

// MARK: - 统计行组件
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 测试按钮组件
struct TestButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(color)
                .cornerRadius(8)
        }
    }
}

// MARK: - 最近徽章卡片
struct RecentBadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [badge.rarity.color.opacity(0.3), badge.rarity.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(badge.rarity.color, lineWidth: 2)
                    )
                
                Text(badge.icon)
                    .font(.title2)
            }
            
            Text(badge.name)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    BadgeTestView()
} 