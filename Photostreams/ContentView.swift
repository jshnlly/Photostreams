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
    
    var body: some View {
        ZStack {
            // Background blur
            if let firstPhoto = todaysPhotos.first {
                Image(uiImage: firstPhoto.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 2)
                    .blur(radius: 30)
                    .brightness(-0.1)
                    .ignoresSafeArea()
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 2)
                    .blur(radius: 30)
                    .brightness(-0.1)
                    .ignoresSafeArea()
            }
            
            TabView(selection: $currentPage) {
                // First page - Single photo view
                VStack {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else {
                        if !todaysPhotos.isEmpty {
                            Image(uiImage: todaysPhotos[currentPhotoIndex].image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: UIScreen.main.bounds.width - 32)
                                .frame(height: UIScreen.main.bounds.height * 0.6)
                                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                                )
                        } else {
                            Rectangle()
                                .fill(.black.opacity(0.15))
                                .frame(
                                    width: UIScreen.main.bounds.width - 32,
                                    height: UIScreen.main.bounds.height * 0.7
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
                                        VStack() {
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
                    }
                    Spacer()
                }
                .padding(.top, 60)
                .tag(0)
                
                // Second page - Grid view (only show if there are photos)
                if !todaysPhotos.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                            } else {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(todaysPhotos) { photo in
                                        Image(uiImage: photo.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: gridItemSize, height: gridItemSize)
                                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 60)
                    }
                    .tag(1)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height - 32)
            .padding(.bottom, 64)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            
            VStack(alignment: .center) {
                Text("\(todaysPhotos.count) new photos today")
                    .foregroundColor(.white)
                    .opacity(0.5)
                
                Spacer()
            }
            .frame(maxHeight: UIScreen.main.bounds.height - 32)
            .padding(.top, 80)
        }
        .frame(maxHeight: UIScreen.main.bounds.height - 32)
        .onAppear {
            requestPhotoLibraryAccess()
        }
        .onReceive(timer) { _ in
            if !todaysPhotos.isEmpty {
                currentPhotoIndex = (currentPhotoIndex + 1) % todaysPhotos.count
                if currentPage == 0 {
                    generateHapticFeedback()
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera)
        }
    }
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.isAuthorized = true
                    self.fetchTodaysPhotos()
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
        
        #if DEBUG
        if debugNoPhotos {
            DispatchQueue.main.async {
                self.todaysPhotos = []
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
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
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
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
