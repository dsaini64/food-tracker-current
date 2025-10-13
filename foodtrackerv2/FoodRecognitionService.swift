import Foundation
import UIKit
import Vision
import Combine

// MARK: - Food Recognition Service
class FoodRecognitionService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var recognitionResult: FoodRecognitionResult?
    
    func analyzeFoodImage(_ image: UIImage) {
        isAnalyzing = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performFoodRecognition(image)
        }
    }
    
    private func performFoodRecognition(_ image: UIImage) {
        // In a real app, this would use a food recognition API like:
        // - Google Vision API
        // - Clarifai Food API
        // - Microsoft Computer Vision API
        // - Custom ML model
        
        // For demo purposes, we'll simulate recognition with mock data
        let mockResults = generateMockFoodRecognition()
        self.recognitionResult = mockResults
        self.isAnalyzing = false
    }
    
    private func generateMockFoodRecognition() -> FoodRecognitionResult {
        let foodOptions = [
            FoodRecognitionResult(
                name: "Grilled Chicken Breast",
                confidence: 0.92,
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6,
                fiber: 0,
                sugar: 0,
                sodium: 74,
                healthScore: 9
            ),
            FoodRecognitionResult(
                name: "Mixed Green Salad",
                confidence: 0.88,
                calories: 25,
                protein: 2,
                carbs: 5,
                fat: 0.5,
                fiber: 2,
                sugar: 3,
                sodium: 15,
                healthScore: 10
            ),
            FoodRecognitionResult(
                name: "Pasta with Marinara",
                confidence: 0.85,
                calories: 220,
                protein: 8,
                carbs: 44,
                fat: 2,
                fiber: 3,
                sugar: 8,
                sodium: 320,
                healthScore: 6
            ),
            FoodRecognitionResult(
                name: "Apple",
                confidence: 0.95,
                calories: 95,
                protein: 0.5,
                carbs: 25,
                fat: 0.3,
                fiber: 4,
                sugar: 19,
                sodium: 2,
                healthScore: 9
            ),
            FoodRecognitionResult(
                name: "French Fries",
                confidence: 0.90,
                calories: 365,
                protein: 4,
                carbs: 63,
                fat: 11,
                fiber: 6,
                sugar: 0.3,
                sodium: 246,
                healthScore: 3
            )
        ]
        
        return foodOptions.randomElement() ?? foodOptions[0]
    }
}

// MARK: - Food Recognition Result
struct FoodRecognitionResult {
    let name: String
    let confidence: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let healthScore: Int
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}
