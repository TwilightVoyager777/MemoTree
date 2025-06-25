//
//  ARNavigationManager.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import Foundation
import ARKit
import SceneKit
import CoreLocation
import UIKit
import AVFoundation

class ARNavigationManager: NSObject, ObservableObject {
    private var arView: ARSCNView?
    private var arrowNode: SCNNode?
    private var currentDestination: CLLocationCoordinate2D?
    private var isARRunning = false
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    // 添加徽章管理器
    private let badgeManager = BadgeManager.shared
    
    // 回调函数
    private var statusCallback: ((Bool) -> Void)?
    private var locationPermissionCompletion: ((Bool, String?) -> Void)?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - 权限请求
    func checkCurrentPermissions() -> (camera: AVAuthorizationStatus, location: CLAuthorizationStatus) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        // 修复：不要在主线程直接访问authorizationStatus，使用缓存的状态
        let locationStatus = locationManager.authorizationStatus
        
        print("📋 当前权限状态详情:")
        print("📷 相机权限: \(cameraStatus.rawValue) (\(cameraStatusDescription(cameraStatus)))")
        print("📍 位置权限: \(locationStatus.rawValue) (\(locationStatusDescription(locationStatus)))")
        
        // 在后台线程检查位置服务状态
        DispatchQueue.global(qos: .utility).async {
            let servicesEnabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                print("🌍 位置服务总开关: \(servicesEnabled ? "开启" : "关闭")")
            }
        }
        
        return (camera: cameraStatus, location: locationStatus)
    }
    
    private func cameraStatusDescription(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "未询问"
        case .restricted: return "受限制"
        case .denied: return "被拒绝"
        case .authorized: return "已授权"
        @unknown default: return "未知状态"
        }
    }
    
    private func locationStatusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "未询问"
        case .restricted: return "受限制"
        case .denied: return "被拒绝"
        case .authorizedAlways: return "始终授权"
        case .authorizedWhenInUse: return "使用时授权"
        @unknown default: return "未知状态"
        }
    }
    
    func requestPermissions(completion: @escaping (Bool, String?) -> Void) {
        print("🔍 开始检查AR导航权限")
        
        // 首先检查ARKit支持
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ 设备不支持ARKit")
            completion(false, "此设备不支持AR功能")
            return
        }
        
        // 检查相机权限
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 相机权限状态: \(cameraStatus.rawValue)")
        
        switch cameraStatus {
        case .authorized:
            requestLocationPermission(completion: completion)
        case .notDetermined:
            print("📷 请求相机权限...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("📷 相机权限回调收到，结果: \(granted)")
                DispatchQueue.main.async {
                    print("📷 在主线程处理相机权限结果: \(granted)")
                    if granted {
                        print("📷 相机权限获取成功，继续请求位置权限")
                        self.requestLocationPermission(completion: completion)
                    } else {
                        print("📷 相机权限被拒绝")
                        completion(false, "需要相机权限来使用AR导航")
                    }
                }
            }
        case .denied, .restricted:
            completion(false, "相机权限被拒绝，请在设置中开启")
        @unknown default:
            completion(false, "未知的相机权限状态")
        }
    }
    
    private func requestLocationPermission(completion: @escaping (Bool, String?) -> Void) {
        let locationStatus = locationManager.authorizationStatus
        print("📍 位置权限状态: \(locationStatus.rawValue)")
        
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 所有权限已获取")
            completion(true, nil)
        case .notDetermined:
            print("📍 请求位置权限...")
            // 设置临时完成回调
            locationPermissionCompletion = completion
            
            // 在后台线程请求权限以避免UI卡顿
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
        case .denied, .restricted:
            completion(false, "需要位置权限来使用AR导航，请在设置中开启")
        @unknown default:
            completion(false, "未知的位置权限状态")
        }
    }
    
    // MARK: - AR设置
    func setupARView(_ arView: ARSCNView) {
        print("🎬 设置ARView")
        self.arView = arView
        arView.delegate = self
        arView.session.delegate = self
        
        // 设置场景
        let scene = SCNScene()
        arView.scene = scene
        
        // 设置光照
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // 显示统计信息（可选）
        arView.showsStatistics = false
        
        print("✅ ARView设置完成")
    }
    
    func startAR(destination: CLLocationCoordinate2D, statusCallback: @escaping (Bool) -> Void) {
        print("🎯 ARNavigationManager.startAR 被调用")
        print("📍 目标坐标: \(destination.latitude), \(destination.longitude)")
        
        // 检查设备支持
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ 设备不支持ARWorldTracking")
            statusCallback(false)
            return
        }
        
        // 检查是否在模拟器上运行
        #if targetEnvironment(simulator)
        print("❌ 检测到模拟器环境，ARKit无法运行")
        statusCallback(false)
        return
        #endif
        
        guard let arView = arView else { 
            print("❌ ARView 未设置")
            statusCallback(false)
            return 
        }
        
        print("✅ ARView 已准备就绪")
        
        self.currentDestination = destination
        self.statusCallback = statusCallback
        
        // 创建配置时进行错误检查
        let configuration = ARWorldTrackingConfiguration()
        
        // 检查平面检测支持
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            print("✅ 支持场景重建")
        }
        
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravityAndHeading
        
        // 添加错误处理
        do {
            print("🔧 启动AR会话...")
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            print("🎭 创建导航箭头...")
            createNavigationArrow()
            
            print("📍 开始位置更新...")
            startLocationUpdates()
            
            isARRunning = true
            print("✅ AR导航启动完成")
            statusCallback(true)
            
            // 记录AR导航使用，可能解锁AR相关徽章
            badgeManager.recordARNavigation()
            print("🏆 已记录AR导航使用")
        } catch {
            print("❌ AR会话启动失败: \(error.localizedDescription)")
            statusCallback(false)
        }
    }
    
    func stopAR() {
        arView?.session.pause()
        locationManager.stopUpdatingLocation()
        isARRunning = false
        statusCallback?(false)
    }
    
    // MARK: - 导航元素创建
    private func createNavigationArrow() {
        guard let arView = arView else { 
            print("❌ createNavigationArrow: ARView为空")
            return 
        }
        
        print("🏹 开始创建3D人物导航指示")
        
        // 移除之前的箭头
        if let existingArrow = arrowNode {
            print("🗑️ 移除已存在的人物模型")
            existingArrow.removeFromParentNode()
        }
        
        // 加载USDZ模型
        guard let modelScene = loadUSDZModel() else {
            print("❌ 无法加载USDZ模型，使用备用箭头")
            createFallbackArrow(arView: arView)
            return
        }
        
        // 从场景中提取模型节点
        arrowNode = modelScene.rootNode.clone()
        
        // 优化模型设置
        setupModelAppearance()
        
        // 设置初始位置（在相机前方2米）
        arrowNode?.position = SCNVector3(0, -0.2, -2)
        
        // 设置初始大小（可能需要根据模型调整）
        arrowNode?.scale = SCNVector3(0.3, 0.3, 0.3)
        
        // 添加到场景
        arView.scene.rootNode.addChildNode(arrowNode!)
        
        print("✅ 3D人物导航指示创建完成，位置: \(arrowNode?.position ?? SCNVector3Zero)")
        print("📊 场景节点数量: \(arView.scene.rootNode.childNodes.count)")
    }
    
    // 加载USDZ模型
    private func loadUSDZModel() -> SCNScene? {
        guard let modelURL = Bundle.main.url(forResource: "Boy_Pointing_Upward", withExtension: "usdz") else {
            print("❌ 找不到Boy_Pointing_Upward.usdz文件")
            return nil
        }
        
        do {
            let scene = try SCNScene(url: modelURL, options: nil)
            print("✅ 成功加载USDZ模型")
            return scene
        } catch {
            print("❌ 加载USDZ模型失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 设置模型外观
    private func setupModelAppearance() {
        guard let arrowNode = arrowNode else { return }
        
        // 遍历所有子节点，设置基本材质属性
        arrowNode.enumerateChildNodes { (node, _) in
            // 如果节点有几何体，优化其材质
            if let geometry = node.geometry {
                for material in geometry.materials {
                    // 确保材质在AR环境中看起来良好
                    material.lightingModel = .physicallyBased
                    material.isDoubleSided = true
                    
                    // 不添加额外的发光效果，保持模型原始外观
                }
            }
        }
        
        print("🎨 模型外观设置完成 - 保持原始颜色")
    }
    
    // 备用箭头（如果USDZ加载失败）
    private func createFallbackArrow(arView: ARSCNView) {
        print("🔄 创建备用箭头")
        
        // 创建简单的箭头几何体
        let arrowGeometry = createSimpleArrowGeometry()
        arrowNode = SCNNode(geometry: arrowGeometry)
        
        // 设置材质
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue
        material.emission.contents = UIColor.systemBlue.withAlphaComponent(0.3)
        material.transparency = 0.9
        material.isDoubleSided = true
        material.lightingModel = .constant
        
        arrowGeometry.materials = [material]
        
        // 设置位置
        arrowNode?.position = SCNVector3(0, -0.2, -2)
        
        // 添加到场景
        arView.scene.rootNode.addChildNode(arrowNode!)
        
        print("✅ 备用箭头创建完成")
    }
    
    // 创建简单箭头几何体（备用）
    private func createSimpleArrowGeometry() -> SCNGeometry {
        // 创建简单的锥形箭头
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.3, height: 1.0)
        return cone
    }
    
    // MARK: - 位置管理
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0
    }
    
    // 新增：接收外部位置更新
    func updateCurrentLocation(_ location: CLLocation) {
        currentLocation = location
        print("📍 ARNavigationManager接收位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    private func startLocationUpdates() {
        // 在后台线程检查位置服务状态
        DispatchQueue.global(qos: .utility).async {
            let servicesEnabled = CLLocationManager.locationServicesEnabled()
            
            DispatchQueue.main.async {
                // 首先检查位置服务是否可用
                guard servicesEnabled else { 
                    print("❌ 位置服务不可用")
                    return 
                }
                
                // 检查当前权限状态
                let currentStatus = self.locationManager.authorizationStatus
                guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
                    print("❌ 位置权限不足，当前状态: \(currentStatus.rawValue)")
                    return
                }
                
                // 在后台线程启动位置更新以避免UI卡顿
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        print("📍 开始位置和方向更新...")
                        self.locationManager.startUpdatingLocation()
                        self.locationManager.startUpdatingHeading()
                    }
                }
            }
        }
    }
    
    // MARK: - 导航更新
    func updateNavigation(
        destination: CLLocationCoordinate2D,
        distanceCallback: @escaping (Double) -> Void,
        bearingCallback: @escaping (Double) -> Void
    ) {
        guard let currentLocation = currentLocation else { 
            print("⚠️ updateNavigation: 当前位置未获取")
            return 
        }
        
        let destinationLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )
        
        // 计算距离
        let distance = currentLocation.distance(from: destinationLocation)
        distanceCallback(distance)
        
        // 计算方位角
        let bearing = calculateBearing(
            from: currentLocation.coordinate,
            to: destination
        )
        bearingCallback(bearing)
        
        // 更新AR箭头方向
        updateArrowDirection(bearing: bearing, distance: distance)
        
        // 添加调试信息
        if distance > 0 {
            print("📍 导航更新 - 距离: \(Int(distance))m, 方位: \(Int(bearing))°")
            print("🏹 箭头节点存在: \(arrowNode != nil)")
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
    
    private func updateArrowDirection(bearing: Double, distance: Double) {
        guard let arrowNode = arrowNode else { 
            print("❌ updateArrowDirection: 人物模型节点不存在")
            return 
        }
        
        print("🏹 更新人物模型方向: 方位\(Int(bearing))°, 距离\(Int(distance))m")
        
        // 将方位角转换为弧度
        let bearingRadians = bearing * .pi / 180
        
        // 对于人物模型，我们需要让他面向目标方向
        // 人物默认可能是面向Z轴负方向，所以我们需要相应调整
        let rotation = SCNVector4(0, 1, 0, Float(bearingRadians))
        
        // 优化距离计算 - 让人物始终在合适的视野范围内
        let optimalDistance: Float = {
            if distance < 100 {
                return 1.5  // 近距离：1.5米（人物模型可以更近一些）
            } else if distance < 500 {
                return 2.0  // 中距离：2米
            } else if distance < 2000 {
                return 2.5  // 远距离：2.5米
            } else {
                return 3.0  // 超远距离：3米
            }
        }()
        
        // 优化高度计算 - 让人物站在合适的高度
        let optimalHeight: Float = {
            if distance < 50 {
                return -0.8  // 很近时人物稍微低一些，像在地面上
            } else if distance < 200 {
                return -0.6  // 中近距离
            } else {
                return -0.4  // 远距离时人物稍微高一些，更容易看到
            }
        }()
        
        // 计算人物在指定方向和距离的位置
        let modelPosition = SCNVector3(
            Float(sin(bearingRadians)) * optimalDistance,
            optimalHeight,
            -Float(cos(bearingRadians)) * optimalDistance
        )
        
        // 优化大小计算 - 根据距离调整人物大小
        let optimalScale: Float = {
            if distance < 50 {
                return 0.5   // 很近时人物变大，更明显
            } else if distance < 100 {
                return 0.4   // 近距离
            } else if distance < 500 {
                return 0.35  // 中距离
            } else if distance < 2000 {
                return 0.3   // 远距离
            } else {
                return 0.25  // 超远距离，稍小一些
            }
        }()
        
        // 平滑动画更新人物
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4  // 人物动画稍微慢一些，更自然
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        arrowNode.rotation = rotation
        arrowNode.position = modelPosition
        arrowNode.scale = SCNVector3(optimalScale, optimalScale, optimalScale)
        
        // 不再调整人物的材质颜色，保持原始外观
        
        SCNTransaction.commit()
        
        print("✅ 人物模型更新完成")
        print("   位置: (\(String(format: "%.1f", modelPosition.x)), \(String(format: "%.1f", modelPosition.y)), \(String(format: "%.1f", modelPosition.z)))")
        print("   距离: \(String(format: "%.1f", optimalDistance))m, 高度: \(String(format: "%.1f", optimalHeight))m")
        print("   缩放: \(String(format: "%.1f", optimalScale))x")
        
        // 如果距离很近，添加抵达效果
        if distance < 20 {
            addArrivalEffect()
        } else {
            // 移除抵达效果，添加常规动画
            if arrowNode.actionKeys.contains("arrivalEffect") {
                arrowNode.removeAction(forKey: "arrivalEffect")
                
                // 清理所有材质的庆祝发光动画
                arrowNode.enumerateChildNodes { (node, _) in
                    if let geometry = node.geometry {
                        for material in geometry.materials {
                            material.removeAnimation(forKey: "celebrationGlow")
                        }
                    }
                }
            }
            
            // 添加微妙的悬浮动画
            if !arrowNode.actionKeys.contains("subtleFloat") {
                addSubtleAnimation()
            }
        }
    }
    
    private func addArrivalEffect() {
        guard let arrowNode = arrowNode else { return }
        
        print("🎉 添加人物抵达庆祝效果")
        
        // 移除之前的动画
        arrowNode.removeAllActions()
        
        // 创建人物庆祝动画效果
        // 1. 轻微的跳跃效果
        let jumpUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.4)
        jumpUp.timingMode = .easeOut
        let jumpDown = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 0.4)
        jumpDown.timingMode = .easeIn
        let jumpSequence = SCNAction.sequence([jumpUp, jumpDown])
        
        // 2. 旋转庆祝效果（小幅度）
        let celebrateRotation = SCNAction.rotateBy(x: 0, y: .pi/4, z: 0, duration: 0.6)
        celebrateRotation.timingMode = .easeInEaseOut
        
        // 3. 缩放脉冲效果
        let scaleUp = SCNAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.3)
        let pulseSequence = SCNAction.sequence([scaleUp, scaleDown])
        
        // 组合所有庆祝动画
        let celebrationGroup = SCNAction.group([jumpSequence, celebrateRotation, pulseSequence])
        let repeatCelebration = SCNAction.repeatForever(celebrationGroup)
        
        arrowNode.runAction(repeatCelebration, forKey: "arrivalEffect")
        
        // 添加发光效果
        arrowNode.enumerateChildNodes { (node, _) in
            if let geometry = node.geometry {
                for material in geometry.materials {
                    let colorAnimation = CABasicAnimation(keyPath: "emission.contents")
                    colorAnimation.fromValue = UIColor.systemGreen.withAlphaComponent(0.2)
                    colorAnimation.toValue = UIColor.systemGreen.withAlphaComponent(0.6)
                    colorAnimation.duration = 0.8
                    colorAnimation.autoreverses = true
                    colorAnimation.repeatCount = .infinity
                    
                    material.addAnimation(colorAnimation, forKey: "celebrationGlow")
                }
            }
        }
        
        print("🎊 人物庆祝动画已启动")
    }
    
    // 添加常规的人物动画效果
    private func addSubtleAnimation() {
        guard let arrowNode = arrowNode else { return }
        
        // 移除之前的动画
        arrowNode.removeAllActions()
        
        // 添加自然的人物动画
        // 1. 轻微的上下浮动（呼吸效果）
        let breatheUp = SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 2.0)
        breatheUp.timingMode = .easeInEaseOut
        
        let breatheDown = SCNAction.moveBy(x: 0, y: -0.08, z: 0, duration: 2.0)
        breatheDown.timingMode = .easeInEaseOut
        
        let breatheSequence = SCNAction.sequence([breatheUp, breatheDown])
        let breatheForever = SCNAction.repeatForever(breatheSequence)
        
        // 2. 轻微的左右摆动（指向强调）
        let pointLeft = SCNAction.rotateBy(x: 0, y: -0.1, z: 0, duration: 1.5)
        pointLeft.timingMode = .easeInEaseOut
        
        let pointRight = SCNAction.rotateBy(x: 0, y: 0.2, z: 0, duration: 3.0)
        pointRight.timingMode = .easeInEaseOut
        
        let pointBack = SCNAction.rotateBy(x: 0, y: -0.1, z: 0, duration: 1.5)
        pointBack.timingMode = .easeInEaseOut
        
        let pointSequence = SCNAction.sequence([pointLeft, pointRight, pointBack])
        let pointForever = SCNAction.repeatForever(pointSequence)
        
        // 组合自然动画
        let naturalGroup = SCNAction.group([breatheForever, pointForever])
        arrowNode.runAction(naturalGroup, forKey: "subtleFloat")
        
        print("✅ 人物自然动画已启动")
    }
}

// MARK: - ARSCNViewDelegate
extension ARNavigationManager: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 每帧更新（如需要）
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 检测到新的锚点
    }
}

// MARK: - ARSessionDelegate
extension ARNavigationManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // AR会话更新
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR会话失败: \(error.localizedDescription)")
        isARRunning = false
        statusCallback?(false)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("AR会话被中断")
        isARRunning = false
        statusCallback?(false)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("AR会话中断结束")
        // 重新启动追踪
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravityAndHeading
        
        session.run(configuration, options: [.resetTracking])
        isARRunning = true
        statusCallback?(true)
    }
}

// MARK: - CLLocationManagerDelegate
extension ARNavigationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 可以使用指南针数据进一步优化方向计算
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        let errorCode = clError?.code.rawValue ?? -1
        
        print("❌ 位置更新失败:")
        print("   错误代码: \(errorCode)")
        print("   错误描述: \(error.localizedDescription)")
        
        if let clError = clError {
            let errorExplanation = locationErrorExplanation(clError.code)
            print("   详细说明: \(errorExplanation)")
            
            // 根据错误类型给出建议
            let suggestion = locationErrorSuggestion(clError.code)
            print("   解决建议: \(suggestion)")
        }
        
        print("   当前位置服务状态: \(CLLocationManager.locationServicesEnabled() ? "开启" : "关闭")")
        print("   当前授权状态: \(locationStatusDescription(manager.authorizationStatus))")
    }
    
    private func locationErrorExplanation(_ error: CLError.Code) -> String {
        switch error {
        case .locationUnknown:
            return "无法确定当前位置"
        case .denied:
            return "位置权限被拒绝"
        case .network:
            return "网络错误"
        case .headingFailure:
            return "罗盘校准失败"
        case .regionMonitoringDenied:
            return "区域监控被拒绝"
        case .regionMonitoringFailure:
            return "区域监控失败"
        case .regionMonitoringSetupDelayed:
            return "区域监控设置延迟"
        case .regionMonitoringResponseDelayed:
            return "区域监控响应延迟"
        case .geocodeFoundNoResult:
            return "地理编码无结果"
        case .geocodeFoundPartialResult:
            return "地理编码部分结果"
        case .geocodeCanceled:
            return "地理编码已取消"
        @unknown default:
            return "未知位置错误"
        }
    }
    
    private func locationErrorSuggestion(_ error: CLError.Code) -> String {
        switch error {
        case .locationUnknown:
            return "请移动到室外空旷环境，或检查GPS信号"
        case .denied:
            return "请到设置 > 隐私与安全性 > 定位服务中开启权限"
        case .network:
            return "请检查网络连接"
        case .headingFailure:
            return "请校准设备罗盘，远离磁场干扰"
        default:
            return "请重试或重启应用"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 位置权限状态变化: \(status.rawValue)")
        
        // 确保在主线程更新UI相关状态
        DispatchQueue.main.async {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ 位置权限已获取")
                // 在后台启动位置更新
                DispatchQueue.global(qos: .userInitiated).async {
                    DispatchQueue.main.async {
                        self.startLocationUpdates()
                    }
                }
                // 如果有待处理的权限回调，调用它
                self.locationPermissionCompletion?(true, nil)
                self.locationPermissionCompletion = nil
            case .denied, .restricted:
                print("❌ 位置权限被拒绝")
                self.locationPermissionCompletion?(false, "需要位置权限来使用AR导航，请在设置中开启")
                self.locationPermissionCompletion = nil
            case .notDetermined:
                print("🤔 位置权限状态未确定")
            @unknown default:
                print("❓ 未知位置权限状态")
                self.locationPermissionCompletion?(false, "未知的位置权限状态")
                self.locationPermissionCompletion = nil
            }
        }
    }
} 