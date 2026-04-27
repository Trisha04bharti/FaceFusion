//
//  CloudinaryService.swift
//  FaceFusion
//
//  Created by Vikram Kumar on 26/04/26.
//

import UIKit
import Foundation

class CloudinaryService {

    // ⚠️ Replace these with your actual Cloudinary credentials
    static let cloudName = "djp2jaxxh"
    static let uploadPreset = "facefusion_upload"  // Must be set to UNSIGNED in Cloudinary dashboard

    // MARK: - Upload UIImage to Cloudinary, returns secure URL
    static func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(CloudinaryError.imageConversionFailed))
            return
        }

        guard let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload") else {
            completion(.failure(CloudinaryError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Upload preset field
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n")
        body.appendString("\(uploadPreset)\r\n")

        // Image field
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n")

        body.appendString("--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(CloudinaryError.noData))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let secureURL = json["secure_url"] as? String {
                        completion(.success(secureURL))
                    } else if let errorInfo = json["error"] as? [String: Any],
                              let message = errorInfo["message"] as? String {
                        completion(.failure(CloudinaryError.serverError(message)))
                    } else {
                        completion(.failure(CloudinaryError.noURL))
                    }
                }
            } catch {
                completion(.failure(error))
            }

        }.resume()
    }
}

// MARK: - Errors
enum CloudinaryError: LocalizedError {
    case imageConversionFailed
    case invalidURL
    case noData
    case noURL
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Failed to convert image."
        case .invalidURL: return "Invalid Cloudinary URL."
        case .noData: return "No data received."
        case .noURL: return "No URL in response."
        case .serverError(let msg): return "Cloudinary error: \(msg)"
        }
    }
}

// MARK: - Data extension helper
extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
