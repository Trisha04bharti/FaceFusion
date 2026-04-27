//
//  FirestoreService.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 26/04/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirestoreService {

    static let db = Firestore.firestore()

    // MARK: - Save generated image to Firestore
    static func saveGeneratedImage(outputURL: String, templateURL: String, completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("outputs")
            .addDocument(data: [
                "outputURL": outputURL,
                "templateURL": templateURL,
                "createdAt": Timestamp()
            ]) { error in
                completion?(error)
            }
    }

    // MARK: - Fetch all generated images for current user
    static func fetchGeneratedImages(completion: @escaping ([GeneratedImage]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users")
            .document(uid)
            .collection("outputs")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let images = documents.compactMap { doc -> GeneratedImage? in
                    let data = doc.data()
                    guard let outputURL = data["outputURL"] as? String,
                          let templateURL = data["templateURL"] as? String,
                          let timestamp = data["createdAt"] as? Timestamp else { return nil }
                    return GeneratedImage(
                        id: UUID(),
                        outputURL: outputURL,
                        templateURL: templateURL,
                        date: timestamp.dateValue()
                    )
                }

                completion(images)
            }
    }
}
