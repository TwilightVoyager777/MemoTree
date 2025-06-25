//
//  ARScannerView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI
import AVFoundation
import CoreLocation

struct ARScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = false
    @State private var scanProgress: Double = 0
    @State private var showingSuccess = false
    @State private var showingAttractionDetail = false
    @State private var animateScanFrame = false
    @State private var foundAttraction: AttractionInfo?
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var recognitionInProgress = false
    
    @StateObject private var recognitionService = ImageRecognitionService.shared
    
    // 模拟灵隐寺数据
    private let lingYinTemple = AttractionInfo(
        name: "灵隐寺",
        chineseName: "灵隐寺",
        description: "杭州最著名的佛教寺院，始建于东晋咸和元年（326年），距今已有1700多年历史。这里古木参天，殿宇巍峨，是杭州最具代表性的佛教圣地。",
        history: "灵隐寺创建于东晋咸和元年，由印度僧人慧理和尚建造。寺名'灵隐'意为'仙灵所隐'，据说是因为这里林木茂盛，山峰奇秀，似有仙灵隐匿其间而得名。",
        features: [
            "天王殿：寺院的第一重殿，供奉四大天王",
            "大雄宝殿：寺院主殿，供奉释迦牟尼佛",
            "药师殿：供奉药师如来，祈求健康平安",
            "飞来峰：寺前的奇峰怪石，有众多石窟造像"
        ],
        visitTips: [
            "开放时间：6:30-18:30（夏季延长至19:00）",
            "门票价格：灵隐寺30元，飞来峰45元",
            "交通：地铁4号线到龙翔桥站，转公交7、807路",
            "建议游览时间：2-3小时",
            "注意：进入寺院请保持安静，尊重佛教文化"
        ],
        coordinates: CLLocationCoordinate2D(latitude: 30.2419, longitude: 120.0985),
        category: "佛教寺院",
        rating: 4.6,
        imageUrl: "route_cover_2"
    )
    
    var body: some View {
        ZStack {
            // 真实相机预览
            CameraView(isScanning: $isScanning) { image in
                if let image = image {
                    processRecognition(with: image)
                }
            }
            .ignoresSafeArea()
            
            // 扫描界面覆盖层
            VStack {
                // 顶部控制栏
                TopControlBar(dismiss: dismiss)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                // 扫描框和提示
                VStack(spacing: 24) {
                    // 扫描框
                    ScanFrameView(
                        isScanning: $recognitionInProgress,
                        animateScanFrame: $animateScanFrame
                    )
                    
                    // 扫描提示文字
                    VStack(spacing: 12) {
                        if recognitionInProgress {
                            Text("正在识别景点...")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            ProgressView(value: scanProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .frame(width: 200)
                                .scaleEffect(y: 2)
                        } else {
                            Text("将相机对准景点或建筑")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("支持识别著名景点、历史建筑、文化地标")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                
                Spacer()
                
                // 底部操作区
                BottomActionArea(
                    isScanning: $recognitionInProgress,
                    onScanTap: startCameraRecognition,
                    onGalleryTap: { showingImagePicker = true }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // 成功识别覆盖层
            if showingSuccess, let attraction = foundAttraction {
                SuccessOverlayView(
                    attraction: attraction,
                    onDetailTap: {
                        showingAttractionDetail = true
                    },
                    onDismiss: {
                        showingSuccess = false
                        resetScanning()
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .zIndex(10)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                if let image = image {
                    processRecognition(with: image)
                }
            }
        }
        .sheet(isPresented: $showingAttractionDetail) {
            if let attraction = foundAttraction {
                AttractionDetailView(attraction: attraction)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateScanFrame = true
            }
        }
    }
    
    private func startCameraRecognition() {
        guard !recognitionInProgress else { return }
        isScanning = true
    }
    
    private func processRecognition(with image: UIImage) {
        recognitionInProgress = true
        scanProgress = 0
        
        // 模拟进度更新
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            scanProgress += 0.05
            if scanProgress >= 1.0 {
                timer.invalidate()
            }
        }
        
        // 开始图片识别
        recognitionService.recognizeImage(image) { result in
            progressTimer.invalidate()
            
            switch result {
            case .success(let attraction):
                foundAttraction = attraction
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingSuccess = true
                    }
                    
                    // 触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }
                
            case .failure(_):
                // 识别失败时直接重置扫描状态
                resetScanning()
            }
            
            recognitionInProgress = false
            isScanning = false
        }
    }
    
    private func resetScanning() {
        recognitionInProgress = false
        isScanning = false
        scanProgress = 0
        foundAttraction = nil
    }
}

// MARK: - 顶部控制栏
struct TopControlBar: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Text("AR景点识别")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // 占位，保持居中
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
    }
}

// MARK: - 扫描框视图
struct ScanFrameView: View {
    @Binding var isScanning: Bool
    @Binding var animateScanFrame: Bool
    
    var body: some View {
        ZStack {
            // 扫描框
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .blue, .green]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 250, height: 250)
                .scaleEffect(animateScanFrame ? 1.05 : 1.0)
                .opacity(animateScanFrame ? 0.8 : 1.0)
            
            // 扫描线条
            if isScanning {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .green.opacity(0.8),
                                .green,
                                .green.opacity(0.8),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 250, height: 2)
                    .offset(y: animateScanFrame ? -125 : 125)
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animateScanFrame)
            }
            
            // 角落装饰
            VStack {
                HStack {
                    CornerMarker(position: .topLeading)
                    Spacer()
                    CornerMarker(position: .topTrailing)
                }
                Spacer()
                HStack {
                    CornerMarker(position: .bottomLeading)
                    Spacer()
                    CornerMarker(position: .bottomTrailing)
                }
            }
            .frame(width: 250, height: 250)
        }
    }
}

// MARK: - 角落标记
struct CornerMarker: View {
    enum Position {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }
    
    let position: Position
    
    var body: some View {
        ZStack {
            switch position {
            case .topLeading:
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle().frame(width: 20, height: 3)
                    Rectangle().frame(width: 3, height: 20)
                }
            case .topTrailing:
                VStack(alignment: .trailing, spacing: 0) {
                    Rectangle().frame(width: 20, height: 3)
                    Rectangle().frame(width: 3, height: 20)
                }
            case .bottomLeading:
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle().frame(width: 3, height: 20)
                    Rectangle().frame(width: 20, height: 3)
                }
            case .bottomTrailing:
                VStack(alignment: .trailing, spacing: 0) {
                    Rectangle().frame(width: 3, height: 20)
                    Rectangle().frame(width: 20, height: 3)
                }
            }
        }
        .foregroundColor(.white)
    }
}

// MARK: - 底部操作区域
struct BottomActionArea: View {
    @Binding var isScanning: Bool
    let onScanTap: () -> Void
    let onGalleryTap: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            // 相册按钮
            Button(action: onGalleryTap) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .disabled(isScanning)
            .opacity(isScanning ? 0.5 : 1.0)
            
            // 扫描按钮
            Button(action: onScanTap) {
                ZStack {
                    Circle()
                        .fill(isScanning ? .red : .green)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                    
                    if isScanning {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(isScanning ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isScanning)
            
            // 闪光灯按钮（暂时保留）
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .disabled(isScanning)
            .opacity(isScanning ? 0.5 : 1.0)
        }
    }
}

// MARK: - 成功识别覆盖层
struct SuccessOverlayView: View {
    let attraction: AttractionInfo
    let onDetailTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var animateSuccess = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                // 成功图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateSuccess ? 1.0 : 0.5)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateSuccess ? 1.0 : 0.5)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                }
                
                // 成功文字
                VStack(spacing: 8) {
                    Text("恭喜你已经成功打卡")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .offset(y: animateSuccess ? 0 : 20)
                    
                    // 可点击的景点名称
                    Button(action: onDetailTap) {
                        Text(attraction.name)
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.yellow, .orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .underline()
                    }
                    .opacity(animateSuccess ? 1.0 : 0.0)
                    .offset(y: animateSuccess ? 0 : 20)
                    
                    Text("景点")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .offset(y: animateSuccess ? 0 : 20)
                }
                
                // 操作按钮
                HStack(spacing: 16) {
                    Button("稍后查看") {
                        onDismiss()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    
                    Button("查看详情") {
                        onDetailTap()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
                }
                .opacity(animateSuccess ? 1.0 : 0.0)
                .offset(y: animateSuccess ? 0 : 30)
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateSuccess = true
            }
        }
    }
}

#Preview {
    ARScannerView()
} 