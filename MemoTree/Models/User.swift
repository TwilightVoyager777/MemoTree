//
//  User.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import Foundation

// MARK: - 用户数据模型
struct User: Identifiable, Codable {
    let id: Int64
    let username: String
    let email: String
    let nickname: String?
    let avatar: String?
    let bio: String?
    let location: String?
    
    // 统计数据
    let completedRoutes: Int
    let totalKilometers: Double
    let totalLikes: Int
    let totalFollowers: Int
    let totalFollowing: Int
    
    // 设置信息
    let profileVisibility: ProfileVisibility
    let locationSharingEnabled: Bool
    let photoSyncEnabled: Bool
    let activityStatusVisible: Bool
    
    // 通知设置
    let pushNotificationsEnabled: Bool
    let likeNotificationsEnabled: Bool
    let friendActivityNotificationsEnabled: Bool
    
    let createdAt: String
    let lastLoginAt: String?
}

// MARK: - 枚举定义
enum ProfileVisibility: String, CaseIterable, Codable {
    case `public` = "PUBLIC"
    case `private` = "PRIVATE"
    case friends = "FRIENDS"
    
    var displayName: String {
        switch self {
        case .public: return "公开"
        case .private: return "私密"
        case .friends: return "仅好友"
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "MALE"
    case female = "FEMALE"
    case unknown = "UNKNOWN"
    
    var displayName: String {
        switch self {
        case .male: return "男"
        case .female: return "女"
        case .unknown: return "未知"
        }
    }
}

// MARK: - 认证相关模型
struct LoginRequest: Codable {
    let usernameOrEmail: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let nickname: String?
}

struct AuthResponse: Codable {
    let token: String
    let userId: Int64
    let username: String
    let email: String
    let nickname: String?
    let avatar: String?
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
    let timestamp: Int64?
} 