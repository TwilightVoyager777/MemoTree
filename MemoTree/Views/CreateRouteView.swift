//
//  CreateRouteView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import CoreLocation

struct CreateRouteView: View {
    @State private var animateTitle = false
    @State private var animateButton = false
    @State private var showingQuickCreate = false
    @State private var showingSmartRecommendations = false
    @State private var showingARNavigation = false
    @State private var showingARScan = false
    
    var body: some View {
        NavigationView {
            // 主要内容
            ScrollView(.vertical) {
                VStack(spacing: 32) {
                    // 头部标题区域
                    VStack(spacing: 16) {
                        // 动画图标
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(animateTitle ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateTitle)
                            
                            Image(systemName: "map.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 8) {
                            Text("创建专属路线")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("分享你的探索路线，让更多人发现城市之美")
                                .font(.subheadline)
                                .foregroundColor(Color.compatibleTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .onAppear {
                        animateTitle = true
                    }
                    
                    // 快速创建选项
                    VStack(spacing: 16) {
                        Text("快速开始")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            QuickCreateButton(
                                icon: "figure.walk",
                                title: "徒步路线",
                                color: .green
                            ) {
                                showingQuickCreate = true
                            }
                            
                            QuickCreateButton(
                                icon: "bicycle",
                                title: "骑行路线",
                                color: .blue
                            ) {
                                showingQuickCreate = true
                            }
                        }
                        
                        HStack(spacing: 16) {
                            QuickCreateButton(
                                icon: "camera.fill",
                                title: "摄影路线",
                                color: .purple
                            ) {
                                showingQuickCreate = true
                            }
                            
                            QuickCreateButton(
                                icon: "fork.knife",
                                title: "美食路线",
                                color: .orange
                            ) {
                                showingQuickCreate = true
                            }
                        }
                        
                        HStack(spacing: 16) {
                            // AR导航按钮
                            QuickCreateButton(
                                icon: "arkit",
                                title: "AR导航体验",
                                color: .cyan
                            ) {
                                showingARNavigation = true
                            }
                            
                            // AR景点识别按钮
                            QuickCreateButton(
                                icon: "camera.viewfinder",
                                title: "AR景点识别",
                                color: .indigo
                            ) {
                                showingARScan = true
                            }
                        }
                    }
                    .padding(20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // 创建引导卡片
                    VStack(spacing: 16) {
                        Text("创建步骤")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        CreateGuideStep(
                            stepNumber: 1,
                            title: "选择路线类型",
                            description: "徒步、骑行、摄影或美食路线"
                        )
                        CreateGuideStep(
                            stepNumber: 2,
                            title: "标记关键点位",
                            description: "在地图上添加起点、途经点和终点"
                        )
                        CreateGuideStep(
                            stepNumber: 3,
                            title: "完善路线信息",
                            description: "添加标题、描述和推荐标签"
                        )
                        CreateGuideStep(
                            stepNumber: 4,
                            title: "发布分享",
                            description: "设置隐私选项并分享给其他探索者"
                        )
                    }
                    .padding(20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // 开始创建按钮
                    NavigationLink(destination: RouteEditorView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("开始创建路线")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .scaleEffect(animateButton ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: animateButton)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            animateButton = true
                        }
                    }
                    
                    // 我的草稿
                    RecentDraftsSection()
                    
                    // 底部间距
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("创建路线")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button(action: {
                    showingSmartRecommendations = true
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        

                    }
                }
            )
            .sheet(isPresented: $showingSmartRecommendations) {
                SmartRecommendationModal()
            }
            .sheet(isPresented: $showingARNavigation) {
                DestinationSelectionView()
            }
            .sheet(isPresented: $showingARScan) {
                ARScannerView()
            }
        }
    }
}

// MARK: - 快速创建按钮
struct QuickCreateButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 创建步骤引导
struct CreateGuideStep: View {
    let stepNumber: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 步骤号码
            ZStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(stepNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 最近草稿部分
struct RecentDraftsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("我的草稿")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("查看全部") {
                    // TODO: 实现查看全部草稿
                }
                .font(.subheadline)
                .foregroundColor(.green)
            }
            
            if hasDrafts {
                // 显示草稿列表
                ForEach(draftRoutes, id: \.id) { draft in
                    DraftRouteCard(draft: draft)
                }
            } else {
                // 空状态
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.5))
                    
                    Text("暂无草稿")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("创建的路线会自动保存为草稿")
                        .font(.caption)
                        .foregroundColor(Color.compatibleTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var hasDrafts: Bool {
        !draftRoutes.isEmpty
    }
    
    private var draftRoutes: [DraftRoute] {
        // TODO: 从本地存储或服务器获取草稿
        []
    }
}

// MARK: - 草稿路线卡片
struct DraftRouteCard: View {
    let draft: DraftRoute
    
    var body: some View {
        HStack(spacing: 12) {
            // 路线图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "map")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.name.isEmpty ? "未命名路线" : draft.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("编辑于 \(formatDate(draft.lastModified))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(draft.pointsCount) 个点位")
                    .font(.caption)
                    .foregroundColor(Color.compatibleTertiary)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: 继续编辑草稿
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 草稿路线模型
struct DraftRoute: Identifiable {
    let id = UUID()
    let name: String
    let lastModified: Date
    let pointsCount: Int
}

// MARK: - 智能推荐模态窗口
struct SmartRecommendationModal: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var currentRecommendationIndex = 0
    @State private var showDetailedSuggestions = false
    
    // 基于用户偏好的定制推荐
    private let customizationRecommendations = [
        CustomizationRecommendation(
            icon: "🎯",
            title: "专属路线推荐",
            description: "基于你的偏好智能生成",
            suggestions: [
                "推荐距离: 2.5km (符合你的步行偏好)",
                "推荐时长: 90分钟 (适合午后时光)",
                "景点密度: 每500m一个打卡点",
                "路线类型: 历史文化 + 咖啡休憩"
            ]
        ),
        CustomizationRecommendation(
            icon: "📍",
            title: "智能点位建议",
            description: "AI 分析最佳打卡位置",
            suggestions: [
                "起点建议: 地铁站附近 (交通便利)",
                "途径推荐: 3个文化景点 + 2个咖啡店",
                "最佳拍摄点: 4个高分摄影位置",
                "终点建议: 美食街区 (完美收尾)"
            ]
        ),
        CustomizationRecommendation(
            icon: "⏰",
            title: "最佳时间规划",
            description: "基于你的活跃时段优化",
            suggestions: [
                "推荐出发时间: 下午 2:30",
                "各点位停留时长已优化",
                "避开人流高峰时段",
                "赶上最佳光线时机 📸"
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 头部标题
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .scaleEffect(animateContent ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateContent)
                            }
                            
                            VStack(spacing: 8) {
                                Text("🧠 智能定制推荐")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("AI 为你量身打造最适合的路线")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
                        
                        // 推荐内容卡片
                        VStack(spacing: 20) {
                            ForEach(Array(customizationRecommendations.enumerated()), id: \.offset) { index, recommendation in
                                RecommendationCard(
                                    recommendation: recommendation,
                                    animationDelay: Double(index) * 0.2
                                )
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
                        
                        // 匹配度展示
                        MatchScoreCard()
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
                        
                        // 应用按钮
                        Button(action: {
                            // TODO: 应用推荐设置
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("应用这些推荐")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
                        
                        // 底部间距
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("智能定制")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") { dismiss() })
        }
        .onAppear {
            animateContent = true
        }
    }
}

// MARK: - 推荐卡片
struct RecommendationCard: View {
    let recommendation: CustomizationRecommendation
    let animationDelay: Double
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 卡片头部
            HStack(spacing: 12) {
                Text(recommendation.icon)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 建议列表
            VStack(spacing: 8) {
                ForEach(Array(recommendation.suggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 6, height: 6)
                        
                        Text(suggestion)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .opacity(animate ? 1 : 0)
                    .offset(x: animate ? 0 : -20)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: animate)
                }
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .scaleEffect(animate ? 1 : 0.95)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(animationDelay)) {
                animate = true
            }
        }
    }
}

// MARK: - 匹配度卡片
struct MatchScoreCard: View {
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎯 个性化匹配度")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("基于你的 15 次探索数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("94%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            ProgressView(value: animateProgress ? 0.94 : 0.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                .scaleEffect(y: 2.0)
                .animation(.easeOut(duration: 1.5).delay(0.5), value: animateProgress)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("成功率预测")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("96%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("85%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            animateProgress = true
        }
    }
}

struct CustomizationRecommendation {
    let icon: String
    let title: String
    let description: String
    let suggestions: [String]
}

#Preview {
    CreateRouteView()
} 
