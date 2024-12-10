//
//  ContentView.swift
//  Photostreams
//
//  Created by Josh Nelson on 12/6/24.
//

import SwiftUI
import SwiftData
import Photos

struct Photo: Identifiable {
    let id = UUID()
    let asset: PHAsset
    let image: UIImage
}

struct ContentView: View {
    @State private var isAuthorized = false
    @State private var todaysPhotos: [Photo] = []
    @State private var currentPhotoIndex = 0
    @State private var isLoading = true
    @State private var currentPage = 0
    @State private var showCamera = false
    private let gridItemSize: CGFloat = (UIScreen.main.bounds.width - 40)/3
    private let columns = [
        GridItem(.fixed(UIScreen.main.bounds.width/3 - 12)),
        GridItem(.fixed(UIScreen.main.bounds.width/3 - 12)),
        GridItem(.fixed(UIScreen.main.bounds.width/3 - 12))
    ]
    
    // Timer for cycling through photos
    let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
#if DEBUG
    private let debugNoPhotos = false  // Set this to true to simulate no photos
#endif
    
    @State private var yesterdaysPhotos: [Photo] = []
    @State private var yesterdayPhotoIndex = 0
    @State private var showingYesterday = false
    @State private var imageHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    @State private var imageWidth: CGFloat = UIScreen.main.bounds.width - 32
    @State private var isPaused = false
    @State private var photoRefreshToken = UUID()
    
    var body: some View {
        ZStack {
            // Background blur
            if let firstPhoto = showingYesterday ? yesterdaysPhotos.first : todaysPhotos.first {
                Image(uiImage: firstPhoto.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 2)
                    .blur(radius: 30)
                    .brightness(-0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingYesterday.toggle()
                        }
                        generateButtonHapticFeedback()
                    }
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 2)
                    .blur(radius: 30)
                    .brightness(-0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingYesterday.toggle()
                        }
                        generateButtonHapticFeedback()
                    }
            }
            
            TabView(selection: $currentPage) {
                // Single photo view
                VStack {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else {
                        if !(showingYesterday ? yesterdaysPhotos.isEmpty : todaysPhotos.isEmpty) {
                            Image(uiImage: showingYesterday ? yesterdaysPhotos[yesterdayPhotoIndex].image : todaysPhotos[currentPhotoIndex].image)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: imageWidth,
                                    height: imageHeight
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .onLongPressGesture(minimumDuration: 0.1) { isPressing in
                                    isPaused = isPressing
                                    if isPressing {
                                        generateButtonHapticFeedback()
                                    }
                                } perform: {
                                    // Do nothing on completion
                                }
                        } else {
                            Rectangle()
                                .fill(.black.opacity(0.15))
                                .frame(
                                    width: imageWidth,
                                    height: imageHeight
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .overlay(
                                    Button(action: {
                                        generateButtonHapticFeedback()
                                        showCamera = true
                                    }) {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16))
                                            Text("Take a Photo")
                                                .font(.headline)
                                                .padding(.top, 8)
                                        }
                                        .foregroundColor(.white)
                                    }
                                )
                        }
                        Spacer()
                    }
                }
                .padding(.top, 60)
                .tag(0)
                
                // Grid view
                if !(showingYesterday ? yesterdaysPhotos.isEmpty : todaysPhotos.isEmpty) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(showingYesterday ? yesterdaysPhotos : todaysPhotos) { photo in
                                    Image(uiImage: photo.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: gridItemSize, height: gridItemSize)
                                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 60)
                    }
                    .refreshable {
                        if showingYesterday {
                            fetchYesterdaysPhotos()
                        } else {
                            fetchTodaysPhotos()
                        }
                    }
                    .tag(1)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height - 32)
            .padding(.bottom, 64)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            
            VStack(alignment: .center) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            generateButtonHapticFeedback()
                            showCamera = true
                        }
                    Spacer()
                    HStack(spacing: 4) {
                        Text(showingYesterday ? "Yesterday" : "Today")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .opacity(1)
                        Text(showingYesterday ? "\(yesterdaysPhotos.count)" : "\(todaysPhotos.count)")
                            .foregroundColor(.white)
                            .opacity(0.5)
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingYesterday.toggle()
                        }
                        generateButtonHapticFeedback()
                    }
                    Spacer()
                    Menu {
                        Button {
                            let testFlightLink = "https://testflight.apple.com/join/FrVGZvfC"
                            let activityVC = UIActivityViewController(
                                activityItems: [testFlightLink],
                                applicationActivities: nil
                            )
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                activityVC.popoverPresentationController?.sourceView = rootVC.view
                                rootVC.present(activityVC, animated: true)
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            if let instagramURL = URL(string: "instagram://user?username=jnelly2"),
                               UIApplication.shared.canOpenURL(instagramURL) {
                                UIApplication.shared.open(instagramURL)
                            } else if let webURL = URL(string: "https://instagram.com/jnelly2") {
                                UIApplication.shared.open(webURL)
                            }
                        } label: {
                            Label("Send Feedback", systemImage: "arrow.up.forward.app")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(8)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    let testFlightLink = "https://testflight.apple.com/join/FrVGZvfC"
                                    let activityVC = UIActivityViewController(
                                        activityItems: [testFlightLink],
                                        applicationActivities: nil
                                    )
                                    
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first,
                                       let rootVC = window.rootViewController {
                                        activityVC.popoverPresentationController?.sourceView = rootVC.view
                                        rootVC.present(activityVC, animated: true)
                                    }
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                
                                Button {
                                    if let instagramURL = URL(string: "instagram://user?username=jnelly2"),
                                       UIApplication.shared.canOpenURL(instagramURL) {
                                        UIApplication.shared.open(instagramURL)
                                    } else if let webURL = URL(string: "https://instagram.com/jnelly2") {
                                        UIApplication.shared.open(webURL)
                                    }
                                } label: {
                                    Label("Send Feedback", systemImage: "arrow.up.forward.app")
                                }
                            }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: UIScreen.main.bounds.width - 32, maxHeight: UIScreen.main.bounds.height - 32)
            .padding(.top, 64)
        }
        .ignoresSafeArea()
        .onAppear {
            requestPhotoLibraryAccess()
            fetchYesterdaysPhotos()
        }
        .onReceive(timer) { _ in
            // Skip if paused or camera is showing
            guard !isPaused && !showCamera else { return }
            
            if !todaysPhotos.isEmpty {
                currentPhotoIndex = (currentPhotoIndex + 1) % todaysPhotos.count
            }
            if !yesterdaysPhotos.isEmpty {
                yesterdayPhotoIndex = (yesterdayPhotoIndex + 1) % yesterdaysPhotos.count
            }
            
            // Only play haptic if we're on the single photo view (page 0)
            // AND we have multiple photos to display
            let currentPhotos = showingYesterday ? yesterdaysPhotos : todaysPhotos
            if currentPage == 0 && currentPhotos.count > 1 {
                generateHapticFeedback()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera)
                .edgesIgnoringSafeArea(.all)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshPhotos"))) { _ in
            // Small delay to ensure photo is saved before refreshing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fetchTodaysPhotos()
            }
        }
    }
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.isAuthorized = true
                    self.fetchTodaysPhotos()
                    self.fetchYesterdaysPhotos()
                case .denied, .restricted:
                    self.isAuthorized = false
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func fetchTodaysPhotos() {
        isLoading = true
        // Clear the array before fetching
        DispatchQueue.main.async {
            self.todaysPhotos.removeAll()
        }
        
        #if DEBUG
        if debugNoPhotos {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        #endif
        
        let fetchOptions = PHFetchOptions()
        
        // Create date range for today (midnight to midnight)
        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) else { return }
        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else { return }
        
        // Create fetch predicate for today's photos
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        assets.enumerateObjects { (asset, count, stop) in
            let imageManager = PHImageManager.default()
            let imageOptions = PHImageRequestOptions()
            imageOptions.isSynchronous = true
            imageOptions.deliveryMode = .highQualityFormat
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 800),
                contentMode: .aspectFill,
                options: imageOptions
            ) { image, _ in
                if let image = image {
                    DispatchQueue.main.async {
                        self.todaysPhotos.append(Photo(asset: asset, image: image))
                        if count == assets.count - 1 {
                            self.isLoading = false
                        }
                    }
                }
            }
        }
        
        // If there are no assets, end loading immediately
        if assets.count == 0 {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func generateHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    private func generateButtonHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)  // Using medium for button press
        generator.impactOccurred()
    }
    
    private func fetchYesterdaysPhotos() {
        // Clear the array before fetching
        DispatchQueue.main.async {
            self.yesterdaysPhotos.removeAll()
        }
        
        #if DEBUG
        if debugNoPhotos {
            return
        }
        #endif
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfYesterday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -1, to: now)!) else { return }
        guard let endOfYesterday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfYesterday) else { return }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startOfYesterday as NSDate, endOfYesterday as NSDate)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        assets.enumerateObjects { (asset, count, stop) in
            let imageManager = PHImageManager.default()
            let imageOptions = PHImageRequestOptions()
            imageOptions.isSynchronous = true
            imageOptions.deliveryMode = .highQualityFormat
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 800),
                contentMode: .aspectFill,
                options: imageOptions
            ) { image, _ in
                if let image = image {
                    DispatchQueue.main.async {
                        self.yesterdaysPhotos.append(Photo(asset: asset, image: image))
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        // Remove any extra UI elements
        picker.modalPresentationStyle = .fullScreen
        picker.navigationBar.isHidden = true
        picker.toolbarItems = nil
        picker.toolbar.isHidden = true
        
        // Adjust the camera view to fill the screen
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.showsCameraControls = true
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Save image to photo library
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveComplete), nil)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        @objc func saveComplete(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            // Notify parent view to refresh photos
            NotificationCenter.default.post(name: NSNotification.Name("RefreshPhotos"), object: nil)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
