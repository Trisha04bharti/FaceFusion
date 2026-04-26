//
//  AuthViewModel.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 26/04/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserModel? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    // MARK: - Listen to Firebase Auth State
    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.fetchUserData(uid: user.uid)
            } else {
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.currentUser = nil
                }
            }
        }
    }

    // MARK: - Fetch user data from Firestore
    func fetchUserData(uid: String) {
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let data = snapshot?.data() {
                    self.currentUser = UserModel(
                        uid: uid,
                        email: data["email"] as? String ?? "",
                        username: data["username"] as? String ?? "",
                        profileImageURL: data["profileImageURL"] as? String
                    )
                }
                self.isLoggedIn = true
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }

            // Save user to Firestore
            let userData: [String: Any] = [
                "email": email,
                "username": username,
                "createdAt": Timestamp(),
                "profileImageURL": ""
            ]

            Firestore.firestore().collection("users").document(user.uid).setData(userData) { [weak self] error in
                guard let self = self else { return }

                // Send welcome/verification email
                user.sendEmailVerification { _ in }

                DispatchQueue.main.async {
                    self.isLoading = false
                    if error == nil {
                        self.currentUser = UserModel(uid: user.uid, email: email, username: username, profileImageURL: nil)
                        self.isLoggedIn = true
                        completion(true)
                    } else {
                        self.errorMessage = "Failed to save user data."
                        completion(false)
                    }
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    // MARK: - Logout
    func logout() {
        try? Auth.auth().signOut()
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.currentUser = nil
        }
    }

    // MARK: - Update profile image URL
    func updateProfileImage(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData(["profileImageURL": url])
        DispatchQueue.main.async {
            self.currentUser?.profileImageURL = url
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

// MARK: - User Model
struct UserModel {
    let uid: String
    let email: String
    let username: String
    var profileImageURL: String?
}
