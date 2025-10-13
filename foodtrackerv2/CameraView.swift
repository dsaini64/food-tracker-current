import SwiftUI
internal import AVFoundation
import UIKit
import Combine

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.cameraDevice = .rear
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.capturedImage = editedImage
                parent.onImageCaptured(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.capturedImage = originalImage
                parent.onImageCaptured(originalImage)
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Camera Permission Helper
class CameraPermissionManager: ObservableObject {
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.checkPermission()
            }
        }
    }
}
