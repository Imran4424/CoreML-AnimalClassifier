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
    @State private var predictedAnimal: String = "Processing"
    @State private var ciImage = CIImage()
    
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
                        
                        Text("Predicted Animal - \(predictedAnimal)")
                    }
                    
                    Spacer()
                    PhotosPicker("Select an Image to classify", selection: $imageItem, matching: .images)
                    Spacer()
                    
                    Button("RECOGNIZE") {
                        recognizeAnimal()
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .onChange(of: imageItem) { _ in
                Task {
                    if let data = try? await imageItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            selectedImage = Image(uiImage: uiImage)
                            // clearing data after selection
                            predictedAnimal = "Processing"
                            
                            ciImage = CIImage(image: uiImage)!
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
        guard let model = try? VNCoreMLModel(for: AnimalRecognitionModel(configuration: MLModelConfiguration()).model) else {
            fatalError("Can not load CoreML model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                predictedAnimal = "Unable to process Imge"
//                fatalError("Model failed to process image")
                return
            }
            
            guard let firstResult = results.first else {
                fatalError("can not fetch first result")
            }
            
            predictedAnimal = firstResult.identifier
            
            print(results)
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
