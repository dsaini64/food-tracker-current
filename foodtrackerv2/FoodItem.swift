import Foundation
import SwiftUI
import Combine

// MARK: - Food Item Model
struct FoodItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let timestamp: Date
    let imageData: Data?
    let mealType: MealType
    let healthScore: Int // 1-10 scale
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        
        var emoji: String {
            switch self {
            case .breakfast: return "🌅"
            case .lunch: return "☀️"
            case .dinner: return "🌙"
            case .snack: return "🍎"
            }
        }
    }
}

// MARK: - Daily Food Log
class DailyFoodLog: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var currentDate: Date = Date()
    
    var totalCalories: Double {
        foodItems.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        foodItems.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        foodItems.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFat: Double {
        foodItems.reduce(0) { $0 + $1.fat }
    }
    
    var averageHealthScore: Double {
        guard !foodItems.isEmpty else { return 0 }
        return Double(foodItems.reduce(0) { $0 + $1.healthScore }) / Double(foodItems.count)
    }
    
    func addFoodItem(_ item: FoodItem) {
        foodItems.append(item)
    }
    
    func removeFoodItem(_ item: FoodItem) {
        foodItems.removeAll { $0.id == item.id }
    }
    
    func getFoodItems(for mealType: FoodItem.MealType) -> [FoodItem] {
        return foodItems.filter { $0.mealType == mealType }
    }
}

// MARK: - Nutrition Goals
struct NutritionGoals {
    let dailyCalories: Double
    let dailyProtein: Double
    let dailyCarbs: Double
    let dailyFat: Double
    
    static let defaultGoals = NutritionGoals(
        dailyCalories: 2000,
        dailyProtein: 150,
        dailyCarbs: 250,
        dailyFat: 65
    )
}
