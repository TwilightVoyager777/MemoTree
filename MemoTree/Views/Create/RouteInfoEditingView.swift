//
//  RouteInfoEditingView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI

struct RouteInfoEditingView: View {
    @Binding var routeName: String
    @Binding var routeDescription: String
    @Binding var selectedDifficulty: Difficulty
    @Binding var selectedTags: Set<RouteTag>
    @Binding var estimatedDuration: Int
    @Binding var isPublic: Bool
    
    @State private var animateContent = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 路线名称
                RouteNameSection(routeName: $routeName)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateContent)
                
                // 路线描述
                RouteDescriptionSection(routeDescription: $routeDescription)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateContent)
                
                // 难度选择
                DifficultySelectionSection(selectedDifficulty: $selectedDifficulty)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animateContent)
                
                // 标签选择
                TagSelectionSection(selectedTags: $selectedTags)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateContent)
                
                // 时长设置
                DurationSettingSection(estimatedDuration: $estimatedDuration)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: animateContent)
                
                // 隐私设置
                PrivacySettingSection(isPublic: $isPublic)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateContent)
                
                // 底部间距
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 180) // 为顶部导航预留足够空间
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
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}

// MARK: - 路线名称部分
struct RouteNameSection: View {
    @Binding var routeName: String
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("路线名称", systemImage: "pencil.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("给你的路线起个有趣的名字...", text: $routeName)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isNameFocused ? .green : .clear, lineWidth: 2)
                    )
                    .focused($isNameFocused)
                
                Text("建议包含地点或主题，让别人一眼就能了解这条路线")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 路线描述部分
struct RouteDescriptionSection: View {
    @Binding var routeDescription: String
    @FocusState private var isDescriptionFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("路线描述", systemImage: "text.alignleft.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if routeDescription.isEmpty {
                        Text("描述这条路线的特色、适合的人群、最佳游览时间等...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $routeDescription)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isDescriptionFocused ? .green : .clear, lineWidth: 2)
                        )
                        .frame(minHeight: 80)
                        .focused($isDescriptionFocused)
                }
                
                HStack {
                    Text("字数: \(routeDescription.count)/500")
                        .font(.caption)
                        .foregroundColor(routeDescription.count > 500 ? .red : .secondary)
                    
                    Spacer()
                    
                    if routeDescription.count > 50 {
                        Text("✓ 描述充分")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 难度选择部分
struct DifficultySelectionSection: View {
    @Binding var selectedDifficulty: Difficulty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("难度等级", systemImage: "speedometer.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Difficulty.allCases, id: \.rawValue) { difficulty in
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        onTap: {
                            selectedDifficulty = difficulty
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct DifficultyCard: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(difficulty.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: difficultyIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(difficulty.color)
                }
                
                Text(difficulty.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(difficultyDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? difficulty.color.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? difficulty.color : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var difficultyIcon: String {
        switch difficulty {
        case .easy: return "tortoise.fill"
        case .medium: return "hare.fill"
        case .hard: return "figure.run"
        case .expert: return "bolt.fill"
        }
    }
    
    private var difficultyDescription: String {
        switch difficulty {
        case .easy: return "轻松漫步\n适合所有人"
        case .medium: return "中等强度\n需要一定体力"
        case .hard: return "挑战性强\n需要良好体力"
        case .expert: return "专业级别\n经验丰富者"
        }
    }
}

// MARK: - 标签选择部分
struct TagSelectionSection: View {
    @Binding var selectedTags: Set<RouteTag>
    
    let tagCategories: [(String, [RouteTag])] = [
        ("主题类型", [.architecture, .nature, .art, .photography, .food, .shopping]),
        ("历史文化", [.history, .culture, .temple]),
        ("出行方式", [.cycling, .solo, .couple, .family, .friends]),
        ("时间场景", [.night, .rainy, .nightview])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("路线标签", systemImage: "tag.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("已选 \(selectedTags.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1), in: Capsule())
            }
            
            ForEach(tagCategories, id: \.0) { category, tags in
                TagCategoryView(
                    categoryName: category,
                    tags: tags,
                    selectedTags: $selectedTags
                )
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct TagCategoryView: View {
    let categoryName: String
    let tags: [RouteTag]
    @Binding var selectedTags: Set<RouteTag>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(categoryName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            FlowLayout(tags) { tag in
                TagChip(
                    tag: tag,
                    isSelected: selectedTags.contains(tag),
                    onTap: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                )
            }
        }
    }
}

struct TagChip: View {
    let tag: RouteTag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.caption)
                
                Text(tag.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? .green : .gray.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : .gray.opacity(0.3), lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - 时长设置部分
struct DurationSettingSection: View {
    @Binding var estimatedDuration: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("预估时长", systemImage: "clock.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("预计需要时间")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatDuration(estimatedDuration))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Slider(
                    value: Binding(
                        get: { Double(estimatedDuration) },
                        set: { estimatedDuration = Int($0) }
                    ),
                    in: 15...480, // 15分钟到8小时
                    step: 15
                ) {
                    Text("时长")
                } minimumValueLabel: {
                    Text("15m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("8h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.green)
                
                HStack {
                    ForEach([30, 60, 120, 180], id: \.self) { duration in
                        Button(action: {
                            estimatedDuration = duration
                        }) {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(estimatedDuration == duration ? .white : .green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(estimatedDuration == duration ? .green : .green.opacity(0.1))
                                )
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return mins > 0 ? "\(hours)h\(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - 隐私设置部分
struct PrivacySettingSection: View {
    @Binding var isPublic: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("隐私设置", systemImage: "lock.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PrivacyOption(
                    icon: "globe",
                    title: "公开路线",
                    description: "所有人都可以看到和使用这条路线",
                    isSelected: isPublic,
                    onTap: { isPublic = true }
                )
                
                PrivacyOption(
                    icon: "lock",
                    title: "私人路线",
                    description: "只有你自己可以看到这条路线",
                    isSelected: !isPublic,
                    onTap: { isPublic = false }
                )
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct PrivacyOption: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? .green.opacity(0.2) : .gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .green : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .green.opacity(0.05) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .green : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
    RouteInfoEditingView(
        routeName: .constant(""),
        routeDescription: .constant(""),
        selectedDifficulty: .constant(.easy),
        selectedTags: .constant([]),
        estimatedDuration: .constant(60),
        isPublic: .constant(true)
    )
} 