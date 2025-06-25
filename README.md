# MemoTree iOS 应用

MemoTree 是一款基于 SwiftUI 开发的城市漫步探索应用，融合了"小红书+Keep+大众点评"的特色，面向追求松弛生活、注重心理健康的年轻用户。

## 📱 应用特色

- **发现路线**：浏览精选和热门的城市漫步路线
- **地图导航**：使用 MapKit 显示路线和地理位置
- **个人记录**：记录和分享个人的漫步足迹
- **社交互动**：与其他探索者交流心得和建议
- **路线创建**：创建和分享自己的城市探索路线

## 🏗️ 架构设计

### 技术栈
- **SwiftUI**：现代化的用户界面框架
- **Combine**：响应式编程和数据绑定
- **MapKit**：地图和位置服务
- **CoreLocation**：位置管理
- **URLSession**：网络请求

### 项目结构

```
MemoTree/
├── Models/                 # 数据模型
│   ├── User.swift         # 用户模型
│   └── Route.swift        # 路线模型
├── Services/              # 服务层
│   ├── NetworkService.swift   # 网络服务基类
│   ├── AuthService.swift     # 认证服务
│   └── RouteService.swift    # 路线服务
├── Views/                 # 视图层
│   ├── Auth/              # 认证相关视图
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── Discover/          # 发现页面
│   │   └── DiscoverView.swift
│   ├── Map/               # 地图相关
│   │   └── MapView.swift
│   ├── Create/            # 创建路线
│   │   └── CreateRouteView.swift
│   ├── Discuss/           # 交流讨论
│   │   └── DiscussView.swift
│   ├── Profile/           # 个人资料
│   │   └── ProfileView.swift
│   └── MainTabView.swift  # 主标签栏
└── MemoTreeApp.swift      # 应用入口
```

## 🔧 核心功能模块

### 1. 认证系统 (AuthService)
- 用户注册和登录
- JWT 令牌管理
- 自动登录状态检查
- 令牌刷新机制

### 2. 路线服务 (RouteService)
- 获取精选和热门路线
- 基于位置的附近路线查询
- 路线搜索和标签筛选
- 路线点赞、收藏和完成
- 路线评分系统

### 3. 网络服务 (NetworkService)
- 统一的 API 请求管理
- 自动认证头添加
- 错误处理和重试机制
- 文件上传支持

### 4. 用户界面
- **登录/注册**：美观的认证界面
- **发现页面**：精选路线展示和快捷功能
- **地图视图**：集成 MapKit 的路线地图
- **个人资料**：用户信息和统计数据
- **创建页面**：路线创建功能占位符

## 🎨 设计特色

- **现代化 UI**：采用 iOS 原生设计语言
- **绿色主题**：体现健康和自然的品牌形象
- **响应式布局**：适配不同屏幕尺寸
- **流畅动画**：提供优秀的用户体验
- **组件化设计**：可复用的 UI 组件

## 📡 API 集成

应用设计为与后端 Spring Boot API 集成：

- **认证接口**：`/api/auth/*`
- **路线接口**：`/api/routes/*`
- **用户接口**：`/api/user/*`

基础 URL 配置为：`http://localhost:8080/api`

## 🚀 运行项目

1. 确保已安装 Xcode 14.0+
2. 打开 `MemoTree.xcodeproj`
3. 选择 iOS 模拟器或真机
4. 点击运行按钮

## 🔄 后续开发计划

### 即将实现的功能
- [ ] 路线创建和编辑界面
- [ ] 路线详情页面
- [ ] 照片上传和同步
- [ ] 用户设置页面
- [ ] 搜索功能完善
- [ ] 推送通知

### 技术优化
- [ ] 数据缓存机制
- [ ] 离线功能支持
- [ ] 性能优化
- [ ] 单元测试添加
- [ ] UI 测试覆盖

## 🤝 开发团队

此项目为 MemoTree 城市漫步应用的 iOS 客户端，与 Spring Boot 后端协同开发。

---

**注意**：当前版本为开发阶段，某些功能可能仍在完善中。建议在真实设备上测试地图和位置相关功能。 