import Foundation
import UIKit
import Combine

// MARK: - API Models
struct FoodAnalysisResponse: Codable {
    let success: Bool
    let analysisId: String
    let timestamp: String
    let analysis: FoodAnalysis
}

struct FoodAnalysis: Codable {
    let foods: [AnalyzedFood]
    let overallConfidence: Double
    let imageDescription: String
    let suggestions: [String]
    let totals: NutritionTotals?
    let insights: [String]?
    let timestamp: String?
}

// Rename this FoodItem to avoid conflicts with the main app's FoodItem model
struct AnalyzedFood: Codable, Identifiable {
    let id: String // Use String ID for API compatibility
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let servingSize: String
    let confidence: Double
    let cookingMethod: String
    let healthNotes: String
    let verified: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, carbs, fat, fiber
        case servingSize = "serving_size"
        case confidence, cookingMethod = "cooking_method"
        case healthNotes = "health_notes"
        case verified
    }
}

struct NutritionTotals: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
}

struct NutritionSuggestionsResponse: Codable {
    let success: Bool
    let suggestions: NutritionSuggestions
}

struct NutritionSuggestions: Codable {
    let suggestions: [String]
    let mealScore: Int
    let nextMealAdvice: String
}

// MARK: - API Error Types
enum FoodAnalysisError: Error, LocalizedError {
    case noImage
    case invalidResponse
    case networkError(Error)
    case serverError(String)
    case rateLimited
    case fileTooLarge
    case invalidFileType
    
    var errorDescription: String? {
        switch self {
        case .noImage:
            return "No image provided for analysis"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .fileTooLarge:
            return "Image file is too large. Please use a smaller image."
        case .invalidFileType:
            return "Invalid file type. Please use JPG, PNG, or WebP format."
        }
    }
}

// MARK: - Food Analysis Service
class FoodAnalysisService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var lastAnalysis: FoodAnalysis?
    @Published var errorMessage: String?
    
    private let baseURL = "https://food-tracker.com" // Railway backend URL
    private let session = URLSession.shared
    
    func analyzeFoodImage(_ image: UIImage) async throws -> FoodAnalysis {
        print("🌐 FoodAnalysisService: Starting analysis...")
        guard !isAnalyzing else {
            throw FoodAnalysisError.serverError("Analysis already in progress")
        }
        
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        do {
            // Prepare the request
            let url = URL(string: "\(baseURL)/api/analyze-food")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Create multipart form data
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Convert image to JPEG data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw FoodAnalysisError.noImage
            }
            
            // Create multipart body
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            // Make the request
            print("🌐 Sending request to: \(url)")
            let (data, response) = try await session.data(for: request)
            print("🌐 Received response: \(response)")
            print("🌐 Response data size: \(data.count) bytes")
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FoodAnalysisError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 400:
                let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                if let code = errorResponse?["code"] {
                    switch code {
                    case "FILE_TOO_LARGE":
                        throw FoodAnalysisError.fileTooLarge
                    case "INVALID_FILE_TYPE":
                        throw FoodAnalysisError.invalidFileType
                    default:
                        throw FoodAnalysisError.serverError(errorResponse?["message"] ?? "Bad request")
                    }
                }
                throw FoodAnalysisError.serverError("Bad request")
            case 429:
                throw FoodAnalysisError.rateLimited
            case 500:
                throw FoodAnalysisError.serverError("Server error")
            default:
                throw FoodAnalysisError.serverError("Unexpected response: \(httpResponse.statusCode)")
            }
            
            // Decode response
            print("🌐 Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            let analysisResponse = try JSONDecoder().decode(FoodAnalysisResponse.self, from: data)
            print("🌐 Analysis successful: \(analysisResponse.analysis.foods.count) foods found")
            print("🌐 First food: \(analysisResponse.analysis.foods.first?.name ?? "No food found")")
            
            await MainActor.run {
                lastAnalysis = analysisResponse.analysis
            }
            
            return analysisResponse.analysis
            
        } catch {
            let analysisError: FoodAnalysisError
            if let foodError = error as? FoodAnalysisError {
                analysisError = foodError
            } else {
                analysisError = .networkError(error)
            }
            
            await MainActor.run {
                errorMessage = analysisError.localizedDescription
            }
            
            throw analysisError
        }
    }
    
    func getNutritionSuggestions(foodItems: [AnalyzedFood], userGoals: UserGoals) async throws -> NutritionSuggestions {
        let url = URL(string: "\(baseURL)/api/nutrition-suggestions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "foodItems": foodItems,
            "userGoals": [
                "goal": userGoals.goal,
                "dailyCalories": userGoals.dailyCalories,
                "proteinGoal": userGoals.proteinGoal,
                "carbGoal": userGoals.carbGoal,
                "fatGoal": userGoals.fatGoal
            ]
        ] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw FoodAnalysisError.serverError("Failed to encode request")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FoodAnalysisError.serverError("Failed to get suggestions")
        }
        
        let suggestionsResponse = try JSONDecoder().decode(NutritionSuggestionsResponse.self, from: data)
        return suggestionsResponse.suggestions
    }
}

// MARK: - User Goals Model
struct UserGoals: Codable {
    let goal: String // "weight_loss", "muscle_gain", "maintenance"
    let dailyCalories: Int
    let proteinGoal: Int
    let carbGoal: Int
    let fatGoal: Int
}

