//
//  GroceryAppApp.swift
//  GroceryApp
//
//  Created by Landon Yurica on 3/14/25.
//
import SwiftUI
import Amplify
import AVFoundation

@main
struct GroceryDetectorApp: App {
    init() {
        // Configure Amplify
        AmplifyManager.shared.configureAmplify()
        
        // Request camera permissions
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
