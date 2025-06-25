//
//  LocationManager.swift
//  MemoTree
//
//  Created by AI Assistant on 2025/1/10.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0
    }
    
    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("位置服务未开启")
            return
        }
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    self.locationManager.startUpdatingLocation()
                }
            }
        case .notDetermined:
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
        case .denied, .restricted:
            print("位置权限被拒绝或受限")
        @unknown default:
            print("未知的位置权限状态")
        }
    }
    
    func stopTracking() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.locationManager.stopUpdatingLocation()
            }
        }
    }
    
    func requestLocationPermission() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
        }
        
        let clError = error as? CLError
        let errorCode = clError?.code.rawValue ?? -1
        
        print("❌ LocationManager位置更新失败:")
        print("   错误代码: \(errorCode)")
        print("   错误描述: \(error.localizedDescription)")
        
        if let clError = clError {
            let errorExplanation = locationErrorExplanation(clError.code)
            print("   详细说明: \(errorExplanation)")
            
            let suggestion = locationErrorSuggestion(clError.code)
            print("   解决建议: \(suggestion)")
        }
        
        print("   位置服务状态: \(CLLocationManager.locationServicesEnabled() ? "开启" : "关闭")")
        print("   授权状态: \(authorizationStatus.rawValue)")
    }
    
    private func locationErrorExplanation(_ error: CLError.Code) -> String {
        switch error {
        case .locationUnknown:
            return "无法确定当前位置（通常是室内或GPS信号弱）"
        case .denied:
            return "位置权限被拒绝"
        case .network:
            return "网络连接问题"
        case .headingFailure:
            return "罗盘校准失败"
        default:
            return "其他位置服务错误"
        }
    }
    
    private func locationErrorSuggestion(_ error: CLError.Code) -> String {
        switch error {
        case .locationUnknown:
            return "建议移动到室外空旷环境重试"
        case .denied:
            return "请在设置中开启位置权限"
        case .network:
            return "请检查网络连接状态"
        case .headingFailure:
            return "请校准设备罗盘"
        default:
            return "请重启应用或重新授权"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    manager.startUpdatingLocation()
                }
            }
        case .denied, .restricted:
            print("位置权限被拒绝")
        case .notDetermined:
            break
        @unknown default:
            print("未知的授权状态")
        }
    }
} 