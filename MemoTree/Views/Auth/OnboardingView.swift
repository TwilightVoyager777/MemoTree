//
//  OnboardingView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasShownOnboarding") private var hasShownOnboarding = false
    @State private var currentPage = 0
    @State private var animateContent = false
    @State private var showTutorial = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "探索城市漫步",
            subtitle: "发现身边的美好路线",
            description: "与朋友一起探索城市中的隐藏宝藏，记录每一次精彩的漫步体验",
            imageName: "onboarding1",
            backgroundColor: Color.green.opacity(0.3)
        ),
        OnboardingPage(
            title: "分享美好时光",
            subtitle: "记录每一次探索之旅",
            description: "拍照记录，分享心得，与更多探索者一起发现城市的魅力",
            imageName: "onboarding3",
            backgroundColor: Color.green.opacity(0.5)
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.8, blue: 0.4),  // 浅绿色
                    Color(red: 0.2, green: 0.7, blue: 0.3),  // 中绿色
                    Color(red: 0.1, green: 0.6, blue: 0.2)   // 深绿色
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            isActive: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // 底部控制区域
                VStack(spacing: 24) {
                    // 自定义页面指示器
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? .white : .white.opacity(0.5))
                                .frame(width: currentPage == index ? 12 : 8, 
                                       height: currentPage == index ? 12 : 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                        }
                    }
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentPage -= 1
                                }
                            }) {
                                Text("上一步")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 80, height: 48)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        Spacer()
                        
                        // 教程按钮（在最后一页显示）
                        if currentPage == pages.count - 1 {
                            Button(action: {
                                showTutorial = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "book.fill")
                                    Text("查看教程")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                                .frame(width: 110, height: 48)
                                .background(.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(.green.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                        
                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            } else {
                                // 完成引导
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    hasShownOnboarding = true
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage == pages.count - 1 ? "开始探索" : "下一步")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if currentPage < pages.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: currentPage == pages.count - 1 ? 120 : 100, height: 48)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var animateImage = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 40) {
            // 插图区域
            ZStack {
                // 装饰性圆形背景
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .scaleEffect(animateImage ? 1.0 : 0.8)
                    .opacity(animateImage ? 1 : 0)
                    .animation(.easeInOut(duration: 1.2).delay(0.2), value: animateImage)
                
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 320, height: 320)
                    .scaleEffect(animateImage ? 1.0 : 0.9)
                    .opacity(animateImage ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(0.4), value: animateImage)
                
                // 人物插图（使用SF Symbols作为占位符）
                ZStack {
                    // 背景装饰
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.15))
                        .frame(width: 200, height: 240)
                        .rotationEffect(.degrees(-5))
                    
                    VStack(spacing: 16) {
                        // 主要图标
                        Image(systemName: getSystemImageName())
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .white.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 装饰性小图标
                        HStack(spacing: 12) {
                            ForEach(getDecorationIcons(), id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .scaleEffect(animateImage ? 1.0 : 0.7)
                .rotationEffect(.degrees(animateImage ? 0 : -10))
                .opacity(animateImage ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animateImage)
            }
            
            // 文字内容
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)
                    .animation(.easeInOut(duration: 0.8).delay(0.5), value: animateText)
                
                Text(page.subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 15)
                    .animation(.easeInOut(duration: 0.8).delay(0.7), value: animateText)
                
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 10)
                    .animation(.easeInOut(duration: 0.8).delay(0.9), value: animateText)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .onChange(of: isActive) { newValue in
            if newValue {
                animateImage = true
                animateText = true
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
    
    private func getSystemImageName() -> String {
        switch page.title {
        case "探索城市漫步":
            return "figure.walk.circle"
        case "分享美好时光":
            return "camera.circle"
        default:
            return "star.circle"
        }
    }
    
    private func getDecorationIcons() -> [String] {
        switch page.title {
        case "探索城市漫步":
            return ["location.fill", "heart.fill", "star.fill"]
        case "分享美好时光":
            return ["photo.fill", "message.fill", "hand.thumbsup.fill"]
        default:
            return ["star.fill", "heart.fill", "location.fill"]
        }
    }
}

// 为了支持自定义颜色，创建颜色扩展
extension Color {
    static let onboardingGreen1 = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let onboardingGreen2 = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let onboardingGreen3 = Color(red: 0.1, green: 0.6, blue: 0.2)
}

#Preview {
    OnboardingView()
} 