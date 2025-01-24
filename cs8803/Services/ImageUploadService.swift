//
//  ImageUploadService.swift
//  cs8803
//
//  Created by Ethan Yan on 24/1/25.
//

import Cloudinary

class ImageUploadService {
    private let cloudName = "dcvqrt5p0"
    private let uploadPreset = "ios_unsigned_preset"
    private let configuration: CLDConfiguration
    private let cloudinary: CLDCloudinary

    init() {
        configuration = CLDConfiguration(cloudName: cloudName, secure: true)
        cloudinary = CLDCloudinary(configuration: configuration)
    }

    func uploadImage(data: Data, publicId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let params = CLDUploadRequestParams()
        params.setUploadPreset(uploadPreset)
        params.setPublicId(publicId)

        let uploadRequest = cloudinary.createUploader().upload(data: data, uploadPreset: uploadPreset, params: params)

        uploadRequest.response { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let secureUrl = result?.secureUrl {
                completion(.success(secureUrl))
            } else {
                completion(.failure(NSError(domain: "CloudinaryUploadService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No URL returned from Cloudinary"])))
            }
        }
        .progress { progress in
            print("Cloudinary upload progress: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
        }
    }
}
