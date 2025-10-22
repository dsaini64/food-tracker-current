//
//  UserProfile.swift
//  foodtrackerv2
//
//  Created by Divakar Saini on 10/13/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - User Profile Model
class UserProfile: ObservableObject {
    
    @Published var age: Int {
        didSet {
            UserDefaults.standard.set(age, forKey: "userAge")
        }
    }
    
    @Published var gender: Gender {
        didSet {
            UserDefaults.standard.set(gender.rawValue, forKey: "userGender")
        }
    }
    
    @Published var height: Double {
        didSet {
            UserDefaults.standard.set(height, forKey: "userHeight")
        }
    }
    
    @Published var weight: Double {
        didSet {
            UserDefaults.standard.set(weight, forKey: "userWeight")
        }
    }
    
    @Published var activityLevel: ActivityLevel {
        didSet {
            UserDefaults.standard.set(activityLevel.rawValue, forKey: "userActivityLevel")
        }
    }
    
    @Published var customCalorieGoal: Double {
        didSet {
            UserDefaults.standard.set(customCalorieGoal, forKey: "customCalorieGoal")
        }
    }
    
    @Published var hasCustomCalorieGoal: Bool {
        didSet {
            UserDefaults.standard.set(hasCustomCalorieGoal, forKey: "hasCustomCalorieGoal")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    @Published var breakfastTime: (Int, Int) {
        didSet {
            UserDefaults.standard.set(breakfastTime.0, forKey: "breakfastHour")
            UserDefaults.standard.set(breakfastTime.1, forKey: "breakfastMinute")
        }
    }
    
    @Published var lunchTime: (Int, Int) {
        didSet {
            UserDefaults.standard.set(lunchTime.0, forKey: "lunchHour")
            UserDefaults.standard.set(lunchTime.1, forKey: "lunchMinute")
        }
    }
    
    @Published var dinnerTime: (Int, Int) {
        didSet {
            UserDefaults.standard.set(dinnerTime.0, forKey: "dinnerHour")
            UserDefaults.standard.set(dinnerTime.1, forKey: "dinnerMinute")
        }
    }
    
    init() {
        self.age = UserDefaults.standard.object(forKey: "userAge") as? Int ?? 25
        self.gender = Gender(rawValue: UserDefaults.standard.string(forKey: "userGender") ?? "Other") ?? .other
        self.height = UserDefaults.standard.object(forKey: "userHeight") as? Double ?? 170
        self.weight = UserDefaults.standard.object(forKey: "userWeight") as? Double ?? 70
        self.activityLevel = ActivityLevel(rawValue: UserDefaults.standard.string(forKey: "userActivityLevel") ?? "Moderate") ?? .moderate
        self.customCalorieGoal = UserDefaults.standard.object(forKey: "customCalorieGoal") as? Double ?? 0
        self.hasCustomCalorieGoal = UserDefaults.standard.object(forKey: "hasCustomCalorieGoal") as? Bool ?? false
        
        // Notification settings
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.breakfastTime = (
            UserDefaults.standard.object(forKey: "breakfastHour") as? Int ?? 8,
            UserDefaults.standard.object(forKey: "breakfastMinute") as? Int ?? 0
        )
        self.lunchTime = (
            UserDefaults.standard.object(forKey: "lunchHour") as? Int ?? 12,
            UserDefaults.standard.object(forKey: "lunchMinute") as? Int ?? 30
        )
        self.dinnerTime = (
            UserDefaults.standard.object(forKey: "dinnerHour") as? Int ?? 18,
            UserDefaults.standard.object(forKey: "dinnerMinute") as? Int ?? 30
        )
    }
    
    enum Gender: String, CaseIterable, Codable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
        
        var displayName: String { rawValue }
    }
    
    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "Sedentary"
        case light = "Light"
        case moderate = "Moderate"
        case active = "Active"
        case veryActive = "Very Active"
        
        var displayName: String { rawValue }
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .active: return 1.725
            case .veryActive: return 1.9
            }
        }
    }
    
    // Calculate BMR using Mifflin-St Jeor Equation
    var basalMetabolicRate: Double {
        let bmr: Double
        switch gender {
        case .male:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        case .female:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        case .other:
            // Use average of male and female formulas
            let maleBMR = 10 * weight + 6.25 * height - 5 * Double(age) + 5
            let femaleBMR = 10 * weight + 6.25 * height - 5 * Double(age) - 161
            bmr = (maleBMR + femaleBMR) / 2
        }
        return bmr
    }
    
    // Calculate daily calorie needs
    var recommendedDailyCalories: Double {
        return basalMetabolicRate * activityLevel.multiplier
    }
    
    // Get the calorie goal (custom or calculated)
    var dailyCalorieGoal: Double {
        return hasCustomCalorieGoal ? customCalorieGoal : recommendedDailyCalories
    }
    
    // Generate nutrition goals based on user profile
    var nutritionGoals: NutritionGoals {
        let calories = dailyCalorieGoal
        let protein = calories * 0.3 / 4 // 30% of calories from protein (4 cal/g)
        let carbs = calories * 0.4 / 4   // 40% of calories from carbs (4 cal/g)
        let fat = calories * 0.3 / 9     // 30% of calories from fat (9 cal/g)
        
        return NutritionGoals(
            dailyCalories: calories,
            dailyProtein: protein,
            dailyCarbs: carbs,
            dailyFat: fat
        )
    }
}
