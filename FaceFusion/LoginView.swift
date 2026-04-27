//
//  LoginView.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 26/04/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var goToSignup = false
    @State private var showPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 50)

                        Text("AI Styler")
                            .font(.largeTitle).fontWeight(.bold)
                        Text("Sign in to your account")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)

                    // MARK: Form
                    VStack(spacing: 16) {

                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "envelope").foregroundColor(.secondary)
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "lock").foregroundColor(.secondary)
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                } else {
                                    SecureField("Enter password", text: $password)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Error
                        if let error = authViewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                                Text(error).font(.caption).foregroundColor(.red)
                            }
                            .padding(.top, 4)
                        }

                        // Login button
                        Button(action: handleLogin) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView().tint(.white)
                                }
                                Text(authViewModel.isLoading ? "Signing in..." : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.blue, .purple],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)

                    // MARK: Signup link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary).font(.subheadline)
                        Button(action: { goToSignup = true }) {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 28)
                }
            }
            .navigationDestination(isPresented: $goToSignup) {
                SignupView().environmentObject(authViewModel)
            }
            .navigationBarHidden(true)
        }
    }

    func handleLogin() {
        authViewModel.login(email: email, password: password) { _ in }
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
