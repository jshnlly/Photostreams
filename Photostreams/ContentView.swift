//
//  ContentView.swift
//  Photostreams
//
//  Created by Josh Nelson on 12/6/24.
//

import SwiftUI
import SwiftData

struct Photo: Identifiable {
    let id: UUID
    let image: UIImage
    let profileImage: UIImage
    var isUserPhoto: Bool
}

struct ContentView: View {
    @State private var selectedPhoto: Photo?
    @Namespace private var animation
    
    // Grid layout configuration
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    // Add sample data
    private let samplePhotos: [Photo] = (1...12).map { _ in
        Photo(
            id: UUID(),
            image: UIImage(named: "placeholder") ?? UIImage(),
            profileImage: UIImage(named: "profile-placeholder") ?? UIImage(),
            isUserPhoto: Bool.random()
        )
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Photostreams")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(samplePhotos) { photo in
                            if selectedPhoto?.id != photo.id {
                                ZStack(alignment: .topLeading) {
                                    // Main image
                                    Image(uiImage: photo.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipped()
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                                        )
                                        .matchedGeometryEffect(id: photo.id, in: animation)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0)) {
                                                selectedPhoto = photo
                                            }
                                        }
                                        .zIndex(0)
                                    
                                    // Profile image
                                    Image(uiImage: photo.profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                        .padding(12)
                                }
                            } else {
                                Color.clear
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .padding(8)
                }
            }
            
            // Expanded image overlay
            if let photo = selectedPhoto {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0)) {
                                selectedPhoto = nil
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                        }
                        Spacer()
                    }
                    
                    Image(uiImage: photo.image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: selectedPhoto?.id == photo.id ? UIScreen.main.bounds.width - 24 : UIScreen.main.bounds.width/3 - 16,
                            height: selectedPhoto?.id == photo.id ? UIScreen.main.bounds.height - 320 : UIScreen.main.bounds.width/3 - 16
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                        )
                        .clipped()
                        .matchedGeometryEffect(id: photo.id, in: animation)
                        .padding()
                    
                    Spacer()
                }
                .zIndex(2)
            }
        }
    }
}
#Preview {
    ContentView()
}
