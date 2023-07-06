//
//  ContentView.swift
//  AnimalClassifier
//
//  Created by Shah Md Imran Hossain on 28/5/23.
//

import AVFoundation
import CoreML
import CoreVideo
import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var isShowingImagePicker = false
    @State private var imageItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var pixelBuffer: CVPixelBuffer?
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
                            pixelBuffer = convertToPixelBuffer(image: uiImage)
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
        do {
            let config = MLModelConfiguration()
            let model = try AnimalRecognitionModel(configuration: config)
            
            guard let pixelBuffer else {
                print("failed to unwrap pixel buffer")
                return
            }
            
            let prediction = try model.prediction(image: pixelBuffer)
            predictedAnimal = String(prediction.classLabel)
        } catch {
            
        }
    }
    
    func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        if status != kCVReturnSuccess {
            return nil
        }
        
        return pixelBuffer
    }
    
    func convertToPixelBuffer(image: UIImage) -> CVPixelBuffer? {
        guard let pixelBuffer = createPixelBuffer(width: Int(image.size.width), height: Int(image.size.height)) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        if let context = context {
            context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
