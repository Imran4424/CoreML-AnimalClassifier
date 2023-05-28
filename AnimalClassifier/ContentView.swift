//
//  ContentView.swift
//  AnimalClassifier
//
//  Created by Shah Md Imran Hossain on 28/5/23.
//

import CoreML
import PhotosUI
import SwiftUI
import Vision

struct ContentView: View {
    @State private var isShowingImagePicker = false
    @State private var imageItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var predictedAnimal: String = "None"
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        Image("dog")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                        Image("cat")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                        Image("rabbit")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
                
                VStack {
                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    }
                    
                    PhotosPicker("Select an Image to classify", selection: $imageItem, matching: .images)
                }
                .frame(maxHeight: .infinity)
            }
            .onChange(of: imageItem) { _ in
                Task {
                    if let data = try? await imageItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                            return
                        }
                    }
                    
                    print("Failed")
                }
            }
        }
    }
}

// MARK: - Actions
extension ContentView {
    func recognizeAnimal() {
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
