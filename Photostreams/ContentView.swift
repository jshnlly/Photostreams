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
    let image: UIImage
}

struct ContentView: View {
    @State private var isAuthorized = false
    private let gridItemSize: CGFloat = (UIScreen.main.bounds.width - 32)/3  // Explicit calculation including total padding
    private let columns = [
        GridItem(.fixed(UIScreen.main.bounds.width/3 - 12)),
        GridItem(.fixed(UIScreen.main.bounds.width/3 - 12)),
        GridItem(.fixed(UIScreen.main.bounds.width/3 - 12))
    ]
    
    var body: some View {
        ZStack {
            // Background blur
            Image("placeholder")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 2)
                .blur(radius: 30)
                .brightness(-0.1)
                .ignoresSafeArea()
            
            TabView {
                // First page - Single photo view
                VStack(alignment: .leading) {
                    Spacer().frame(height: 60)
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: UIScreen.main.bounds.width - 32,
                            height: UIScreen.main.bounds.height - 240
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 48, style: .continuous)
                                .stroke(.white, lineWidth: 0.5)
                        )
                    Spacer()
                }
                
                // Second page - Grid view
                VStack(alignment: .leading) {
                    Spacer().frame(height: 60)
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(0..<12, id: \.self) { index in
                                Image("placeholder")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: gridItemSize, height: gridItemSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))

            VStack {
                Text("12 new photos today")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .opacity(0.5)
                Spacer()
            }
            .padding(16)
        }
        .onAppear {
            requestPhotoLibraryAccess()
        }
    }
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.isAuthorized = true
                case .denied, .restricted:
                    self.isAuthorized = false
                case .notDetermined:
                    // This case should not occur after requesting
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
