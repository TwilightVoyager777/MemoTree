//
//  RoutePointEditorView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import MapKit

struct RoutePointEditorView: View {
    @Binding var point: EditableRoutePoint
    let onSave: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var localName: String = ""
    @State private var localDescription: String = ""
    @State private var localPointType: PointType = .waypoint
    @State private var showingDeleteAlert = false
    
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 地图预览
                    PointLocationPreview(coordinate: point.coordinate)
                        .frame(height: 200)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 20) {
                        // 点位名称
                        PointNameSection(
                            name: $localName,
                            isNameFocused: $isNameFocused
                        )
                        
                        // 点位类型
                        PointTypeSection(
                            pointType: $localPointType,
                            isStartOrEnd: point.pointType == .start || point.pointType == .end
                        )
                        
                        // 点位描述
                        PointDescriptionSection(
                            description: $localDescription,
                            isDescriptionFocused: $isDescriptionFocused
                        )
                        
                        // 坐标信息
                        CoordinateInfoSection(coordinate: point.coordinate)
                        
                        // 删除按钮（如果不是起点或终点）
                        if point.pointType != .start && point.pointType != .end {
                            DeletePointButton {
                                showingDeleteAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("编辑点位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePoint()
                    }
                    .fontWeight(.semibold)
                    .disabled(localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("删除点位", isPresented: $showingDeleteAlert) {
                Button("删除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要删除这个点位吗？此操作无法撤销。")
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    // MARK: - 方法
    
    private func setupInitialValues() {
        localName = point.name
        localDescription = point.description
        localPointType = point.pointType
    }
    
    private func savePoint() {
        point.name = localName.trimmingCharacters(in: .whitespacesAndNewlines)
        point.description = localDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果不是起点或终点，允许修改类型
        if point.pointType != .start && point.pointType != .end {
            point.pointType = localPointType
        }
        
        onSave()
        dismiss()
    }
}

// MARK: - 地图位置预览
struct PointLocationPreview: View {
    let coordinate: CLLocationCoordinate2D
    
    @State private var mapRegion: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self._mapRegion = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("位置预览")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            Map(coordinateRegion: .constant(mapRegion), annotationItems: [coordinate]) { coordinate in
                MapPin(coordinate: coordinate, tint: .red)
            }
            .disabled(true) // 只作为预览，不允许交互
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// 扩展以支持Map annotationItems
extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}

// MARK: - 点位名称部分
struct PointNameSection: View {
    @Binding var name: String
    @FocusState.Binding var isNameFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("点位名称", systemImage: "mappin.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("为这个点位命名...", text: $name)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isNameFocused ? .blue : .clear, lineWidth: 2)
                    )
                    .focused($isNameFocused)
                
                Text("清晰的名称有助于其他用户理解这个点位")
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

// MARK: - 点位类型部分
struct PointTypeSection: View {
    @Binding var pointType: PointType
    let isStartOrEnd: Bool
    
    var availableTypes: [PointType] {
        if isStartOrEnd {
            return [pointType] // 如果是起点或终点，不允许修改
        } else {
            return [.waypoint, .viewpoint, .food, .photo, .rest, .shop]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("点位类型", systemImage: "tag.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if isStartOrEnd {
                // 起点或终点不可修改提示
                HStack {
                    Image(systemName: pointType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(pointType.color)
                    
                    Text(pointType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("固定类型")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.gray.opacity(0.1), in: Capsule())
                }
                .padding(16)
                .background(.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            } else {
                // 可选择的类型
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(availableTypes, id: \.rawValue) { type in
                        PointTypeCard(
                            pointType: type,
                            isSelected: pointType == type,
                            onTap: {
                                pointType = type
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct PointTypeCard: View {
    let pointType: PointType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(pointType.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: pointType.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(pointType.color)
                }
                
                Text(pointType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(pointType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? pointType.color.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? pointType.color : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - 点位描述部分
struct PointDescriptionSection: View {
    @Binding var description: String
    @FocusState.Binding var isDescriptionFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("点位描述", systemImage: "text.bubble.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("描述这个点位的特色、注意事项或推荐理由...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $description)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isDescriptionFocused ? .blue : .clear, lineWidth: 2)
                        )
                        .frame(minHeight: 100)
                        .focused($isDescriptionFocused)
                }
                
                HStack {
                    Text("字数: \(description.count)/200")
                        .font(.caption)
                        .foregroundColor(description.count > 200 ? .red : .secondary)
                    
                    Spacer()
                    
                    if description.count > 20 {
                        Text("✓ 描述详细")
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

// MARK: - 坐标信息部分
struct CoordinateInfoSection: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("位置坐标", systemImage: "location.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                CoordinateRow(
                    label: "纬度",
                    value: String(format: "%.6f", coordinate.latitude),
                    icon: "arrow.up.and.down"
                )
                
                CoordinateRow(
                    label: "经度",
                    value: String(format: "%.6f", coordinate.longitude),
                    icon: "arrow.left.and.right"
                )
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct CoordinateRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

// MARK: - 删除点位按钮
struct DeletePointButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("删除此点位")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.red, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - PointType 扩展
extension PointType {
    var color: Color {
        switch self {
        case .start: return .green
        case .end: return .red
        case .waypoint: return .blue
        case .checkpoint: return .cyan
        case .viewpoint: return .purple
        case .food: return .orange
        case .photo: return .pink
        case .rest: return .teal
        case .shop: return .brown
        case .historic: return .indigo
        case .nature: return .mint
        }
    }
    
    var description: String {
        switch self {
        case .start: return "路线起点"
        case .end: return "路线终点"
        case .waypoint: return "普通经过点"
        case .checkpoint: return "检查点"
        case .viewpoint: return "观景点位"
        case .food: return "美食推荐"
        case .photo: return "拍照胜地"
        case .rest: return "休息点位"
        case .shop: return "商店"
        case .historic: return "历史点位"
        case .nature: return "自然景观"
        }
    }
}

#Preview {
    RoutePointEditorView(
        point: .constant(EditableRoutePoint(
            coordinate: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
            name: "西湖断桥",
            description: "著名的西湖十景之一",
            pointType: .viewpoint
        )),
        onSave: {},
        onDelete: {}
    )
} 