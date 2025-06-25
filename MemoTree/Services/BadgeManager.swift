//
//  BadgeManager.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import Foundation
import Combine

class BadgeManager: ObservableObject {
    static let shared = BadgeManager()
    
    @Published var userBadges: [Badge] = []
    @Published var badgeProgress: [UUID: UserBadgeProgress] = [:]
    @Published var recentlyUnlocked: [Badge] = []
    @Published var showBadgeAlert = false
    @Published var newBadge: Badge?
    
    private let userDefaults = UserDefaults.standard
    private let badgeStorageKey = "user_badges"
    private let progressStorageKey = "badge_progress"
    
    // 用户统计数据
    @Published var userStats = UserStats()
    
    private init() {
        loadBadgeData()
        initializeAvailableBadges()
        // 初始化特定徽章为已解锁状态
        initializeDefaultUnlockedBadges()
        checkForNewBadges()
    }
    
    // MARK: - 数据加载和保存
    private func loadBadgeData() {
        // 加载已解锁徽章
        if let data = userDefaults.data(forKey: badgeStorageKey),
           let badges = try? JSONDecoder().decode([Badge].self, from: data) {
            userBadges = badges
        }
        
        // 加载徽章进度
        if let data = userDefaults.data(forKey: progressStorageKey),
           let progress = try? JSONDecoder().decode([UUID: UserBadgeProgress].self, from: data) {
            badgeProgress = progress
        }
        
        // 加载用户统计
        loadUserStats()
    }
    
    private func saveBadgeData() {
        // 保存已解锁徽章
        if let data = try? JSONEncoder().encode(userBadges) {
            userDefaults.set(data, forKey: badgeStorageKey)
        }
        
        // 保存徽章进度
        if let data = try? JSONEncoder().encode(badgeProgress) {
            userDefaults.set(data, forKey: progressStorageKey)
        }
        
        // 保存用户统计
        saveUserStats()
    }
    
    private func initializeAvailableBadges() {
        // 为所有预设徽章初始化进度跟踪
        for badge in BadgePresets.allBadges {
            if badgeProgress[badge.id] == nil {
                badgeProgress[badge.id] = UserBadgeProgress(
                    badgeId: badge.id,
                    currentProgress: 0,
                    completedAt: nil,
                    lastUpdated: Date()
                )
            }
        }
        saveBadgeData()
    }
    
    // MARK: - 初始化默认解锁徽章
    private func initializeDefaultUnlockedBadges() {
        let defaultUnlockedNames = ["端午安康", "路线达人", "AR先锋"]
        
        for badgeName in defaultUnlockedNames {
            // 检查是否已经解锁过
            if !userBadges.contains(where: { $0.name == badgeName }) {
                // 从预设徽章中找到对应的徽章
                if let badge = BadgePresets.allBadges.first(where: { $0.name == badgeName }) {
                    unlockBadgeDirectly(badge)
                }
            }
        }
    }
    
    // MARK: - 直接解锁徽章（无需检查条件）
    private func unlockBadgeDirectly(_ badge: Badge) {
        var unlockedBadge = badge
        unlockedBadge.unlockedAt = Date()
        
        userBadges.append(unlockedBadge)
        
        // 更新进度
        badgeProgress[badge.id]?.completedAt = Date()
        badgeProgress[badge.id]?.currentProgress = badge.conditions.target
        badgeProgress[badge.id]?.lastUpdated = Date()
        
        // 应用奖励
        if let rewards = badge.rewards {
            userStats.experience += rewards.experience
            
            if let title = rewards.title {
                userStats.earnedTitles.append(title)
            }
        }
        
        saveBadgeData()
        
        print("🏆 徽章直接解锁: \(badge.name)")
    }
    
    // MARK: - 徽章检查和解锁
    func checkForNewBadges() {
        var newlyUnlocked: [Badge] = []
        
        for badge in BadgePresets.allBadges {
            // 跳过已解锁的徽章
            if userBadges.contains(where: { $0.id == badge.id }) {
                continue
            }
            
            // 检查是否满足解锁条件
            if checkBadgeCondition(badge) {
                unlockBadge(badge)
                newlyUnlocked.append(badge)
            }
        }
        
        if !newlyUnlocked.isEmpty {
            recentlyUnlocked.append(contentsOf: newlyUnlocked)
            // 显示第一个新徽章的提醒
            if let firstBadge = newlyUnlocked.first {
                newBadge = firstBadge
                showBadgeAlert = true
            }
        }
    }
    
    private func checkBadgeCondition(_ badge: Badge) -> Bool {
        // 检查徽章是否在有效期内
        if let validUntil = badge.validUntil, Date() > validUntil {
            return false
        }
        
        // 检查徽章是否激活
        guard badge.isActive else { return false }
        
        switch badge.conditions.type {
        case .completeRoutesCount:
            return userStats.completedRoutes >= badge.conditions.target
            
        case .walkDistance:
            return userStats.totalDistance >= Double(badge.conditions.target)
            
        case .visitLocations:
            return userStats.visitedLocations >= badge.conditions.target
            
        case .socialShare:
            return userStats.socialShares >= badge.conditions.target
            
        case .arNavigation:
            if badge.conditions.parameters?["type"] == "first_time" {
                return userStats.arNavigationUsed >= 1
            }
            return userStats.arNavigationUsed >= badge.conditions.target
            
        case .consecutiveDays:
            return userStats.consecutiveDays >= badge.conditions.target
            
        case .photoTaken:
            return userStats.photosTaken >= badge.conditions.target
            
        case .festivalActivity:
            return checkFestivalActivity(badge)
            
        case .specificDate:
            return checkSpecificDateCondition(badge)
            
        case .completeOfficialRoute:
            return checkOfficialRouteCondition(badge)
        }
    }
    
    private func checkFestivalActivity(_ badge: Badge) -> Bool {
        guard let festival = badge.conditions.parameters?["festival"] else { return false }
        
        switch festival {
        case "dragon_boat":
            // 端午节活动：需要完成官方端午主题路线
            return userStats.completedFestivalRoutes["dragon_boat"] ?? 0 >= badge.conditions.target
        default:
            return false
        }
    }
    
    private func checkSpecificDateCondition(_ badge: Badge) -> Bool {
        guard let beforeDateString = badge.conditions.parameters?["before"],
              let beforeDate = DateFormatter.iso8601.date(from: beforeDateString) else {
            return false
        }
        
        // 检查用户注册时间是否在指定日期之前
        return userStats.registrationDate < beforeDate
    }
    
    private func checkOfficialRouteCondition(_ badge: Badge) -> Bool {
        // 检查是否完成了官方路线
        return userStats.completedOfficialRoutes >= badge.conditions.target
    }
    
    private func unlockBadge(_ badge: Badge) {
        var unlockedBadge = badge
        unlockedBadge.unlockedAt = Date()
        
        userBadges.append(unlockedBadge)
        
        // 更新进度
        badgeProgress[badge.id]?.completedAt = Date()
        badgeProgress[badge.id]?.currentProgress = badge.conditions.target
        badgeProgress[badge.id]?.lastUpdated = Date()
        
        // 应用奖励
        if let rewards = badge.rewards {
            userStats.experience += rewards.experience
            
            if let title = rewards.title {
                userStats.earnedTitles.append(title)
            }
        }
        
        saveBadgeData()
        
        print("🏆 徽章解锁: \(badge.name)")
    }
    
    // MARK: - 用户行为记录
    func recordRouteCompletion(isOfficial: Bool = false, routeType: String? = nil, festivalType: String? = nil) {
        userStats.completedRoutes += 1
        
        if isOfficial {
            userStats.completedOfficialRoutes += 1
        }
        
        if let festival = festivalType {
            userStats.completedFestivalRoutes[festival, default: 0] += 1
        }
        
        updateConsecutiveDays()
        saveBadgeData()
        checkForNewBadges()
    }
    
    func recordWalkDistance(_ distance: Double) {
        userStats.totalDistance += distance
        saveBadgeData()
        checkForNewBadges()
    }
    
    func recordLocationVisit() {
        userStats.visitedLocations += 1
        saveBadgeData()
        checkForNewBadges()
    }
    
    func recordSocialShare() {
        userStats.socialShares += 1
        saveBadgeData()
        checkForNewBadges()
    }
    
    func recordARNavigation() {
        userStats.arNavigationUsed += 1
        saveBadgeData()
        checkForNewBadges()
    }
    
    func recordPhotoTaken() {
        userStats.photosTaken += 1
        saveBadgeData()
        checkForNewBadges()
    }
    
    private func updateConsecutiveDays() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastActiveDay = userStats.lastActiveDay {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            
            if Calendar.current.isDate(lastActiveDay, inSameDayAs: yesterday) {
                // 连续的一天
                userStats.consecutiveDays += 1
            } else if !Calendar.current.isDate(lastActiveDay, inSameDayAs: today) {
                // 中断了，重新开始
                userStats.consecutiveDays = 1
            }
        } else {
            // 第一天
            userStats.consecutiveDays = 1
        }
        
        userStats.lastActiveDay = today
    }
    
    // MARK: - 徽章信息获取
    func getAvailableBadges() -> [Badge] {
        return BadgePresets.allBadges.filter { badge in
            // 过滤掉已解锁的徽章
            !userBadges.contains(where: { $0.id == badge.id })
        }
    }
    
    func getBadgesByCategory(_ category: BadgeCategory) -> [Badge] {
        return BadgePresets.allBadges.filter { $0.category == category }
    }
    
    func getUnlockedBadgesByCategory(_ category: BadgeCategory) -> [Badge] {
        return userBadges.filter { $0.category == category }
    }
    
    func getBadgeProgress(_ badgeId: UUID) -> Double {
        guard let progress = badgeProgress[badgeId],
              let badge = BadgePresets.allBadges.first(where: { $0.id == badgeId }) else {
            return 0
        }
        
        return Double(progress.currentProgress) / Double(badge.conditions.target)
    }
    
    func dismissBadgeAlert() {
        showBadgeAlert = false
        newBadge = nil
    }
    
    // MARK: - 用户统计数据
    private func loadUserStats() {
        if let data = userDefaults.data(forKey: "user_stats"),
           let stats = try? JSONDecoder().decode(UserStats.self, from: data) {
            userStats = stats
        } else {
            // 首次使用，设置注册时间
            userStats.registrationDate = Date()
        }
    }
    
    private func saveUserStats() {
        if let data = try? JSONEncoder().encode(userStats) {
            userDefaults.set(data, forKey: "user_stats")
        }
    }
}

// MARK: - 用户统计数据模型
struct UserStats: Codable {
    var completedRoutes: Int = 0
    var completedOfficialRoutes: Int = 0
    var completedFestivalRoutes: [String: Int] = [:]
    var totalDistance: Double = 0
    var visitedLocations: Int = 0
    var socialShares: Int = 0
    var arNavigationUsed: Int = 0
    var photosTaken: Int = 0
    var consecutiveDays: Int = 0
    var experience: Int = 0
    var earnedTitles: [String] = []
    var registrationDate: Date = Date()
    var lastActiveDay: Date?
}

// MARK: - 扩展DateFormatter
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
} 