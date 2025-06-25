//
//  Badge.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import Foundation
import SwiftUI

// MARK: - 徽章数据模型
struct Badge: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let iconColor: String
    let category: BadgeCategory
    let rarity: BadgeRarity
    let conditions: BadgeConditions
    let rewards: BadgeRewards?
    let isActive: Bool // 是否是当前活动徽章
    let validUntil: Date? // 限时徽章的截止时间
    let unlockMessage: String
    
    // 创建时间和解锁时间
    let createdAt: Date
    var unlockedAt: Date?
    var isUnlocked: Bool { unlockedAt != nil }
}

// MARK: - 徽章类别
enum BadgeCategory: String, CaseIterable, Codable {
    case exploration = "exploration"    // 探索类
    case festival = "festival"         // 节日活动类
    case achievement = "achievement"   // 成就类
    case social = "social"            // 社交类
    case special = "special"          // 特殊类
    case seasonal = "seasonal"        // 季节类
    
    var displayName: String {
        switch self {
        case .exploration: return "探索发现"
        case .festival: return "节日庆典"
        case .achievement: return "里程碑"
        case .social: return "社交达人"
        case .special: return "特殊荣誉"
        case .seasonal: return "四季轮回"
        }
    }
    
    var color: Color {
        switch self {
        case .exploration: return .green
        case .festival: return .red
        case .achievement: return .blue
        case .social: return .purple
        case .special: return .orange
        case .seasonal: return .cyan
        }
    }
}

// MARK: - 徽章稀有度
enum BadgeRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case mythic = "mythic"
    
    var displayName: String {
        switch self {
        case .common: return "普通"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        case .mythic: return "神话"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .mythic: return .red
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .common: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        case .mythic: return 5
        }
    }
}

// MARK: - 徽章解锁条件
struct BadgeConditions: Codable {
    let type: ConditionType
    let target: Int
    let parameters: [String: String]?
    
    enum ConditionType: String, Codable {
        case completeOfficialRoute = "complete_official_route"  // 完成官方路线
        case completeRoutesCount = "complete_routes_count"      // 完成路线数量
        case walkDistance = "walk_distance"                     // 步行距离
        case visitLocations = "visit_locations"                 // 访问地点数量
        case festivalActivity = "festival_activity"             // 节日活动
        case socialShare = "social_share"                       // 社交分享
        case consecutiveDays = "consecutive_days"               // 连续天数
        case specificDate = "specific_date"                     // 特定日期
        case arNavigation = "ar_navigation"                     // AR导航使用
        case photoTaken = "photo_taken"                         // 拍照打卡
    }
}

// MARK: - 徽章奖励
struct BadgeRewards: Codable {
    let experience: Int
    let title: String?
    let avatar: String?
    let specialFeature: String?
}

// MARK: - 用户徽章进度
struct UserBadgeProgress: Codable {
    let badgeId: UUID
    var currentProgress: Int
    var completedAt: Date?
    var lastUpdated: Date
}

// MARK: - 预设徽章数据
struct BadgePresets {
    static let allBadges: [Badge] = [
        // 端午节活动徽章
        Badge(
            name: "端午安康",
            description: "完成端午节官方主题路线，感受传统文化魅力",
            icon: "🏮",
            iconColor: "red",
            category: .festival,
            rarity: .epic,
            conditions: BadgeConditions(
                type: .festivalActivity,
                target: 1,
                parameters: ["festival": "dragon_boat", "route_type": "official"]
            ),
            rewards: BadgeRewards(
                experience: 500,
                title: "端午文化传承者",
                avatar: "dragon_boat_avatar",
                specialFeature: "专属端午节边框"
            ),
            isActive: true,
            validUntil: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            unlockMessage: "🎉 恭喜获得「端午安康」徽章！传统文化的魅力在你的足迹中绽放！",
            createdAt: Date()
        ),
        
        // 探索类徽章
        Badge(
            name: "初探江湖",
            description: "完成你的第一条探索路线",
            icon: "🗺️",
            iconColor: "green",
            category: .exploration,
            rarity: .common,
            conditions: BadgeConditions(
                type: .completeRoutesCount,
                target: 1,
                parameters: nil
            ),
            rewards: BadgeRewards(
                experience: 100,
                title: "新手探索者",
                avatar: nil,
                specialFeature: nil
            ),
            isActive: true,
            validUntil: nil,
            unlockMessage: "🎉 欢迎加入探索者行列！这只是开始！",
            createdAt: Date()
        ),
        
        Badge(
            name: "路线达人",
            description: "累计完成10条不同路线",
            icon: "🏆",
            iconColor: "gold",
            category: .achievement,
            rarity: .rare,
            conditions: BadgeConditions(
                type: .completeRoutesCount,
                target: 10,
                parameters: nil
            ),
            rewards: BadgeRewards(
                experience: 300,
                title: "资深探索者",
                avatar: "explorer_avatar",
                specialFeature: "路线推荐优先级提升"
            ),
            isActive: true,
            validUntil: nil,
            unlockMessage: "🎉 你已成为路线达人！继续探索更多精彩！",
            createdAt: Date()
        ),
        
        // AR导航相关徽章
        Badge(
            name: "AR先锋",
            description: "使用AR导航功能完成首次导航",
            icon: "📱",
            iconColor: "blue",
            category: .achievement,
            rarity: .rare,
            conditions: BadgeConditions(
                type: .arNavigation,
                target: 1,
                parameters: ["type": "first_time"]
            ),
            rewards: BadgeRewards(
                experience: 200,
                title: "AR导航员",
                avatar: "ar_pioneer_avatar",
                specialFeature: "AR导航界面专属主题"
            ),
            isActive: true,
            validUntil: nil,
            unlockMessage: "🎉 你是AR导航的先锋！科技让探索更精彩！",
            createdAt: Date()
        ),
        
        // 社交类徽章
        Badge(
            name: "分享达人",
            description: "分享路线到社交媒体5次",
            icon: "📤",
            iconColor: "purple",
            category: .social,
            rarity: .common,
            conditions: BadgeConditions(
                type: .socialShare,
                target: 5,
                parameters: nil
            ),
            rewards: BadgeRewards(
                experience: 150,
                title: "社交分享者",
                avatar: nil,
                specialFeature: "分享模板解锁"
            ),
            isActive: true,
            validUntil: nil,
            unlockMessage: "🎉 感谢你的分享！让更多人发现美好！",
            createdAt: Date()
        ),
        
        // 季节性徽章
        Badge(
            name: "春意盎然",
            description: "在春季完成5条户外路线",
            icon: "🌸",
            iconColor: "pink",
            category: .seasonal,
            rarity: .rare,
            conditions: BadgeConditions(
                type: .completeRoutesCount,
                target: 5,
                parameters: ["season": "spring", "type": "outdoor"]
            ),
            rewards: BadgeRewards(
                experience: 250,
                title: "春日行者",
                avatar: "spring_avatar",
                specialFeature: "春季专属滤镜"
            ),
            isActive: isSpring(),
            validUntil: nil,
            unlockMessage: "🎉 春天的脚步与你同行！",
            createdAt: Date()
        ),
        
        // 特殊徽章
        Badge(
            name: "创始纪念",
            description: "MemoTree应用早期用户专属纪念徽章",
            icon: "⭐",
            iconColor: "gold",
            category: .special,
            rarity: .legendary,
            conditions: BadgeConditions(
                type: .specificDate,
                target: 1,
                parameters: ["before": "2025-02-01"]
            ),
            rewards: BadgeRewards(
                experience: 1000,
                title: "创始探索者",
                avatar: "founder_avatar",
                specialFeature: "专属金色边框"
            ),
            isActive: true,
            validUntil: nil,
            unlockMessage: "🎉 感谢你成为MemoTree的早期探索者！这份荣耀永远属于你！",
            createdAt: Date()
        )
    ]
    
    private static func isSpring() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month >= 3 && month <= 5
    }
} 