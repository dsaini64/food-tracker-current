import SwiftUI

struct SnapchatCameraView: View {
    let analysis: NutritionAnalysis
    @ObservedObject var foodRecognition: FoodRecognitionService
    
    @State private var isCapturing = false
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var isFlashOn = false
    
    var body: some View {
        ZStack {
            // Live Camera Feed
            LiveCameraView(
                isCapturing: $isCapturing,
                isFlashOn: $isFlashOn,
                onImageCaptured: { image in
                    print("📱 Image captured, size: \(image.size)")
                    capturedImage = image
                    // Start analysis immediately
                    foodRecognition.analyzeFoodImage(image)
                }
            )
            .ignoresSafeArea()
            
            // Top Status Bar
            VStack {
                HStack {
                    // Calorie Progress
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(analysis.dailyLog.totalCalories))/\(Int(analysis.goals.dailyCalories)) cal")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ProgressView(value: analysis.dailyLog.totalCalories, total: analysis.goals.dailyCalories)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: 120)
                    }
                    
                    Spacer()
                    
                    // Quick Actions
                    HStack(spacing: 20) {
                        Button(action: {
                            isFlashOn.toggle()
                        }) {
                            Image(systemName: isFlashOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title2)
                                .foregroundColor(isFlashOn ? .yellow : .white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // Bottom UI
            VStack {
                Spacer()
                
                // Recent Food Items
                if !analysis.dailyLog.foodItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(analysis.dailyLog.foodItems.suffix(5)) { item in
                                VStack(spacing: 4) {
                                    Text(item.name)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text("\(Int(item.calories)) cal")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 60)
                }
                
                // Capture Button
                VStack(spacing: 8) {
                    Button(action: {
                        isCapturing = true
                    }) {
                        ZStack {
                            // Outer ring
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                            
                            // Inner circle
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                        }
                    }
                    .disabled(foodRecognition.isAnalyzing)
                    
                    if foodRecognition.isAnalyzing {
                        VStack(spacing: 4) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            Text(foodRecognition.analysisProgress.isEmpty ? "Analyzing..." : foodRecognition.analysisProgress)
                                .foregroundColor(.white)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Analysis Results Overlay
            if let result = foodRecognition.recognitionResult {
                let _ = print("📱 Displaying result: \(result.name), \(result.calories) calories")
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text("Food Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if foodRecognition.detectedFoodsCount > 1 {
                                Text("\(foodRecognition.detectedFoodsCount) foods detected")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name: \(result.name)")
                                .foregroundColor(.white)
                            
                            if result.name.lowercased().contains("unidentified") || result.calories == 0 {
                                Text("Unable to identify food")
                                    .foregroundColor(.orange)
                                Text("Try taking a clearer photo with better lighting")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                            } else {
                                Text("Calories: \(Int(result.calories))")
                                    .foregroundColor(.white)
                                
                                Text("Protein: \(Int(result.protein))g")
                                    .foregroundColor(.white)
                                
                                Text("Health Score: \(result.healthScore)/10")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        
                        Button("Done") {
                            foodRecognition.recognitionResult = nil
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
        .onTapGesture {
            // Tap anywhere to capture
            isCapturing = true
        }
    }
}
