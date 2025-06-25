//
//  ARNavigationView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI
import ARKit
import SceneKit
import CoreLocation
import MapKit

struct ARNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var arManager = ARNavigationManager()
    @StateObject private var locationManager = MemoTree.LocationManager()
    
    let destination: CLLocationCoordinate2D
    let destinationName: String
    
    @State private var isARActive = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var distance: Double = 0
    @State private var bearing: Double = 0
    @State private var updateTimer: Timer?
    
    var body: some View {
        ZStack {
            // AR场景视图
            ARViewRepresentable(
                arManager: arManager,
                destination: destination,
                distance: $distance,
                bearing: $bearing
            )
            .ignoresSafeArea()
            
            // 顶部信息栏
            VStack {
                HStack {
                    Button("退出") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
                    
                    Spacer()
                    
                    // AR状态指示器
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isARActive ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(isARActive ? "AR已激活" : "正在初始化...")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        // 权限状态指示
                        let permissions = arManager.checkCurrentPermissions()
                        let cameraOK = permissions.camera == .authorized
                        let locationOK = permissions.location == .authorizedWhenInUse || permissions.location == .authorizedAlways
                        
                        Text("📷\(cameraOK ? "✓" : "✗") 📍\(locationOK ? "✓" : "✗")")
                            .font(.caption2)
                            .foregroundColor(cameraOK && locationOK ? .green : .red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // 底部导航信息
            VStack {
                Spacer()
                
                NavigationInfoPanel(
                    destinationName: destinationName,
                    distance: distance,
                    bearing: bearing
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // 中央十字准星
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    CrosshairView()
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .onAppear {
            setupAR()
            startNavigationUpdates()
        }
        .onDisappear {
            arManager.stopAR()
            stopNavigationUpdates()
        }
        .alert("AR导航错误", isPresented: $showingError) {
            Button("确定") { dismiss() }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func setupAR() {
        print("🚀 开始设置AR导航")
        
        // 检查AR支持
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ 设备不支持ARKit")
            errorMessage = "此设备不支持AR功能"
            showingError = true
            return
        }
        
        print("✅ ARKit支持检查通过")
        
        // 添加超时保护
        var permissionRequestCompleted = false
        
        // 设置10秒超时
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if !permissionRequestCompleted {
                print("⏰ 权限请求超时")
                errorMessage = "权限请求超时，请手动到设置中开启相机和位置权限后重试"
                showingError = true
            }
        }
        
        // 检查权限
        arManager.requestPermissions { success, error in
            DispatchQueue.main.async {
                permissionRequestCompleted = true
                print("🔐 权限检查结果 - 成功: \(success), 错误: \(error ?? "无")")
                
                if success {
                    print("🎯 开始启动AR...")
                    arManager.startAR(destination: destination) { active in
                        DispatchQueue.main.async {
                            print("📱 AR状态更新: \(active)")
                            isARActive = active
                            
                            // AR启动成功后立即更新一次导航数据
                            if active {
                                print("🚀 AR启动成功，立即更新导航数据")
                                self.updateNavigationData()
                            }
                        }
                    }
                    
                    print("📍 开始位置跟踪...")
                    locationManager.startTracking()
                } else {
                    errorMessage = error ?? "无法获取必要权限"
                    showingError = true
                }
            }
        }
    }
    
    private func startNavigationUpdates() {
        print("⏰ 启动导航数据更新定时器")
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateNavigationData()
        }
    }
    
    private func stopNavigationUpdates() {
        print("⏹️ 停止导航数据更新定时器")
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateNavigationData() {
        // 确保有当前位置
        guard let currentLocation = locationManager.currentLocation else {
            print("⚠️ updateNavigationData: 当前位置为空")
            return
        }
        
        // 将当前位置传递给AR管理器
        arManager.updateCurrentLocation(currentLocation)
        
        let destinationLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )
        
        // 计算距离
        let newDistance = currentLocation.distance(from: destinationLocation)
        
        // 计算方位角
        let newBearing = calculateBearing(
            from: currentLocation.coordinate,
            to: destination
        )
        
        // 更新UI数据
        DispatchQueue.main.async {
            self.distance = newDistance
            self.bearing = newBearing
        }
        
        // 更新AR管理器（这会更新箭头方向）
        arManager.updateNavigation(
            destination: destination,
            distanceCallback: { dist in
                // 这个回调已经不需要了，因为我们直接计算了距离
            },
            bearingCallback: { bear in
                // 这个回调已经不需要了，因为我们直接计算了方位
            }
        )
        
        // 只在需要时打印（避免日志过多）
        if Int(newDistance) % 10 == 0 || newBearing.truncatingRemainder(dividingBy: 10) < 1 {
            print("📊 导航数据更新 - 距离: \(Int(newDistance))m, 方位: \(Int(newBearing))°")
        }
    }
    
    private func calculateBearing(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let fromLat = from.latitude * .pi / 180
        let fromLng = from.longitude * .pi / 180
        let toLat = to.latitude * .pi / 180
        let toLng = to.longitude * .pi / 180
        
        let deltaLng = toLng - fromLng
        
        let y = sin(deltaLng) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(deltaLng)
        
        var bearing = atan2(y, x) * 180 / .pi
        
        // 标准化角度到0-360度
        bearing = bearing >= 0 ? bearing : bearing + 360
        
        return bearing
    }
}

// MARK: - AR视图包装器
struct ARViewRepresentable: UIViewRepresentable {
    let arManager: ARNavigationManager
    let destination: CLLocationCoordinate2D
    @Binding var distance: Double
    @Binding var bearing: Double
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arManager.setupARView(arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // 更新距离和方位信息
        arManager.updateNavigation(
            destination: destination,
            distanceCallback: { dist in
                DispatchQueue.main.async {
                    distance = dist
                }
            },
            bearingCallback: { bear in
                DispatchQueue.main.async {
                    bearing = bear
                }
            }
        )
    }
}

// MARK: - 导航信息面板
struct NavigationInfoPanel: View {
    let destinationName: String
    let distance: Double
    let bearing: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("目的地")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(destinationName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("距离")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formatDistance(distance))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // 方向指示器
            HStack(spacing: 16) {
                DirectionIndicator(bearing: bearing)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("方位角")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(bearing))°")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 导航提示
                Text(getDirectionText(bearing))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
            }
        }
        .padding(20)
        .background(
            .black.opacity(0.8),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func getDirectionText(_ bearing: Double) -> String {
        let normalizedBearing = bearing < 0 ? bearing + 360 : bearing
        
        switch normalizedBearing {
        case 0..<22.5, 337.5...360:
            return "正前方"
        case 22.5..<67.5:
            return "右前方"
        case 67.5..<112.5:
            return "右侧"
        case 112.5..<157.5:
            return "右后方"
        case 157.5..<202.5:
            return "后方"
        case 202.5..<247.5:
            return "左后方"
        case 247.5..<292.5:
            return "左侧"
        case 292.5..<337.5:
            return "左前方"
        default:
            return "未知方向"
        }
    }
}

// MARK: - 方向指示器
struct DirectionIndicator: View {
    let bearing: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(.blue)
                .frame(width: 32, height: 32)
            
            Image(systemName: "location.north.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(bearing))
        }
    }
}

// MARK: - 十字准星
struct CrosshairView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // 十字线
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(width: 2, height: 20)
            
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(width: 20, height: 2)
        }
    }
}

#Preview {
    ARNavigationView(
        destination: CoreLocation.CLLocationCoordinate2D(latitude: 29.3067, longitude: 120.0763),
        destinationName: "义乌国际商贸城"
    )
} 
