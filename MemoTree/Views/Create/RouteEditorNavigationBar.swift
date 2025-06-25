//
//  RouteEditorNavigationBar.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

struct RouteEditorNavigationBar: View {
    let currentStep: Int
    let steps: [String]
    let onDismiss: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let canGoNext: Bool
    let isCreating: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 顶部导航栏
            HStack {
                // 关闭按钮
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                }
                
                Spacer()
                
                // 步骤指示器
                Text("第 \(currentStep + 1) 步，共 \(steps.count) 步")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 占位，保持对称
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20) // 状态栏高度
            
            // 进度指示器
            StepProgressIndicator(
                currentStep: currentStep,
                steps: steps
            )
            .padding(.horizontal, 20)
            
            // 导航按钮
            NavigationButtons(
                currentStep: currentStep,
                totalSteps: steps.count,
                onNext: onNext,
                onPrevious: onPrevious,
                canGoNext: canGoNext,
                isCreating: isCreating
            )
            .padding(.horizontal, 20)
        }
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
        .overlay(
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - 步骤进度指示器
struct StepProgressIndicator: View {
    let currentStep: Int
    let steps: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // 进度条
            HStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 0) {
                        // 步骤圆点
                        ZStack {
                            Circle()
                                .fill(stepBackgroundColor(for: index))
                                .frame(width: 24, height: 24)
                            
                            if index < currentStep {
                                // 已完成步骤显示对勾
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else if index == currentStep {
                                // 当前步骤显示数字
                                Text("\(index + 1)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                // 未来步骤显示数字
                                Text("\(index + 1)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // 连接线（除了最后一个步骤）
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? .green : .gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // 步骤标题
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    Text(step)
                        .font(.caption)
                        .fontWeight(index == currentStep ? .semibold : .medium)
                        .foregroundColor(index <= currentStep ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func stepBackgroundColor(for index: Int) -> Color {
        if index < currentStep {
            return .green // 已完成
        } else if index == currentStep {
            return .blue // 当前步骤
        } else {
            return .gray.opacity(0.3) // 未来步骤
        }
    }
}

// MARK: - 导航按钮
struct NavigationButtons: View {
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let canGoNext: Bool
    let isCreating: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 上一步按钮
            if currentStep > 0 {
                Button(action: onPrevious) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("上一步")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                // 占位，保持对称
                Color.clear
                    .frame(height: 44)
            }
            
            Spacer()
            
            // 下一步/创建按钮
            Button(action: onNext) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(nextButtonTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if currentStep < totalSteps - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    (canGoNext && !isCreating) ? .green : .gray,
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .disabled(!canGoNext || isCreating)
            .scaleEffect(isCreating ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCreating)
        }
    }
    
    private var nextButtonTitle: String {
        if isCreating {
            return "创建中..."
        } else if currentStep == totalSteps - 1 {
            return "创建路线"
        } else {
            return "下一步"
        }
    }
}

// MARK: - 预览
#Preview {
    VStack {
        RouteEditorNavigationBar(
            currentStep: 1,
            steps: ["地图编辑", "路线信息", "预览发布"],
            onDismiss: {},
            onNext: {},
            onPrevious: {},
            canGoNext: true,
            isCreating: false
        )
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
} 
