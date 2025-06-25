//
//  DestinationSelectionView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI
import CoreLocation
import MapKit

struct DestinationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDestination: DestinationOption?
    @State private var customDestinationName = ""
    @State private var showingARNavigation = false
    @State private var showingCustomInput = false
    
    // 预设目的地选项
    let presetDestinations = [
        DestinationOption(
            name: "义乌国际商贸城",
            subtitle: "全球最大的小商品批发市场",
            coordinate: CLLocationCoordinate2D(latitude: 29.3067, longitude: 120.0763),
            icon: "building.2.fill",
            color: .blue
        ),
        DestinationOption(
            name: "义乌火车站",
            subtitle: "义乌交通枢纽",
            coordinate: CLLocationCoordinate2D(latitude: 29.3019, longitude: 120.0739),
            icon: "tram.fill",
            color: .green
        ),
        DestinationOption(
            name: "义乌机场",
            subtitle: "义乌民用机场",
            coordinate: CLLocationCoordinate2D(latitude: 29.3456, longitude: 120.0319),
            icon: "airplane",
            color: .orange
        ),
        DestinationOption(
            name: "天安门广场",
            subtitle: "北京市中心地标",
            coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            icon: "building.columns.fill",
            color: .red
        ),
        DestinationOption(
            name: "外滩",
            subtitle: "上海黄浦江畔",
            coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            icon: "water.waves",
            color: .cyan
        ),
        DestinationOption(
            name: "西湖",
            subtitle: "杭州著名景点",
            coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
            icon: "mountain.2.fill",
            color: .green
        ),
        DestinationOption(
            name: "广州塔",
            subtitle: "广州地标建筑",
            coordinate: CLLocationCoordinate2D(latitude: 23.1051, longitude: 113.3247),
            icon: "antenna.radiowaves.left.and.right",
            color: .orange
        ),
        DestinationOption(
            name: "深圳华强北",
            subtitle: "中国电子第一街",
            coordinate: CLLocationCoordinate2D(latitude: 22.5455, longitude: 114.0883),
            icon: "laptopcomputer",
            color: .purple
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题区域
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text("选择目的地")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    Text("选择一个目的地开始AR实景导航")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 预设目的地列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(presetDestinations, id: \.name) { destination in
                            DestinationCard(
                                destination: destination,
                                isSelected: selectedDestination?.name == destination.name
                            ) {
                                selectedDestination = destination
                                print("🎯 选择目的地: \(destination.name)")
                            }
                        }
                        
                        // 自定义目的地卡片
                        CustomDestinationCard(
                            isSelected: showingCustomInput,
                            customName: $customDestinationName
                        ) {
                            showingCustomInput.toggle()
                            if showingCustomInput {
                                selectedDestination = nil
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 底部按钮
                VStack(spacing: 16) {
                    Button(action: startARNavigation) {
                        HStack {
                            Image(systemName: "arkit")
                                .font(.title2)
                            
                            Text("开始AR导航")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .disabled(!canStartNavigation)
                        .opacity(canStartNavigation ? 1.0 : 0.6)
                    }
                    
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingARNavigation) {
            if let destination = finalDestination {
                ARNavigationView(
                    destination: destination.coordinate,
                    destinationName: destination.name
                )
            }
        }
    }
    
    private var canStartNavigation: Bool {
        if let _ = selectedDestination {
            return true
        }
        if showingCustomInput && !customDestinationName.trim().isEmpty {
            return true
        }
        return false
    }
    
    private var finalDestination: DestinationOption? {
        if let selected = selectedDestination {
            return selected
        }
        
        if showingCustomInput && !customDestinationName.trim().isEmpty {
            // 自定义目的地，使用义乌国际商贸城作为默认坐标
            return DestinationOption(
                name: customDestinationName.trim(),
                subtitle: "自定义目的地",
                coordinate: CLLocationCoordinate2D(latitude: 29.3067, longitude: 120.0763),
                icon: "location.fill",
                color: .purple
            )
        }
        
        return nil
    }
    
    private func startARNavigation() {
        guard canStartNavigation else { return }
        print("🚀 启动AR导航到: \(finalDestination?.name ?? "未知")")
        showingARNavigation = true
    }
}

// MARK: - 目的地选项数据模型
struct DestinationOption {
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let icon: String
    let color: Color
}

// MARK: - 目的地卡片
struct DestinationCard: View {
    let destination: DestinationOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(destination.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: destination.icon)
                        .font(.title2)
                        .foregroundColor(destination.color)
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(destination.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("纬度: \(String(format: "%.4f", destination.coordinate.latitude))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("经度: \(String(format: "%.4f", destination.coordinate.longitude))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 选择指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blue : Color(.separator), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 自定义目的地卡片
struct CustomDestinationCard: View {
    let isSelected: Bool
    @Binding var customName: String
    let onTap: () -> Void
    
    // 常见目的地建议
    private let suggestions = [
        "国际商贸城", "火车站", "机场", "市政府", "人民医院", "大学城", 
        "购物中心", "体育馆", "博物馆", "公园", "酒店", "餐厅"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    
                    // 信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text("自定义目的地")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("输入任意目的地名称")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("默认使用义乌国际商贸城坐标进行测试")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 展开指示器
                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? .purple : Color(.separator), lineWidth: isSelected ? 2 : 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 输入区域
            if isSelected {
                VStack(spacing: 12) {
                    // 输入框
                    TextField("请输入目的地名称", text: $customName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .submitLabel(.done)
                        .padding(.horizontal, 20)
                    
                    // 快速建议
                    if customName.trim().isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("快速选择:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        customName = suggestion
                                    }
                                    .font(.caption)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.purple.opacity(0.1))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 字符串扩展
extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    DestinationSelectionView()
} 