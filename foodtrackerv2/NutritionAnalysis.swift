import Foundation
import SwiftUI
import Combine

// MARK: - Nutrition Analysis
class NutritionAnalysis: ObservableObject {
    @Published var dailyLog: DailyFoodLog
    @Published var goals: NutritionGoals
    
    init(dailyLog: DailyFoodLog, goals: NutritionGoals = .defaultGoals) {
        self.dailyLog = dailyLog
        self.goals = goals
    }
    
    // MARK: - Progress Calculations
    var caloriesProgress: Double {
        min(dailyLog.totalCalories / goals.dailyCalories, 1.0)
    }
    
    var proteinProgress: Double {
        min(dailyLog.totalProtein / goals.dailyProtein, 1.0)
    }
    
    var carbsProgress: Double {
        min(dailyLog.totalCarbs / goals.dailyCarbs, 1.0)
    }
    
    var fatProgress: Double {
        min(dailyLog.totalFat / goals.dailyFat, 1.0)
    }
    
    // MARK: - Health Insights
    var overallHealthScore: Double {
        dailyLog.averageHealthScore
    }
    
    var healthScoreColor: Color {
        switch overallHealthScore {
        case 8...10:
            return .green
        case 6..<8:
            return .yellow
        case 4..<6:
            return .orange
        default:
            return .red
        }
    }
    
    var healthScoreDescription: String {
        switch overallHealthScore {
        case 8...10:
            return "Excellent! You're making great food choices."
        case 6..<8:
            return "Good job! A few tweaks could make it even better."
        case 4..<6:
            return "Room for improvement. Focus on healthier options."
        default:
            return "Let's work on making better food choices."
        }
    }
    
    // MARK: - Improvement Suggestions
    func generateImprovementSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // Calorie-based suggestions
        if dailyLog.totalCalories < goals.dailyCalories * 0.8 {
            suggestions.append("Consider adding healthy snacks to meet your calorie goals")
        } else if dailyLog.totalCalories > goals.dailyCalories * 1.2 {
            suggestions.append("Try reducing portion sizes or choosing lower-calorie options")
        }
        
        // Protein suggestions
        if dailyLog.totalProtein < goals.dailyProtein * 0.7 {
            suggestions.append("Add more lean proteins like chicken, fish, or legumes")
        }
        
        // Health score suggestions
        if overallHealthScore < 6 {
            suggestions.append("Include more fruits and vegetables in your meals")
            suggestions.append("Choose whole grains over refined carbohydrates")
            suggestions.append("Limit processed foods and added sugars")
        }
        
        // Meal balance suggestions
        let mealTypes = FoodItem.MealType.allCases
        let emptyMeals = mealTypes.filter { dailyLog.getFoodItems(for: $0).isEmpty }
        
        if emptyMeals.contains(.breakfast) {
            suggestions.append("Don't skip breakfast - it kickstarts your metabolism")
        }
        
        if emptyMeals.contains(.lunch) {
            suggestions.append("A balanced lunch helps maintain energy throughout the day")
        }
        
        if emptyMeals.contains(.dinner) {
            suggestions.append("A nutritious dinner supports overnight recovery")
        }
        
        // Hydration reminder
        suggestions.append("Remember to stay hydrated throughout the day")
        
        return suggestions.isEmpty ? ["Keep up the great work!"] : suggestions
    }
    
    // MARK: - Daily Summary
    func generateDailySummary() -> DailySummary {
        let suggestions = generateImprovementSuggestions()
        let mealBreakdown = generateMealBreakdown()
        
        return DailySummary(
            totalCalories: dailyLog.totalCalories,
            totalProtein: dailyLog.totalProtein,
            totalCarbs: dailyLog.totalCarbs,
            totalFat: dailyLog.totalFat,
            healthScore: overallHealthScore,
            mealBreakdown: mealBreakdown,
            suggestions: suggestions,
            goalsMet: calculateGoalsMet()
        )
    }
    
    private func generateMealBreakdown() -> [MealBreakdown] {
        return FoodItem.MealType.allCases.map { mealType in
            let items = dailyLog.getFoodItems(for: mealType)
            let calories = items.reduce(0) { $0 + $1.calories }
            let healthScore = items.isEmpty ? 0 : Double(items.reduce(0) { $0 + $1.healthScore }) / Double(items.count)
            
            return MealBreakdown(
                mealType: mealType,
                calories: calories,
                itemCount: items.count,
                averageHealthScore: healthScore
            )
        }
    }
    
    private func calculateGoalsMet() -> [String: Bool] {
        return [
            "Calories": dailyLog.totalCalories >= goals.dailyCalories * 0.8 && dailyLog.totalCalories <= goals.dailyCalories * 1.2,
            "Protein": dailyLog.totalProtein >= goals.dailyProtein * 0.7,
            "Health Score": overallHealthScore >= 6
        ]
    }
}

// MARK: - Daily Summary Model
struct DailySummary {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let healthScore: Double
    let mealBreakdown: [MealBreakdown]
    let suggestions: [String]
    let goalsMet: [String: Bool]
}

struct MealBreakdown {
    let mealType: FoodItem.MealType
    let calories: Double
    let itemCount: Int
    let averageHealthScore: Double
}
