//
//  S3UploadService.swift
//  GroceryApp
//
//  Created by Landon Yurica on 3/14/25.
//


import Foundation
import UIKit
import Amplify

class S3UploadService {
    static let shared = S3UploadService()
    
    private init() {}
    
    func uploadFrame(_ imageBuffer: CVImageBuffer, completion: @escaping (Result<String, Error>) -> Void) {
        // Convert CVImageBuffer to UIImage
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            completion(.failure(NSError(domain: "ImageProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage"])))
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "ImageProcessing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        // Generate unique filename
        let filename = "frame-\(UUID().uuidString).jpg"
        
        // Upload to S3
        Amplify.Storage.uploadData(
            key: filename,
            data: imageData
        )
    }
}
