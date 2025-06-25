//
//  LoginView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingRegister = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var animateContent = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Logo和标题区域
                    LogoSection()
                    
                    // 登录表单区域
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            // 用户名/邮箱输入框
                            TextField("用户名或邮箱", text: $usernameOrEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            // 密码输入框
                            SecureField("密码", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)
                        }
                        
                        // 登录按钮
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isLoading ? "登录中..." : "登录")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(usernameOrEmail.isEmpty || password.isEmpty || isLoading)
                        
                        // 忘记密码
                        Button("忘记密码？") {
                            // TODO: 实现忘记密码功能
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal, 30)
                    
                    // 注册提示
                    HStack {
                        Text("还没有账号？")
                            .foregroundColor(.secondary)
                        
                        Button("立即注册") {
                            showingRegister = true
                        }
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    }
                    
                    Spacer(minLength: 60)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("登录失败", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }
    
    // MARK: - 方法
    private func handleLogin() {
        guard !usernameOrEmail.isEmpty && !password.isEmpty else { return }
        
        isLoading = true
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        authService.login(usernameOrEmail: usernameOrEmail, password: password)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        isLoading = false
                        if case .failure(let error) = completion {
                            alertMessage = error.localizedDescription
                            showingAlert = true
                        }
                    }
                },
                receiveValue: { success in
                    DispatchQueue.main.async {
                        isLoading = false
                        if !success {
                            alertMessage = "登录失败，请检查用户名和密码"
                            showingAlert = true
                        }
                        // 成功的话，AuthService会自动更新isLoggedIn状态
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Logo区域组件
struct LogoSection: View {
    @State private var logoRotation: Double = 0
    @State private var logoScale: Double = 1
    
    var body: some View {
        VStack(spacing: 24) {
            // 动态Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.3), .green.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(logoRotation))
                    .scaleEffect(logoScale)
            }
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    logoRotation = 360
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    logoScale = 1.1
                }
            }
            
            // 标题文字
            VStack(spacing: 8) {
                Text("MemoTree")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.primary, .secondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("发现城市，记录足迹")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 登录表单组件
struct LoginFormSection: View {
    @Binding var usernameOrEmail: String
    @Binding var password: String
    @Binding var isLoading: Bool
    @Binding var showingRegister: Bool
    let handleLogin: () -> Void
    
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var isFormValid: Bool {
        !usernameOrEmail.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                // 用户名/邮箱输入框
                EnhancedTextField(
                    icon: "person.fill",
                    placeholder: "用户名或邮箱",
                    text: $usernameOrEmail,
                    isFocused: focusedField == .email
                )
                .focused($focusedField, equals: .email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                // 密码输入框
                EnhancedSecureField(
                    icon: "lock.fill",
                    placeholder: "密码",
                    text: $password,
                    isFocused: focusedField == .password
                )
                .focused($focusedField, equals: .password)
                .textContentType(.password)
            }
            
            // 登录按钮
            EnhancedLoginButton(
                isLoading: isLoading,
                isFormValid: isFormValid,
                action: handleLogin
            )
            
            // 忘记密码
            Button("忘记密码？") {
                // TODO: 实现忘记密码功能
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.green)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 注册提示组件
struct RegisterPromptSection: View {
    @Binding var showingRegister: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text("还没有账号？")
                .foregroundColor(.secondary)
            
            Button("立即注册") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingRegister = true
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .font(.subheadline)
    }
}

// MARK: - 增强文本输入框
struct EnhancedTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isFocused ? .green : .secondary)
                .frame(width: 24)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isFocused)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused ? Color.green.opacity(0.6) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? .green.opacity(0.2) : .black.opacity(0.05),
            radius: isFocused ? 12 : 4,
            x: 0,
            y: isFocused ? 6 : 2
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - 增强密码输入框
struct EnhancedSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isFocused: Bool
    @State private var isPasswordVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isFocused ? .green : .secondary)
                .frame(width: 24)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isFocused)
            
            Group {
                if isPasswordVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isPasswordVisible.toggle()
                }
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused ? Color.green.opacity(0.6) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? .green.opacity(0.2) : .black.opacity(0.05),
            radius: isFocused ? 12 : 4,
            x: 0,
            y: isFocused ? 6 : 2
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - 增强登录按钮
struct EnhancedLoginButton: View {
    let isLoading: Bool
    let isFormValid: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            guard isFormValid && !isLoading else { return }
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                    
                    Text("登录中...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("登录")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: 
                                isFormValid && !isLoading ? 
                                    [.green, .green.opacity(0.8)] : 
                                    [.gray.opacity(0.3), .gray.opacity(0.2)]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isFormValid && !isLoading ? .green.opacity(0.3) : .clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(!isFormValid || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFormValid)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLoading)
    }
}

// MARK: - 浮动装饰形状
struct FloatingShapes: View {
    @State private var moveShapes = false
    
    var body: some View {
        ZStack {
            // 浮动圆圈
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.1),
                                Color.blue.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...80))
                    .position(
                        x: moveShapes ? CGFloat.random(in: 50...350) : CGFloat.random(in: 50...350),
                        y: moveShapes ? CGFloat.random(in: 100...800) : CGFloat.random(in: 100...800)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: moveShapes
                    )
            }
        }
        .onAppear {
            moveShapes = true
        }
    }
}

// MARK: - 键盘高度监听
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

#Preview {
    LoginView()
} 