//
//  SignupView.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 26/04/26.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showSuccessAlert = false

    var passwordsMatch: Bool { password == confirmPassword }
    var formValid: Bool { !username.isEmpty && !email.isEmpty && password.count >= 6 && passwordsMatch }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)

                    Text("Create Account")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("Join AI Styler today")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.bottom, 36)

                // MARK: Form
                VStack(spacing: 16) {

                    // Username
                    FormField(
                        icon: "person",
                        placeholder: "Username",
                        label: "Username",
                        text: $username
                    )

                    // Email
                    FormField(
                        icon: "envelope",
                        placeholder: "you@example.com",
                        label: "Email",
                        text: $email,
                        keyboardType: .emailAddress
                    )

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "lock").foregroundColor(.secondary)
                            if showPassword {
                                TextField("Min. 6 characters", text: $password)
                            } else {
                                SecureField("Min. 6 characters", text: $password)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption2).foregroundColor(.orange)
                        }
                    }

                    // Confirm Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "lock.shield").foregroundColor(.secondary)
                            if showConfirmPassword {
                                TextField("Re-enter password", text: $confirmPassword)
                            } else {
                                SecureField("Re-enter password", text: $confirmPassword)
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    !confirmPassword.isEmpty && !passwordsMatch ? Color.red : Color.clear,
                                    lineWidth: 1.5
                                )
                        )

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.caption2).foregroundColor(.red)
                        }
                    }

                    // Error
                    if let error = authViewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                            Text(error).font(.caption).foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    }

                    // Signup button
                    Button(action: handleSignup) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(authViewModel.isLoading ? "Creating Account..." : "Create Account")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.purple, .pink],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                    }
                    .disabled(!formValid || authViewModel.isLoading)
                    .opacity(formValid ? 1 : 0.6)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)

                // Already have account
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.secondary).font(.subheadline)
                    Button(action: { dismiss() }) {
                        Text("Sign In")
                            .fontWeight(.semibold).foregroundColor(.blue)
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .alert("Welcome to AI Styler! 🎉", isPresented: $showSuccessAlert) {
            Button("Get Started") { }
        } message: {
            Text("A verification email has been sent to \(email). You can verify it anytime.")
        }
    }

    func handleSignup() {
        authViewModel.signUp(email: email, password: password, username: username) { success in
            if success {
                showSuccessAlert = true
            }
        }
    }
}

// MARK: - Reusable Form Field
struct FormField: View {
    let icon: String
    let placeholder: String
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            HStack {
                Image(systemName: icon).foregroundColor(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        SignupView().environmentObject(AuthViewModel())
    }
}
