import SwiftUI
import SwiftUI
internal import AVFoundation
import UIKit

struct LiveCameraView: UIViewRepresentable {
    @Binding var isCapturing: Bool
    @Binding var isFlashOn: Bool
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let cameraView = CameraPreviewView()
        context.coordinator.setupCamera(in: cameraView)
        return cameraView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Handle capture trigger
        if isCapturing {
            context.coordinator.capturePhoto()
            DispatchQueue.main.async {
                isCapturing = false
            }
        }
        
        // Handle flash toggle
        context.coordinator.setFlashMode(isFlashOn ? .on : .off)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class CameraPreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: LiveCameraView
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?
        var captureDevice: AVCaptureDevice?
        
        init(_ parent: LiveCameraView) {
            self.parent = parent
        }
        
        func setupCamera(in view: CameraPreviewView) {
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            
            // Set up camera
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("Unable to access back camera")
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: backCamera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
                
                let output = AVCapturePhotoOutput()
                if captureSession.canAddOutput(output) {
                    captureSession.addOutput(output)
                }
                
                // Configure preview layer
                view.videoPreviewLayer.session = captureSession
                view.videoPreviewLayer.videoGravity = .resizeAspectFill
                
                // Store references
                self.captureSession = captureSession
                self.photoOutput = output
                self.captureDevice = backCamera
                
                // Set initial flash mode
                self.setFlashMode(parent.isFlashOn ? .on : .off)
                
                // Start session on background queue
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
                
            } catch {
                print("Error setting up camera: \(error)")
            }
        }
        
        func capturePhoto() {
            guard let photoOutput = photoOutput else { 
                print("Photo output not available")
                return 
            }
            
            let settings: AVCapturePhotoSettings
            
            // Configure settings with format
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("Unable to create image from photo data")
                return
            }
            
            DispatchQueue.main.async {
                self.parent.onImageCaptured(image)
            }
        }
        
        func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
            guard let device = captureDevice else { return }
            
            do {
                try device.lockForConfiguration()
                if device.hasFlash {
                    device.flashMode = mode
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting flash mode: \(error)")
            }
        }
    }
}


