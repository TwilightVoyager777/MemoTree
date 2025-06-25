//
//  TutorialView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import MapKit

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var animateContent = false
    @State private var showMapPreview = false
    
    private let tutorialSteps: [TutorialStep] = [
        TutorialStep(
            title: "发现探索",
            subtitle: "找到附近有趣的路线",
            description: "浏览精心策划的城市漫步路线，每条路线都有详细的指南和用户评价",
            systemImage: "binoculars.fill",
            backgroundColor: Color.green.opacity(0.1)
        ),
        TutorialStep(
            title: "地图导航",
            subtitle: "跟随路线开始探索",
            description: "使用交互式地图查看路线详情，获取准确的导航指引",
            systemImage: "map.fill",
            backgroundColor: Color.blue.opacity(0.1)
        ),
        TutorialStep(
            title: "记录分享",
            subtitle: "保存美好的探索回忆",
            description: "拍照记录精彩瞬间，与社区分享你的探索体验",
            systemImage: "camera.fill",
            backgroundColor: Color.orange.opacity(0.1)
        ),
        TutorialStep(
            title: "创建路线",
            subtitle: "分享你的发现",
            description: "创建属于自己的探索路线，让更多人体验你发现的美好",
            systemImage: "plus.circle.fill",
            backgroundColor: Color.purple.opacity(0.1)
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.white,
                        Color.green.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部进度指示器
                    VStack(spacing: 16) {
                        HStack {
                            Text("功能教程")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("跳过") {
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                        }
                        
                        // 进度条
                        ProgressView(value: Double(currentStep + 1), total: Double(tutorialSteps.count))
                            .progressViewStyle(CustomProgressViewStyle())
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // 主要内容区域
                    TabView(selection: $currentStep) {
                        ForEach(0..<tutorialSteps.count, id: \.self) { index in
                            TutorialStepView(
                                step: tutorialSteps[index],
                                stepNumber: index + 1,
                                totalSteps: tutorialSteps.count,
                                isActive: currentStep == index
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentStep)
                    
                    // 底部导航按钮
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentStep -= 1
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("上一步")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.green.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        Button(action: {
                            if currentStep < tutorialSteps.count - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentStep += 1
                                }
                            } else {
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentStep == tutorialSteps.count - 1 ? "完成教程" : "下一步")
                                if currentStep < tutorialSteps.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

struct TutorialStep {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let backgroundColor: Color
}

struct TutorialStepView: View {
    let step: TutorialStep
    let stepNumber: Int
    let totalSteps: Int
    let isActive: Bool
    
    @State private var animateImage = false
    @State private var animateText = false
    @State private var showFeatureDemo = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // 步骤指示器
                HStack(spacing: 8) {
                    Text("第 \(stepNumber) 步")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("共 \(totalSteps) 步")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .opacity(animateText ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.2), value: animateText)
                
                // 功能图标和演示
                ZStack {
                    // 背景装饰
                    Circle()
                        .fill(step.backgroundColor)
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateImage ? 1.0 : 0.8)
                        .opacity(animateImage ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: animateImage)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
                        .scaleEffect(animateImage ? 1.0 : 0.9)
                        .opacity(animateImage ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateImage)
                    
                    // 主要图标
                    Image(systemName: step.systemImage)
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateImage ? 1.0 : 0.5)
                        .rotationEffect(.degrees(animateImage ? 0 : -180))
                        .opacity(animateImage ? 1 : 0)
                        .animation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.5), value: animateImage)
                    
                    // 功能演示区域
                    if showFeatureDemo {
                        FeatureDemoView(step: step)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showFeatureDemo.toggle()
                    }
                }
                
                // 文字内容
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text(step.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(animateText ? 1 : 0)
                            .offset(y: animateText ? 0 : 20)
                            .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateText)
                        
                        Text(step.subtitle)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .opacity(animateText ? 1 : 0)
                            .offset(y: animateText ? 0 : 15)
                            .animation(.easeInOut(duration: 0.8).delay(0.6), value: animateText)
                    }
                    
                    Text(step.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 32)
                        .opacity(animateText ? 1 : 0)
                        .offset(y: animateText ? 0 : 10)
                        .animation(.easeInOut(duration: 0.8).delay(0.8), value: animateText)
                    
                    // 互动提示
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                            .foregroundColor(.green.opacity(0.7))
                        
                        Text("点击图标查看功能演示")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(animateText ? 0.8 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(1.0), value: animateText)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                // 重置动画状态
                animateImage = false
                animateText = false
                showFeatureDemo = false
                
                // 启动动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateImage = true
                    animateText = true
                }
            }
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateImage = true
                    animateText = true
                }
            }
        }
    }
}

struct FeatureDemoView: View {
    let step: TutorialStep
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .frame(width: 250, height: 150)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: getDemoIcon())
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text(getDemoText())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding()
            )
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    private func getDemoIcon() -> String {
        switch step.title {
        case "发现探索": return "list.bullet.rectangle"
        case "地图导航": return "location.north.line.fill"
        case "记录分享": return "square.and.arrow.up"
        case "创建路线": return "pencil.and.outline"
        default: return "star.fill"
        }
    }
    
    private func getDemoText() -> String {
        switch step.title {
        case "发现探索": return "浏览精选路线\n查看详细信息"
        case "地图导航": return "实时位置跟踪\n语音导航提示"
        case "记录分享": return "拍照上传\n社区互动"
        case "创建路线": return "自定义路径\n添加兴趣点"
        default: return "功能演示"
        }
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.green.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 8)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    TutorialView()
} 