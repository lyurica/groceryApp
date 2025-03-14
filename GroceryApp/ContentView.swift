//
//  ContentView.swift
//  GroceryApp
//
//  Created by Landon Yurica on 3/14/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @StateObject private var cameraModel = CameraModel()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(cameraModel: cameraModel)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Camera controls
                HStack {
                    Spacer()
                    
                    Button(action: {
                        cameraModel.isCapturing.toggle()
                    }) {
                        Image(systemName: cameraModel.isCapturing ? "stop.circle" : "record.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(cameraModel.isCapturing ? .red : .white)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            
            // Status indicator
            VStack {
                Text(cameraModel.isCapturing ? "Capturing Frames" : "Ready")
                    .padding(8)
                    .background(cameraModel.isCapturing ? Color.green.opacity(0.8) : Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {
            cameraModel.checkPermissions()
        }
    }
}

// Camera Preview using UIViewRepresentable
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraModel: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.session)
        cameraModel.preview.frame = view.frame
        cameraModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraModel.preview)
        
        // Session is now started in setupCamera() on a background thread
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// Camera Model
class CameraModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isCapturing = false {
        didSet {
            if isCapturing {
                startFrameCapture()
            } else {
                stopFrameCapture()
            }
        }
    }
    
    var session = AVCaptureSession()
    var preview: AVCaptureVideoPreviewLayer!
    
    private var output = AVCaptureVideoDataOutput()
    private var queue = DispatchQueue(label: "camera.queue")
    private var frameCount = 0
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    func setupCamera() {
        // Move session setup to background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.session.beginConfiguration()
                
                // Set camera device
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                let input = try AVCaptureDeviceInput(device: device!)
                
                // Add input and output to session
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                }
                
                self.session.commitConfiguration()
                
                // Start session in background thread
                self.session.startRunning()
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func startFrameCapture() {
        output.setSampleBufferDelegate(self, queue: queue)
    }
    
    func stopFrameCapture() {
        output.setSampleBufferDelegate(nil, queue: nil)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Only process every 10th frame to reduce load
        frameCount += 1
        if frameCount % 10 == 0 {
            S3UploadService.shared.uploadFrame(frame) { result in
                switch result {
                case .success(let filename):
                    print("Frame uploaded: \(filename)")
                case .failure(let error):
                    print("Failed to upload frame: \(error)")
                }
            }
        }
    }
}

