//
//  AttractionDetailView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI
import MapKit

struct AttractionDetailView: View {
    let attraction: AttractionInfo
    @Environment(\.dismiss) private var dismiss
    @State private var animateContent = false
    @State private var showingMap = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部图片区域
                    AttractionHeaderView(attraction: attraction)
                    
                    // 内容区域
                    VStack(spacing: 24) {
                        // 基本信息卡片
                        BasicInfoCard(attraction: attraction)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                        
                        // 选项卡切换
                        TabSegmentedControl(selectedTab: $selectedTab)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                        
                        // 内容展示
                        Group {
                            switch selectedTab {
                            case 0:
                                HistoryContentView(attraction: attraction)
                            case 1:
                                FeaturesContentView(attraction: attraction)
                            case 2:
                                VisitTipsContentView(attraction: attraction)
                            default:
                                HistoryContentView(attraction: attraction)
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .overlay(
                // 底部操作栏
                VStack {
                    Spacer()
                    AttractionBottomActionBar(
                        onNavigate: { showingMap = true },
                        onShare: shareAttraction,
                        onFavorite: addToFavorites
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 50)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingMap) {
            AttractionMapView(attraction: attraction)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    private func shareAttraction() {
        let shareText = "我刚刚通过AR识别发现了\(attraction.name)！\(attraction.description)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func addToFavorites() {
        // TODO: 实现收藏功能
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - 头部图片区域
struct AttractionHeaderView: View {
    let attraction: AttractionInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 背景图片
            SmartImageView(
                imageSource: attraction.imageUrl,
                placeholder: Image(systemName: "building.2"),
                width: UIScreen.main.bounds.width,
                height: 350,
                contentMode: .fill
            )
            
            // 渐变遮罩
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // 内容覆盖层
            VStack {
                // 顶部控制栏
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Text("景点详情")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // 底部信息
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(attraction.category)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.orange, in: Capsule())
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { star in
                                Image(systemName: star < Int(attraction.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            Text(String(format: "%.1f", attraction.rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(attraction.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    
                    Text(attraction.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 350)
    }
}

// MARK: - 基本信息卡片
struct BasicInfoCard: View {
    let attraction: AttractionInfo
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("基本信息")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "location.fill",
                    label: "地理位置",
                    value: String(format: "%.4f, %.4f", attraction.coordinates.latitude, attraction.coordinates.longitude),
                    color: .green
                )
                
                InfoRow(
                    icon: "star.fill",
                    label: "评分等级",
                    value: "\(String(format: "%.1f", attraction.rating)) / 5.0",
                    color: .yellow
                )
                
                InfoRow(
                    icon: "building.2.fill",
                    label: "景点类型",
                    value: attraction.category,
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 选项卡控制器
struct TabSegmentedControl: View {
    @Binding var selectedTab: Int
    private let tabs = ["历史介绍", "特色景观", "游览指南"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == index ? .white : .secondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTab == index 
                                ? Color.blue
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
            }
        }
        .padding(4)
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 历史内容视图
struct HistoryContentView: View {
    let attraction: AttractionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("历史沿革")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(attraction.history)
                .font(.body)
                .lineSpacing(4)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 特色景观视图
struct FeaturesContentView: View {
    let attraction: AttractionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("主要景观")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(attraction.features.enumerated()), id: \.offset) { index, feature in
                    FeatureRow(feature: feature, index: index)
                }
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 特色行
struct FeatureRow: View {
    let feature: String
    let index: Int
    
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red]
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colors[index % colors.count].opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(colors[index % colors.count])
            }
            
            Text(feature)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            Spacer()
        }
    }
}

// MARK: - 游览指南视图
struct VisitTipsContentView: View {
    let attraction: AttractionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("游览建议")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(attraction.visitTips.enumerated()), id: \.offset) { index, tip in
                    TipRow(tip: tip)
                }
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 提示行
struct TipRow: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .padding(.top, 2)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            Spacer()
        }
    }
}

// MARK: - 底部操作栏
struct AttractionBottomActionBar: View {
    let onNavigate: () -> Void
    let onShare: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 导航按钮
            Button(action: onNavigate) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("导航前往")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // 分享按钮
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 52, height: 52)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
            
            // 收藏按钮
            Button(action: onFavorite) {
                Image(systemName: "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 52, height: 52)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

// MARK: - 景点地图视图
struct AttractionMapView: View {
    let attraction: AttractionInfo
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(attraction: AttractionInfo) {
        self.attraction = attraction
        self._region = State(initialValue: MKCoordinateRegion(
            center: attraction.coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: [attraction]) { attraction in
                MapPin(coordinate: attraction.coordinates, tint: .red)
            }
            .navigationTitle(attraction.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("关闭") { dismiss() },
                trailing: Button("导航") {
                    openInMaps()
                }
            )
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: attraction.coordinates)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = attraction.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

#Preview {
    AttractionDetailView(attraction: AttractionInfo(
        name: "灵隐寺",
        chineseName: "灵隐寺",
        description: "杭州最著名的佛教寺院，始建于东晋咸和元年（326年），距今已有1700多年历史。",
        history: "灵隐寺创建于东晋咸和元年，由印度僧人慧理和尚建造。寺名'灵隐'意为'仙灵所隐'。",
        features: ["天王殿", "大雄宝殿", "药师殿", "飞来峰"],
        visitTips: ["开放时间：6:30-18:30", "门票价格：30元"],
        coordinates: CLLocationCoordinate2D(latitude: 30.2419, longitude: 120.0985),
        category: "佛教寺院",
        rating: 4.6,
        imageUrl: "lingyin_temple"
    ))
} 