 // AmplifyConfig.swift

import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin

class AmplifyManager {
    static let shared = AmplifyManager()
    
    private init() {}
    
    func configureAmplify() {
        do {
            // Auth plugin
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            
            // Storage plugin
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            // Initialize Amplify
            try Amplify.configure()
            
            print("Amplify configured successfully")
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
}

