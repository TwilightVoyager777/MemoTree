//
//  AuthService.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import Foundation
import Combine

// MARK: - 认证服务
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 添加多样化的模拟用户（第四步测试）
    private let mockUsers = [
        // 原有demo用户
        User(
            id: 1,
            username: "explorer",
            email: "demo@example.com",
            nickname: "城市探索者",
            avatar: "avatar_1",
            bio: "喜欢探索城市的每一个角落，发现隐藏的美好",
            location: "上海",
            completedRoutes: 15,
            totalKilometers: 87.5,
            totalLikes: 234,
            totalFollowers: 89,
            totalFollowing: 56,
            profileVisibility: .public,
            locationSharingEnabled: true,
            photoSyncEnabled: true,
            activityStatusVisible: true,
            pushNotificationsEnabled: true,
            likeNotificationsEnabled: true,
            friendActivityNotificationsEnabled: true,
            createdAt: "2024-01-01T00:00:00Z",
            lastLoginAt: "2024-01-15T10:30:00Z"
        ),
        
        // 摄影爱好者
        User(
            id: 2,
            username: "photographer",
            email: "wang@example.com",
            nickname: "镜头下的城市",
            avatar: "avatar_2",
            bio: "摄影爱好者，用镜头记录城市的美好瞬间",
            location: "北京",
            completedRoutes: 28,
            totalKilometers: 156.3,
            totalLikes: 567,
            totalFollowers: 234,
            totalFollowing: 123,
            profileVisibility: .public,
            locationSharingEnabled: true,
            photoSyncEnabled: true,
            activityStatusVisible: true,
            pushNotificationsEnabled: true,
            likeNotificationsEnabled: true,
            friendActivityNotificationsEnabled: true,
            createdAt: "2024-01-02T00:00:00Z",
            lastLoginAt: "2024-01-14T16:20:00Z"
        ),
        
        // 美食探索者
        User(
            id: 3,
            username: "foodie",
            email: "chen@example.com",
            nickname: "美食达人",
            avatar: "avatar_3",
            bio: "寻找城市中的美食宝藏，分享味蕾的感动",
            location: "广州",
            completedRoutes: 22,
            totalKilometers: 98.7,
            totalLikes: 398,
            totalFollowers: 156,
            totalFollowing: 87,
            profileVisibility: .public,
            locationSharingEnabled: true,
            photoSyncEnabled: true,
            activityStatusVisible: true,
            pushNotificationsEnabled: true,
            likeNotificationsEnabled: true,
            friendActivityNotificationsEnabled: true,
            createdAt: "2024-01-03T00:00:00Z",
            lastLoginAt: "2024-01-13T14:15:00Z"
        ),
        
        // 历史文化爱好者
        User(
            id: 4,
            username: "historian",
            email: "history@example.com",
            nickname: "历史文化爱好者",
            avatar: "avatar_4",
            bio: "探索城市的历史文化，传承古老的记忆",
            location: "西安",
            completedRoutes: 35,
            totalKilometers: 203.4,
            totalLikes: 445,
            totalFollowers: 298,
            totalFollowing: 145,
            profileVisibility: .public,
            locationSharingEnabled: true,
            photoSyncEnabled: true,
            activityStatusVisible: true,
            pushNotificationsEnabled: true,
            likeNotificationsEnabled: true,
            friendActivityNotificationsEnabled: true,
            createdAt: "2024-01-04T00:00:00Z",
            lastLoginAt: "2024-01-12T09:45:00Z"
        )
    ]
    
    // 扩展公共访问方法
    var demoUser: User? {
        return mockUsers.first
    }
    
    var allUsers: [User] {
        return mockUsers
    }
    
    func getUserById(_ id: Int64) -> User? {
        return mockUsers.first { $0.id == id }
    }
    
    // MARK: - 用户个性化数据（第四步测试）
    
    // 搜索历史记录
    private let searchHistory = [
        "外滩夜景",
        "豫园美食",
        "田子坊",
        "摄影路线",
        "上海历史建筑",
        "小笼包",
        "咖啡店",
        "艺术画廊"
    ]
    
    // 用户收藏的路线ID
    private let favoriteRouteIds: [Int64] = [1, 3] // 收藏了外滩和田子坊路线
    
    // 已完成的路线ID及完成时间
    private let completedRoutes: [(routeId: Int64, completedAt: String)] = [
        (1, "2024-01-01T14:30:00Z"),
        (2, "2023-12-28T16:20:00Z"),
        (3, "2023-12-25T10:15:00Z")
    ]
    
    // 用户活动记录
    private let activityRecords = [
        "今天完成了外滩滨江步道，走了2.5公里",
        "收藏了田子坊艺术漫步路线",
        "给豫园老街探秘路线点了赞",
        "在社区发布了一条动态",
        "关注了摄影达人镜头下的城市"
    ]
    
    // 获取搜索历史
    func getSearchHistory() -> [String] {
        return searchHistory
    }
    
    // 获取用户收藏的路线ID列表
    func getFavoriteRouteIds() -> [Int64] {
        return favoriteRouteIds
    }
    
    // 获取已完成的路线记录
    func getCompletedRoutes() -> [(routeId: Int64, completedAt: String)] {
        return completedRoutes
    }
    
    // 获取最近活动记录
    func getActivityRecords() -> [String] {
        return activityRecords
    }
    
    // 检查路线是否已收藏
    func isRouteFavorited(_ routeId: Int64) -> Bool {
        return favoriteRouteIds.contains(routeId)
    }
    
    // 检查路线是否已完成
    func isRouteCompleted(_ routeId: Int64) -> Bool {
        return completedRoutes.contains { $0.routeId == routeId }
    }
    
    // 添加搜索记录（实际应用中会保存到本地）
    func addSearchRecord(_ query: String) {
        // TODO: 实际实现中应该保存到UserDefaults或Core Data
        print("添加搜索记录: \(query)")
    }
    
    // 收藏/取消收藏路线
    func toggleRouteFavorite(_ routeId: Int64) -> AnyPublisher<Bool, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private init() {
        checkLoginStatus()
    }
    
    // MARK: - 检查登录状态
    private func checkLoginStatus() {
        isLoggedIn = TokenManager.shared.isLoggedIn()
        
        // 如果已登录，设置模拟用户
        if isLoggedIn {
            loadMockUser()
        }
    }
    
    private func loadMockUser() {
        // 设置第一个模拟用户
        DispatchQueue.main.async {
            self.currentUser = self.mockUsers.first
        }
    }
    
    // MARK: - 用户注册 (返回模拟用户)
    func register(username: String, email: String, password: String, nickname: String?) -> AnyPublisher<Bool, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 注册成功，设置模拟用户
                TokenManager.shared.saveToken("mock_token_\(username)")
                
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                    self.currentUser = self.mockUsers.first
                }
                
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 用户登录 (返回模拟用户)
    func login(usernameOrEmail: String, password: String) -> AnyPublisher<Bool, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // 登录成功，设置模拟用户
                TokenManager.shared.saveToken("mock_token_\(usernameOrEmail)")
                
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                    self.currentUser = self.mockUsers.first
                }
                
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 用户登出
    func logout() {
        TokenManager.shared.removeToken()
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.currentUser = nil
        }
    }
    
    // MARK: - 获取当前用户信息 (空实现)
    private func fetchCurrentUser() {
        // 无用户数据
        loadMockUser()
    }
    
    // MARK: - 刷新令牌 (空实现)
    func refreshToken() -> AnyPublisher<Bool, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.isLoggedIn {
                    promise(.success(true))
                } else {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 工具方法
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - User扩展（基于实际数据）
extension User {
    var routesCreated: Int {
        // 基于完成路线数推算创建的路线
        return max(1, completedRoutes / 3)
    }
    
    var level: Int {
        // 根据完成的路线数量计算等级
        switch completedRoutes {
        case 0...2: return 1
        case 3...7: return 2
        case 8...15: return 3
        case 16...25: return 4
        case 26...40: return 5
        default: return 6
        }
    }
    
    var totalDistance: Double {
        return totalKilometers
    }
    
    var joinDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        if let date = formatter.date(from: createdAt) {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        
        return "2024-01-01"
    }
} 