//
//  BadgeCollectionView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI

struct BadgeCollectionView: View {
    @StateObject private var badgeManager = BadgeManager.shared
    @State private var selectedCategory: BadgeCategory = .festival
    @State private var selectedBadge: Badge?
    @State private var showBadgeDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计信息栏
                statsHeader
                
                // 分类选择器
                categorySelector
                
                // 徽章网格
                badgeGrid
            }
            .navigationTitle("徽章收藏")
            .navigationBarTitleDisplayMode(.large)
            .alert("🎉 获得新徽章！", isPresented: $badgeManager.showBadgeAlert) {
                Button("太棒了！") {
                    badgeManager.dismissBadgeAlert()
                }
            } message: {
                if let badge = badgeManager.newBadge {
                    Text(badge.unlockMessage)
                }
            }
            .sheet(isPresented: $showBadgeDetail) {
                if let badge = selectedBadge {
                    BadgeDetailView(badge: badge, badgeManager: badgeManager)
                }
            }
        }
    }
    
    // MARK: - 统计信息栏
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatCard(
                    title: "已获得",
                    value: "\(badgeManager.userBadges.count)",
                    icon: "trophy.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "总经验",
                    value: "\(badgeManager.userStats.experience)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "连续天数",
                    value: "\(badgeManager.userStats.consecutiveDays)",
                    icon: "calendar",
                    color: .green
                )
            }
            
            // 当前活动提醒
            if hasActiveFestivalBadges {
                activeEventBanner
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var hasActiveFestivalBadges: Bool {
        BadgePresets.allBadges.contains { badge in
            badge.category == .festival && 
            badge.isActive && 
            !badgeManager.userBadges.contains(where: { $0.id == badge.id })
        }
    }
    
    private var activeEventBanner: some View {
        HStack {
            Text("🎯")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("端午节活动进行中")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("完成官方路线即可获得专属徽章")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button("查看") {
                selectedCategory = .festival
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - 分类选择器
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        badgeCount: getBadgeCount(for: category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func getBadgeCount(for category: BadgeCategory) -> (unlocked: Int, total: Int) {
        let totalBadges = BadgePresets.allBadges.filter { $0.category == category }
        let unlockedBadges = badgeManager.userBadges.filter { $0.category == category }
        return (unlocked: unlockedBadges.count, total: totalBadges.count)
    }
    
    // MARK: - 徽章网格
    private var badgeGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(getBadgesForSelectedCategory(), id: \.id) { badge in
                    BadgeCard(
                        badge: badge,
                        isUnlocked: badgeManager.userBadges.contains(where: { $0.id == badge.id }),
                        progress: badgeManager.getBadgeProgress(badge.id)
                    ) {
                        selectedBadge = badge
                        showBadgeDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    private func getBadgesForSelectedCategory() -> [Badge] {
        return BadgePresets.allBadges.filter { $0.category == selectedCategory }
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - 分类按钮
struct CategoryButton: View {
    let category: BadgeCategory
    let isSelected: Bool
    let badgeCount: (unlocked: Int, total: Int)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(category.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    Text("\(badgeCount.unlocked)/\(badgeCount.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isSelected {
                    Rectangle()
                        .fill(category.color)
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
        }
        .foregroundColor(isSelected ? category.color : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - 徽章卡片
struct BadgeCard: View {
    let badge: Badge
    let isUnlocked: Bool
    let progress: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 徽章图标
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked 
                                ? LinearGradient(
                                    colors: [badge.rarity.color.opacity(0.3), badge.rarity.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    isUnlocked ? badge.rarity.color : Color.gray.opacity(0.3),
                                    lineWidth: badge.rarity.borderWidth
                                )
                        )
                    
                    Text(badge.icon)
                        .font(.title)
                        .opacity(isUnlocked ? 1.0 : 0.4)
                }
                
                // 徽章名称
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                // 稀有度指示
                Text(badge.rarity.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isUnlocked ? badge.rarity.color.opacity(0.2) : Color.gray.opacity(0.1)
                    )
                    .cornerRadius(4)
                    .foregroundColor(isUnlocked ? badge.rarity.color : .secondary)
                
                // 进度条（未解锁时显示）
                if !isUnlocked && progress > 0 {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: badge.category.color))
                        .frame(height: 2)
                }
            }
            .frame(width: 100, height: 140)
            .padding(8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BadgeCollectionView()
} 