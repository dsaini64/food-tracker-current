import SwiftUI
import PhotosUI

struct SimpleCameraView: View {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    let onImageCaptured: (UIImage) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Photo Source")
                    .font(.title2)
                    .padding()
                
                Button("Take Photo") {
                    showingImagePicker = true
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .padding()
                
                Button("Choose from Library") {
                    showingPhotoPicker = true
                }
                .buttonStyle(.bordered)
                .font(.headline)
                .padding()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .navigationTitle("Add Food Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(capturedImage: $capturedImage, onImageCaptured: onImageCaptured)
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        capturedImage = image
                        onImageCaptured(image)
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("📷 Creating simple image picker")
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
            super.init()
            print("📷 Simple picker coordinator created")
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📷 Simple picker finished")
            
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
                parent.onImageCaptured(image)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📷 Simple picker cancelled")
            parent.dismiss()
        }
    }
}