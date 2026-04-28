//
//  ReplicateAPIManager.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 28/04/26.
//

import Foundation
import UIKit

class ReplicateAPIManager {
    
    private let apiKey = "YOUR_REPLICATE_API_KEY"
    
    func generateFaceSwap(userImageURL: String, templateImageURL: String) async throws -> String {
        
        guard let url = URL(string: "https://api.replicate.com/v1/predictions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "version": "PUT_MODEL_VERSION_ID_HERE",
            "input": [
                "source_image": userImageURL,
                "target_image": templateImageURL
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let id = json?["id"] as? String else {
            throw NSError(domain: "No ID", code: 0)
        }
        
        return id
    }
    
    // Poll result
    func getResult(predictionId: String) async throws -> String? {
        
        let url = URL(string: "https://api.replicate.com/v1/predictions/\(predictionId)")!
        
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        let status = json?["status"] as? String
        
        if status == "succeeded" {
            if let output = json?["output"] as? [String],
               let imageURL = output.first {
                return imageURL
            }
        }
        
        return nil
    }
}
