import SwiftUI
import PhotosUI
import Combine

// MARK: - Models

struct Template: Identifiable {
    let id = UUID()
    let url: String
}

struct GeneratedImage: Identifiable {
    let id = UUID()
    let outputURL: String
    let templateURL: String
    let date: Date
}

enum AppScreen {
    case home
    case confirmSelection(userImage: UIImage, template: Template)
    case result(outputURL: String, templateURL: String)
}

// MARK: - App Storage (shared state)

class AppStore: ObservableObject {
    @Published var generatedImages: [GeneratedImage] = []

    func addImage(outputURL: String, templateURL: String) {
        let img = GeneratedImage(outputURL: outputURL, templateURL: templateURL, date: Date())
        generatedImages.insert(img, at: 0)
    }
}

// MARK: - Root View with Custom Tab Bar

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeTabView(store: store)
                    .tag(0)

                ImagesTabView(store: store)
                    .tag(1)

                ProfileTabView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "wand.and.stars", label: "Home", index: 0, selectedTab: $selectedTab)
            TabBarItem(icon: "photo.stack", label: "Images", index: 1, selectedTab: $selectedTab)
            TabBarItem(icon: "person.circle", label: "Profile", index: 2, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(
            ZStack {
                // Frosted glass effect
                Color(.systemBackground).opacity(0.92)
                Rectangle()
                    .fill(.ultraThinMaterial)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let index: Int
    @Binding var selectedTab: Int

    var isSelected: Bool { selectedTab == index }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 48, height: 32)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .blue : Color(.systemGray2))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : Color(.systemGray2))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - HOME TAB

struct HomeTabView: View {
    @ObservedObject var store: AppStore
    @State private var screen: AppScreen = .home
    @State private var userImage: UIImage? = nil
    @State private var photosItem: PhotosPickerItem? = nil
    @State private var isLoadingResult = false
    @State private var showSourcePicker = false
    @State private var pendingTemplate: Template? = nil
    @State private var showCamera = false
    @State private var showGallery = false

    let dummyOutputURL = "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121952/karina-tess-l35dDPD3Gys-unsplash_1_wtqmp2.jpg"

    let templates: [Template] = [
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121966/wasis-riyan-1ev_2PFcS_U-unsplash_texbhm.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121952/karina-tess-l35dDPD3Gys-unsplash_1_wtqmp2.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121938/kyle-smith-tlowJ-oYAjU-unsplash_vui3iq.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121937/irham-setyaki-THGcjt3_MPQ-unsplash_tin53m.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121911/guilherme-caetano-pvBBA6txWKE-unsplash_wn7y2y.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121888/evan-clay-mNaom-LuQbI-unsplash_bd3vyt.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121874/brian-lawson-hpmHV56fpEY-unsplash_z75wzt.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121874/brian-lawson-Bnd33ZgqIX8-unsplash_jnvdw4.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121833/allef-vinicius-Pvn8iP3EAmE-unsplash_fjk7k5.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121816/amirr-zolfaghari-nHUUjcO3Ypk-unsplash_szr5xm.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121816/amir-abbaspoor-zK1IABUPZ0o-unsplash_tssh65.jpg"),
        Template(url: "https://res.cloudinary.com/djp2jaxxh/image/upload/v1777121817/arturo-anez-5FL9DVBl9W8-unsplash_c2cljq.jpg")
    ]

    var body: some View {
        ZStack {
            switch screen {
            case .home:
                HomeScreen(
                    templates: templates,
                    onTemplateTapped: { template in
                        pendingTemplate = template
                        showSourcePicker = true
                    }
                )

            case .confirmSelection(let userImg, let tmpl):
                ConfirmView(
                    userImage: userImg,
                    template: tmpl,
                    isLoading: $isLoadingResult,
                    onSubmit: {
                        isLoadingResult = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isLoadingResult = false
                            store.addImage(outputURL: dummyOutputURL, templateURL: tmpl.url)
                            screen = .result(outputURL: dummyOutputURL, templateURL: tmpl.url)
                        }
                    },
                    onCancel: {
                        userImage = nil
                        photosItem = nil
                        screen = .home
                    },
                    onChangePhoto: {
                        screen = .home
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pendingTemplate = tmpl
                            showSourcePicker = true
                        }
                    }
                )

            case .result(let outputURL, _):
                ResultView(
                    outputURL: outputURL,
                    onBack: {
                        userImage = nil
                        photosItem = nil
                        screen = .home
                    }
                )
            }

            // Source picker overlay
            if showSourcePicker {
                SourcePickerOverlay(
                    onGallery: {
                        showSourcePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showGallery = true
                        }
                    },
                    onCamera: {
                        showSourcePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showCamera = true
                        }
                    },
                    onDismiss: {
                        showSourcePicker = false
                        pendingTemplate = nil
                    }
                )
                .zIndex(10)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showSourcePicker)
            }
        }
        .photosPicker(isPresented: $showGallery, selection: $photosItem, matching: .images)
        .onChange(of: photosItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data),
                   let tmpl = pendingTemplate {
                    await MainActor.run {
                        userImage = img
                        screen = .confirmSelection(userImage: img, template: tmpl)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { img in
                showCamera = false
                if let img = img, let tmpl = pendingTemplate {
                    userImage = img
                    screen = .confirmSelection(userImage: img, template: tmpl)
                }
            }
        }
    }
}

// MARK: - Home Screen

struct HomeScreen: View {
    let templates: [Template]
    let onTemplateTapped: (Template) -> Void
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Banner
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(18)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Transform Yourself")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Pick a template and let AI do the magic")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(20)
                    }
                    .frame(height: 100)
                    .padding(.horizontal)
                    .padding(.top, 4)

                    Text("Choose a Template")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(templates) { template in
                            TemplateCell(template: template, onTap: { onTemplateTapped(template) })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // space for tab bar
                }
                .padding(.top, 12)
            }
            .navigationTitle("AI Styler")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Template Cell

struct TemplateCell: View {
    let template: Template
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            AsyncImage(url: URL(string: template.url)) { phase in
                switch phase {
                case .empty:
                    ZStack { Color(.systemGray5); ProgressView() }
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    ZStack { Color(.systemGray5); Image(systemName: "photo").foregroundColor(.secondary) }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Source Picker Overlay

struct SourcePickerOverlay: View {
    let onGallery: () -> Void
    let onCamera: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                        .padding(.bottom, 4)
                    Text("Upload Your Photo")
                        .font(.title3).fontWeight(.bold)
                    Text("Choose how you'd like to add your photo")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28).padding(.horizontal, 24).padding(.bottom, 24)

                Divider()

                Button(action: onGallery) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.12))
                                .frame(width: 46, height: 46)
                            Image(systemName: "photo.on.rectangle").font(.system(size: 20)).foregroundColor(.blue)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Choose from Gallery").font(.body).fontWeight(.semibold).foregroundColor(.primary)
                            Text("Pick a photo from your library").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.footnote)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 18)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 86)

                Button(action: onCamera) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.purple.opacity(0.12))
                                .frame(width: 46, height: 46)
                            Image(systemName: "camera.fill").font(.system(size: 20)).foregroundColor(.purple)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Open Camera").font(.body).fontWeight(.semibold).foregroundColor(.primary)
                            Text("Take a new photo right now").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(Color(.systemGray3)).font(.footnote)
                    }
                    .padding(.horizontal, 24).padding(.vertical, 18)
                }
                .buttonStyle(.plain)

                Divider()

                Button(action: onDismiss) {
                    Text("Cancel").font(.body).fontWeight(.medium).foregroundColor(.red)
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                }
                .buttonStyle(.plain)
            }
            .background(Color(.systemBackground))
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 10)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Confirm View

struct ConfirmView: View {
    let userImage: UIImage
    let template: Template
    @Binding var isLoading: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let onChangePhoto: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Looking good! Ready to transform?")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal).padding(.top, 20)

                        HStack(spacing: 12) {
                            VStack(spacing: 8) {
                                Text("Your Photo")
                                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                Image(uiImage: userImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 155, height: 220).clipped().cornerRadius(16)
                                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                            VStack {
                                Spacer()
                                Image(systemName: "plus.circle.fill").font(.title).foregroundColor(.blue)
                                Spacer()
                            }
                            .frame(height: 220)
                            VStack(spacing: 8) {
                                Text("Template")
                                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                AsyncImage(url: URL(string: template.url)) { phase in
                                    switch phase {
                                    case .success(let image): image.resizable().scaledToFill()
                                    case .empty: ProgressView()
                                    default: Color(.systemGray5)
                                    }
                                }
                                .frame(width: 155, height: 220).clipped().cornerRadius(16)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal)

                        HStack(spacing: 10) {
                            Image(systemName: "sparkles").foregroundColor(.purple)
                            Text("AI will place your face onto the template's outfit and pose")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(12)
                        .padding(.horizontal)

                        Button(action: onChangePhoto) {
                            Label("Change Photo", systemImage: "arrow.triangle.2.circlepath")
                                .font(.subheadline).foregroundColor(.blue)
                        }
                        Spacer(minLength: 20)
                    }
                }

                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 14) {
                        Button(action: onCancel) {
                            Text("Cancel").fontWeight(.medium).foregroundColor(.primary)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color(.systemGray5)).cornerRadius(14)
                        }
                        Button(action: onSubmit) {
                            HStack(spacing: 8) {
                                if isLoading { ProgressView().tint(.white).scaleEffect(0.85) }
                                else { Image(systemName: "sparkles") }
                                Text(isLoading ? "Generating..." : "Generate").fontWeight(.semibold)
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(isLoading ? Color.gray : Color.blue).cornerRadius(14)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal).padding(.top, 14).padding(.bottom, 28)
                }
            }
            .navigationTitle("Confirm").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Result View

struct ResultView: View {
    let outputURL: String
    let onBack: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Your AI-generated image is ready! 🎉")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal).padding(.top, 12)

                        AsyncImage(url: URL(string: outputURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit().cornerRadius(18)
                                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)
                                    .padding(.horizontal)
                            case .empty: ProgressView("Loading result...").frame(height: 300)
                            case .failure: Text("Failed to load result").foregroundColor(.red).frame(height: 300)
                            @unknown default: EmptyView()
                            }
                        }
                        Spacer(minLength: 100)
                    }
                }
                VStack(spacing: 0) {
                    Divider()
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Start Over").fontWeight(.semibold)
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.blue).cornerRadius(14)
                    }
                    .padding(.horizontal).padding(.top, 14).padding(.bottom, 28)
                }
            }
            .navigationTitle("Result ✨").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Camera Wrapper

struct CameraView: UIViewControllerRepresentable {
    let onImage: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onImage(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onImage(nil) }
    }
}

// MARK: - IMAGES TAB

struct ImagesTabView: View {
    @ObservedObject var store: AppStore
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            Group {
                if store.generatedImages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 60))
                            .foregroundColor(Color(.systemGray3))
                        Text("No images yet")
                            .font(.title3).fontWeight(.semibold)
                        Text("Generate your first AI image from the Home tab")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.generatedImages) { item in
                                GeneratedImageCell(item: item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("My Images")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GeneratedImageCell: View {
    let item: GeneratedImage
    @State private var showFullScreen = false

    var body: some View {
        Button(action: { showFullScreen = true }) {
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: item.outputURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ZStack { Color(.systemGray5); ProgressView() }
                    default:
                        Color(.systemGray5)
                    }
                }
                .frame(height: 200)
                .clipped()

                // Date footer
                HStack {
                    Text(item.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showFullScreen) {
            ImageFullScreenView(imageURL: item.outputURL, onDismiss: { showFullScreen = false })
        }
    }
}

struct ImageFullScreenView: View {
    let imageURL: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit().ignoresSafeArea()
                case .empty:
                    ProgressView().tint(.white)
                default:
                    Image(systemName: "photo").foregroundColor(.white).font(.largeTitle)
                }
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding(20)
            .padding(.top, 40)
        }
    }
}

// MARK: - PROFILE TAB

struct ProfileTabView: View {
    @State private var notificationsOn = true
    @State private var saveToPhotos = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Avatar + Name
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            Text("V")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Vikram Kumar")
                            .font(.title2).fontWeight(.bold)
                        Text("vikram@example.com")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Stats row
                    HStack(spacing: 0) {
                        StatBlock(value: "12", label: "Generated")
                        Divider().frame(height: 40)
                        StatBlock(value: "3", label: "Templates Used")
                        Divider().frame(height: 40)
                        StatBlock(value: "5", label: "Saved")
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Settings Section
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: "Preferences")

                        SettingsToggleRow(
                            icon: "bell.fill",
                            iconColor: .orange,
                            label: "Notifications",
                            isOn: $notificationsOn
                        )
                        Divider().padding(.leading, 56)
                        SettingsToggleRow(
                            icon: "arrow.down.circle.fill",
                            iconColor: .green,
                            label: "Auto-save to Photos",
                            isOn: $saveToPhotos
                        )
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Account Section
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: "Account")

                        SettingsNavRow(icon: "person.fill", iconColor: .blue, label: "Edit Profile")
                        Divider().padding(.leading, 56)
                        SettingsNavRow(icon: "lock.fill", iconColor: .gray, label: "Privacy & Security")
                        Divider().padding(.leading, 56)
                        SettingsNavRow(icon: "questionmark.circle.fill", iconColor: .teal, label: "Help & Support")
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Sign out
                    Button(action: {}) {
                        Text("Sign Out")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white)
            }
            Text(label).font(.body)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white)
            }
            Text(label).font(.body)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(Color(.systemGray3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    ContentView()
}
