//
//  NetworkService.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import Foundation
import Combine

// MARK: - 网络服务基类
class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "http://localhost:8080/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - 基础请求方法
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        requiresAuth: Bool = false
    ) -> AnyPublisher<APIResponse<T>, NetworkError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证头
        if requiresAuth {
            if let token = TokenManager.shared.getToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                return Fail(error: NetworkError.unauthorized)
                    .eraseToAnyPublisher()
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIResponse<T>.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 上传文件方法
    func uploadImage(
        endpoint: String,
        imageData: Data,
        fileName: String = "image.jpg"
    ) -> AnyPublisher<APIResponse<String>, NetworkError> {
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = TokenManager.shared.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let httpBody = createMultipartBody(imageData: imageData, fileName: fileName, boundary: boundary)
        request.httpBody = httpBody
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIResponse<String>.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return NetworkError.decodingError
                } else {
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func createMultipartBody(imageData: Data, fileName: String, boundary: String) -> Data {
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

// MARK: - HTTP方法枚举
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - 网络错误枚举
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case notFound
    case networkError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .decodingError:
            return "数据解析错误"
        case .unauthorized:
            return "未授权访问"
        case .notFound:
            return "资源未找到"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}

// MARK: - Token管理器
class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "auth_token"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func saveToken(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    func removeToken() {
        userDefaults.removeObject(forKey: tokenKey)
    }
    
    func isLoggedIn() -> Bool {
        return getToken() != nil
    }
} 