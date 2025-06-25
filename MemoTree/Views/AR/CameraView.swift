//
//  CameraView.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onImageCaptured: (UIImage?) -> Void
    
    func makeUIView(context: Context) -> CameraUIView {
        let cameraView = CameraUIView()
        cameraView.delegate = context.coordinator
        return cameraView
    }
    
    func updateUIView(_ uiView: CameraUIView, context: Context) {
        if isScanning {
            uiView.capturePhoto()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraUIViewDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didCaptureImage(_ image: UIImage?) {
            parent.onImageCaptured(image)
        }
    }
}

protocol CameraUIViewDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage?)
}

class CameraUIView: UIView {
    weak var delegate: CameraUIViewDelegate?
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("无法访问相机")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        } catch let error {
            print("相机设置错误: \(error.localizedDescription)")
        }
    }
    
    private func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = bounds
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

extension CameraUIView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            delegate?.didCaptureImage(nil)
            return
        }
        
        let image = UIImage(data: imageData)
        delegate?.didCaptureImage(image)
    }
} 