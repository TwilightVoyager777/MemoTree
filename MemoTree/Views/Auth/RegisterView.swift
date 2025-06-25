//
//  RegisterView.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import SwiftUI
import Combine

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 25) {
                        // 标题
                        VStack(spacing: 8) {
                            Text("创建账号")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("加入MemoTree，开始你的城市探索之旅")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 30)
                        
                        // 注册表单
                        VStack(spacing: 16) {
                            // 用户名
                            CustomTextField(
                                icon: "person",
                                placeholder: "用户名",
                                text: $username
                            )
                            
                            // 邮箱
                            CustomTextField(
                                icon: "envelope",
                                placeholder: "邮箱地址",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            
                            // 昵称（可选）
                            CustomTextField(
                                icon: "heart",
                                placeholder: "昵称（可选）",
                                text: $nickname
                            )
                            
                            // 密码
                            CustomSecureField(
                                icon: "lock",
                                placeholder: "密码（至少6位）",
                                text: $password
                            )
                            
                            // 确认密码
                            CustomSecureField(
                                icon: "lock.fill",
                                placeholder: "确认密码",
                                text: $confirmPassword
                            )
                            
                            // 密码强度提示
                            if !password.isEmpty {
                                HStack {
                                    Image(systemName: passwordStrengthIcon)
                                        .foregroundColor(passwordStrengthColor)
                                    Text(passwordStrengthText)
                                        .font(.footnote)
                                        .foregroundColor(passwordStrengthColor)
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 注册按钮
                        Button(action: handleRegister) {
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("注册中...")
                                }
                            } else {
                                Text("创建账号")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(registerButtonBackground)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal, 20)
                        
                        // 用户协议
                        VStack(spacing: 8) {
                            Text("注册即表示你同意我们的")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Button("用户协议") {
                                    // TODO: 显示用户协议
                                }
                                .foregroundColor(.green)
                                .font(.footnote)
                                
                                Text("和")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                Button("隐私政策") {
                                    // TODO: 显示隐私政策
                                }
                                .foregroundColor(.green)
                                .font(.footnote)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("注册")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 计算属性
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        isValidEmail(email)
    }
    
    private var registerButtonBackground: Color {
        isFormValid ? .green : Color(.systemGray4)
    }
    
    private var passwordStrengthIcon: String {
        if password.count < 6 {
            return "xmark.circle"
        } else if password.count < 8 {
            return "checkmark.circle"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var passwordStrengthColor: Color {
        if password.count < 6 {
            return .red
        } else if password.count < 8 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var passwordStrengthText: String {
        if password.count < 6 {
            return "密码至少需要6位字符"
        } else if password.count < 8 {
            return "密码强度：一般"
        } else {
            return "密码强度：良好"
        }
    }
    
    // MARK: - 方法
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func handleRegister() {
        guard isFormValid else { return }
        
        isLoading = true
        
        authService.register(
            username: username,
            email: email,
            password: password,
            nickname: nickname.isEmpty ? nil : nickname
        )
        .sink(
            receiveCompletion: { completion in
                DispatchQueue.main.async {
                    isLoading = false
                    if case .failure(let error) = completion {
                        alertTitle = "注册失败"
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            },
            receiveValue: { success in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        dismiss()
                    } else {
                        alertTitle = "注册失败"
                        alertMessage = "请检查输入信息是否正确"
                        showingAlert = true
                    }
                }
            }
        )
        .store(in: &cancellables)
    }
}

// MARK: - 自定义输入框组件
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    
    init(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RegisterView()
} 