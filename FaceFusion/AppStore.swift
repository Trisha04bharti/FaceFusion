//
//  AppStore.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 26/04/26.
//

import Foundation
import Combine

class AppStore: ObservableObject {
    @Published var generatedImages: [GeneratedImage] = []
    @Published var isLoadingImages: Bool = false

    // MARK: - Load from Firestore
    func loadImages() {
        isLoadingImages = true
        FirestoreService.fetchGeneratedImages { [weak self] images in
            DispatchQueue.main.async {
                self?.generatedImages = images
                self?.isLoadingImages = false
            }
        }
    }

    // MARK: - Add locally + save to Firestore
    func addImage(outputURL: String, templateURL: String) {
        let img = GeneratedImage(id: UUID(), outputURL: outputURL, templateURL: templateURL, date: Date())
        generatedImages.insert(img, at: 0)
        FirestoreService.saveGeneratedImage(outputURL: outputURL, templateURL: templateURL)
    }
}
