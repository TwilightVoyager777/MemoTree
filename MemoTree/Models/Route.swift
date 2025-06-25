//
//  Route.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - 路线数据模型
struct Route: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String?
    let creator: User?
    
    // 地理位置信息
    let startLatitude: Double
    let startLongitude: Double
    let endLatitude: Double
    let endLongitude: Double
    let startAddress: String?
    let endAddress: String?
    
    // 路线数据
    let distance: Double
    let estimatedDuration: Int // 分钟
    let difficulty: Difficulty
    let tags: [RouteTag]
    let routePoints: [RoutePoint]?
    
    // 媒体内容
    let coverImage: String?
    
    // 统计数据
    let views: Int
    let likes: Int
    let collections: Int
    let completions: Int
    let averageRating: Double
    let ratingCount: Int
    
    // 状态信息
    let status: RouteStatus
    let isPublic: Bool
    let isFeatured: Bool
    
    let createdAt: String
    let updatedAt: String
    
    // 计算属性
    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }
    
    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }
    
    var formattedDistance: String {
        if distance < 1.0 {
            return String(format: "%.0fm", distance * 1000)
        } else {
            return String(format: "%.1fkm", distance)
        }
    }
    
    var formattedDuration: String {
        let hours = estimatedDuration / 60
        let minutes = estimatedDuration % 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)min"
        }
    }
}

// MARK: - 路线点位模型
struct RoutePoint: Identifiable, Codable {
    let id: Int64?
    let latitude: Double
    let longitude: Double
    let name: String?
    let description: String?
    let imageUrl: String?
    let pointType: PointType
    let order: Int?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 枚举定义
enum Difficulty: String, CaseIterable, Codable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    case expert = "EXPERT"
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .expert: return "专家"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        case .expert: return .purple
        }
    }
}

enum RouteTag: String, CaseIterable, Codable {
    case architecture = "ARCHITECTURE"
    case nature = "NATURE"
    case art = "ART"
    case photography = "PHOTOGRAPHY"
    case food = "FOOD"
    case shopping = "SHOPPING"
    case history = "HISTORY"
    case modern = "MODERN"
    case couple = "COUPLE"
    case family = "FAMILY"
    case friends = "FRIENDS"
    case solo = "SOLO"
    case night = "NIGHT"
    case rainy = "RAINY"
    case sightseeing = "SIGHTSEEING"
    case culture = "CULTURE"
    case temple = "TEMPLE"
    case entertainment = "ENTERTAINMENT"
    case cycling = "CYCLING"
    case nightview = "NIGHTVIEW"
    
    var displayName: String {
        switch self {
        case .architecture: return "建筑美学"
        case .nature: return "自然治愈"
        case .art: return "文艺探索"
        case .photography: return "摄影打卡"
        case .food: return "美食探店"
        case .shopping: return "购物休闲"
        case .history: return "历史文化"
        case .modern: return "现代都市"
        case .couple: return "情侣约会"
        case .family: return "亲子出行"
        case .friends: return "朋友聚会"
        case .solo: return "独自漫步"
        case .night: return "夜晚路线"
        case .rainy: return "雨天路线"
        case .sightseeing: return "观光游览"
        case .culture: return "文化体验"
        case .temple: return "寺庙参拜"
        case .entertainment: return "娱乐休闲"
        case .cycling: return "骑行健身"
        case .nightview: return "夜景观赏"
        }
    }
    
    var icon: String {
        switch self {
        case .architecture: return "building.2"
        case .nature: return "leaf"
        case .art: return "paintbrush"
        case .photography: return "camera"
        case .food: return "fork.knife"
        case .shopping: return "bag"
        case .history: return "building.columns"
        case .modern: return "building.2.crop.circle"
        case .couple: return "heart"
        case .family: return "figure.and.child.holdinghands"
        case .friends: return "person.3"
        case .solo: return "person"
        case .night: return "moon"
        case .rainy: return "cloud.rain"
        case .sightseeing: return "binoculars"
        case .culture: return "theatermasks"
        case .temple: return "building.columns.fill"
        case .entertainment: return "party.popper"
        case .cycling: return "bicycle"
        case .nightview: return "moon.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .architecture: return .blue
        case .nature: return .green
        case .art: return .purple
        case .photography: return .pink
        case .food: return .orange
        case .shopping: return .indigo
        case .history: return .brown
        case .modern: return .cyan
        case .couple: return .red
        case .family: return .mint
        case .friends: return .yellow
        case .solo: return .gray
        case .night: return .indigo
        case .rainy: return .blue
        case .sightseeing: return .teal
        case .culture: return .purple
        case .temple: return .brown
        case .entertainment: return .pink
        case .cycling: return .green
        case .nightview: return .indigo
        }
    }
}

enum PointType: String, CaseIterable, Codable {
    case start = "START"
    case end = "END"
    case waypoint = "WAYPOINT"
    case checkpoint = "CHECKPOINT"
    case rest = "REST"
    case viewpoint = "VIEWPOINT"
    case photo = "PHOTO"
    case food = "FOOD"
    case shop = "SHOP"
    case historic = "HISTORIC"
    case nature = "NATURE"
    
    var displayName: String {
        switch self {
        case .start: return "起点"
        case .end: return "终点"
        case .waypoint: return "路径点"
        case .checkpoint: return "打卡点"
        case .rest: return "休息点"
        case .viewpoint: return "观景点"
        case .photo: return "拍照点"
        case .food: return "美食点"
        case .shop: return "购物点"
        case .historic: return "历史点"
        case .nature: return "自然点"
        }
    }
    
    var icon: String {
        switch self {
        case .start: return "play.circle.fill"
        case .end: return "stop.circle.fill"
        case .waypoint: return "circle"
        case .checkpoint: return "checkmark.circle"
        case .rest: return "bed.double"
        case .viewpoint: return "eye"
        case .photo: return "camera.circle"
        case .food: return "fork.knife.circle"
        case .shop: return "bag.circle"
        case .historic: return "building.columns.circle"
        case .nature: return "leaf.circle"
        }
    }
}

enum RouteStatus: String, Codable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case suspended = "SUSPENDED"
    case deleted = "DELETED"
    case published = "PUBLISHED"
}

// MARK: - 分页模型
struct PagedRoutes: Codable {
    let content: [Route]
    let totalElements: Int
    let totalPages: Int
    let size: Int
    let number: Int
    let first: Bool
    let last: Bool
} 