//
//  FaceFusionApp.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 20/04/26.
//

//import SwiftUI
//
//@main
//struct FaceFusionApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


import SwiftUI
import Firebase

@main
struct AIStylerApp: App {

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var auth2 = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Root View (decides Login or Main App)
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .animation(.easeInOut, value: authViewModel.isLoggedIn)
    }
}
