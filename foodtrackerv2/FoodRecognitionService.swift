import Foundation
import UIKit
import Combine

// MARK: - Food Recognition Service
class FoodRecognitionService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var recognitionResult: FoodRecognitionResult?
    @Published var errorMessage: String?
    @Published var analysisProgress: String = ""
    @Published var detectedFoodsCount: Int = 0
    
    private let foodAnalysisService = FoodAnalysisService()
    
    func analyzeFoodImage(_ image: UIImage, mealType: FoodItem.MealType = .snack) {
        print("🍎 Starting food analysis...")
        print("🍎 Image size: \(image.size)")
        
        // Set analyzing state immediately on main thread
        DispatchQueue.main.async {
            self.isAnalyzing = true
            self.errorMessage = nil
            self.analysisProgress = "Preparing image..."
        }
        
        // Start analysis immediately without delay
        Task {
            do {
                // Update progress
                await MainActor.run {
                    self.analysisProgress = "Analyzing..."
                }
                
                print("🍎 Sending image to backend...")
                let analysis = try await foodAnalysisService.analyzeFoodImage(image)
                print("🍎 Received analysis from backend: \(analysis)")
                
                await MainActor.run {
                    self.analysisProgress = "Processing results..."
                    self.processAnalysis(analysis, image: image, mealType: mealType)
                }
            } catch {
                print("🍎 Error during analysis: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAnalyzing = false
                    self.analysisProgress = ""
                }
            }
        }
    }
    
    private func processAnalysis(_ analysis: FoodAnalysis, image: UIImage, mealType: FoodItem.MealType) {
        print("🍎 Processing analysis with \(analysis.foods.count) foods")
        
        // Process all foods, not just the first one
        var validFoods: [FoodRecognitionResult] = []
        
        for (index, food) in analysis.foods.enumerated() {
            print("🍎 Processing food \(index + 1): \(food.name), calories: \(food.calories)")
            
            // Only process real foods (not unidentified)
            if !food.name.lowercased().contains("unidentified") && 
               !food.name.lowercased().contains("unknown") &&
               food.calories > 0 {
                
                let healthScore = calculateHealthScore(from: food)
                
                let result = FoodRecognitionResult(
                    name: food.name,
                    confidence: food.confidence,
                    calories: food.calories,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat,
                    fiber: food.fiber,
                    sugar: 0, // Not provided in new format
                    sodium: 0, // Not provided in new format
                    healthScore: healthScore
                )
                
                validFoods.append(result)
                print("🍎 Added valid food: \(result.name), \(result.calories) calories")
            } else {
                print("🍎 Skipping unidentified food: \(food.name)")
            }
        }
        
        // Set the first valid food as the main result for UI display
        if let firstValidFood = validFoods.first {
            self.recognitionResult = firstValidFood
            print("🍎 Set main recognitionResult: \(firstValidFood.name)")
        }
        
        // Add all valid foods to daily log
        for foodResult in validFoods {
            addToDailyLog(foodResult, image: image, mealType: mealType)
        }
        
        // Update detected foods count for UI
        self.detectedFoodsCount = validFoods.count
        
        print("🍎 Added \(validFoods.count) foods to daily log")
        self.isAnalyzing = false
    }
    
    private func addToDailyLog(_ result: FoodRecognitionResult, image: UIImage, mealType: FoodItem.MealType = .snack) {
        // Convert image to data for storage with lower quality to reduce memory usage
        let imageData = image.jpegData(compressionQuality: 0.3)
        
        // Create a FoodItem from the result
        let foodItem = FoodItem(
            name: result.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fat: result.fat,
            fiber: result.fiber,
            sugar: result.sugar,
            sodium: result.sodium,
            timestamp: Date(),
            imageData: imageData,
            mealType: mealType,
            healthScore: result.healthScore
        )
        
        // Add to daily log (this would need to be injected or accessed via a shared instance)
        // For now, we'll use a notification to update the daily log
        NotificationCenter.default.post(
            name: NSNotification.Name("FoodAnalyzed"),
            object: foodItem
        )
    }
    
    private func calculateHealthScore(from analyzedFood: AnalyzedFood) -> Int {
        // Don't penalize unidentified foods - give them a neutral score
        if analyzedFood.name.lowercased().contains("unidentified") || 
           analyzedFood.name.lowercased().contains("unknown") ||
           analyzedFood.calories == 0 {
            return 5 // Neutral score for unidentified foods
        }
        
        var score = 5 // Base score
        
        // Protein bonus
        if analyzedFood.protein > 20 { score += 2 }
        else if analyzedFood.protein > 10 { score += 1 }
        
        // Fiber bonus
        if analyzedFood.fiber > 5 { score += 2 }
        else if analyzedFood.fiber > 2 { score += 1 }
        
        // Fat penalty for high fat
        if analyzedFood.fat > 20 { score -= 2 }
        else if analyzedFood.fat > 10 { score -= 1 }
        
        // Calorie penalty for very high calories
        if analyzedFood.calories > 500 { score -= 2 }
        else if analyzedFood.calories > 300 { score -= 1 }
        
        return max(1, min(10, score))
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

