//
//  BadgeDetailView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI

struct BadgeDetailView: View {
    let badge: Badge
    @ObservedObject var badgeManager: BadgeManager
    @Environment(\.dismiss) private var dismiss
    
    private var isUnlocked: Bool {
        badgeManager.userBadges.contains(where: { $0.id == badge.id })
    }
    
    private var progress: Double {
        badgeManager.getBadgeProgress(badge.id)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 徽章主要信息
                    badgeHeader
                    
                    // 解锁条件
                    conditionsSection
                    
                    // 奖励信息
                    if let rewards = badge.rewards {
                        rewardsSection(rewards)
                    }
                    
                    // 时效信息
                    if let validUntil = badge.validUntil {
                        timeValiditySection(validUntil)
                    }
                    
                    // 解锁时间（如果已解锁）
                    if isUnlocked, let unlockedAt = badge.unlockedAt {
                        unlockTimeSection(unlockedAt)
                    }
                }
                .padding()
            }
            .navigationTitle(badge.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                if !isUnlocked {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(
                            item: "我正在挑战「\(badge.name)」徽章！一起来MemoTree探索吧！",
                            preview: SharePreview(
                                badge.name,
                                icon: Image(systemName: "trophy")
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 徽章头部
    private var badgeHeader: some View {
        VStack(spacing: 16) {
            // 大号徽章图标
            ZStack {
                Circle()
                    .fill(
                        isUnlocked 
                            ? RadialGradient(
                                colors: [
                                    badge.rarity.color.opacity(0.4),
                                    badge.rarity.color.opacity(0.1),
                                    badge.category.color.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                            : RadialGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                isUnlocked ? badge.rarity.color : Color.gray.opacity(0.4),
                                lineWidth: badge.rarity.borderWidth * 1.5
                            )
                    )
                
                Text(badge.icon)
                    .font(.system(size: 48))
                    .opacity(isUnlocked ? 1.0 : 0.4)
                
                // 解锁效果
                if isUnlocked {
                    Circle()
                        .stroke(badge.rarity.color.opacity(0.3), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(1.0)
                        .opacity(0.6)
                }
            }
            
            // 徽章基本信息
            VStack(spacing: 8) {
                HStack {
                    Text(badge.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badge.category.color.opacity(0.2))
                        .foregroundColor(badge.category.color)
                        .cornerRadius(6)
                    
                    Text(badge.rarity.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badge.rarity.color.opacity(0.2))
                        .foregroundColor(badge.rarity.color)
                        .cornerRadius(6)
                }
                
                Text(badge.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 解锁条件
    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解锁条件")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                conditionDescription
                
                if !isUnlocked {
                    progressIndicator
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var conditionDescription: some View {
        HStack {
            Image(systemName: conditionIcon)
                .foregroundColor(badge.category.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conditionText)
                    .font(.body)
                
                if let detail = conditionDetail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
    }
    
    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("进度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * Double(badge.conditions.target)))/\(badge.conditions.target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: badge.category.color))
                .frame(height: 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(3)
        }
    }
    
    // MARK: - 奖励信息
    private func rewardsSection(_ rewards: BadgeRewards) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("奖励内容")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // 经验奖励
                RewardItem(
                    icon: "star.fill",
                    title: "经验值",
                    value: "+\(rewards.experience)",
                    color: .yellow
                )
                
                // 称号奖励
                if let title = rewards.title {
                    RewardItem(
                        icon: "crown.fill",
                        title: "专属称号",
                        value: title,
                        color: .purple
                    )
                }
                
                // 头像奖励
                if let avatar = rewards.avatar {
                    RewardItem(
                        icon: "person.circle.fill",
                        title: "专属头像",
                        value: avatar,
                        color: .blue
                    )
                }
                
                // 特殊功能
                if let feature = rewards.specialFeature {
                    RewardItem(
                        icon: "sparkles",
                        title: "特殊功能",
                        value: feature,
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 时效信息
    private func timeValiditySection(_ validUntil: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活动时效")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("限时活动徽章")
                        .font(.body)
                    
                    Text("截止时间：\(validUntil, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if Date() <= validUntil {
                    Text("进行中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                } else {
                    Text("已结束")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 解锁时间
    private func unlockTimeSection(_ unlockedAt: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解锁记录")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("徽章解锁时间")
                        .font(.body)
                    
                    Text("\(unlockedAt, formatter: detailDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("已解锁")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - 计算属性
    private var conditionIcon: String {
        switch badge.conditions.type {
        case .completeRoutesCount, .completeOfficialRoute:
            return "map.fill"
        case .walkDistance:
            return "figure.walk"
        case .visitLocations:
            return "location.fill"
        case .socialShare:
            return "square.and.arrow.up"
        case .arNavigation:
            return "camera.viewfinder"
        case .consecutiveDays:
            return "calendar"
        case .photoTaken:
            return "camera.fill"
        case .festivalActivity:
            return "party.popper.fill"
        case .specificDate:
            return "clock.fill"
        }
    }
    
    private var conditionText: String {
        switch badge.conditions.type {
        case .completeRoutesCount:
            return "完成 \(badge.conditions.target) 条路线"
        case .completeOfficialRoute:
            return "完成 \(badge.conditions.target) 条官方路线"
        case .walkDistance:
            return "步行距离达到 \(badge.conditions.target) 米"
        case .visitLocations:
            return "访问 \(badge.conditions.target) 个地点"
        case .socialShare:
            return "分享 \(badge.conditions.target) 次路线"
        case .arNavigation:
            return "使用AR导航功能"
        case .consecutiveDays:
            return "连续使用 \(badge.conditions.target) 天"
        case .photoTaken:
            return "拍摄 \(badge.conditions.target) 张照片"
        case .festivalActivity:
            return "完成节日主题活动"
        case .specificDate:
            return "早期用户专属"
        }
    }
    
    private var conditionDetail: String? {
        switch badge.conditions.type {
        case .festivalActivity:
            if let festival = badge.conditions.parameters?["festival"] {
                switch festival {
                case "dragon_boat":
                    return "参与端午节官方主题路线活动"
                default:
                    return "参与节日主题活动"
                }
            }
            return nil
        case .specificDate:
            if let beforeDate = badge.conditions.parameters?["before"] {
                return "在 \(beforeDate) 之前注册的用户"
            }
            return nil
        default:
            return nil
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    private var detailDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter
    }
}

// MARK: - 奖励项目组件
struct RewardItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BadgeDetailView(
        badge: BadgePresets.allBadges[0],
        badgeManager: BadgeManager.shared
    )
} 