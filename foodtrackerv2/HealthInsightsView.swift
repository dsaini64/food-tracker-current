import SwiftUI
import Combine

struct HealthInsightsView: View {
    @ObservedObject var analysis: NutritionAnalysis
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // MARK: - Computed Properties for Timeframe Filtering
    private var filteredFoodItems: [FoodItem] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeframe {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return analysis.dailyLog.foodItems.filter { $0.timestamp >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return analysis.dailyLog.foodItems.filter { $0.timestamp >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return analysis.dailyLog.foodItems.filter { $0.timestamp >= yearAgo }
        }
    }
    
    private var filteredCalories: Double {
        filteredFoodItems.reduce(0) { $0 + $1.calories }
    }
    
    private var filteredProtein: Double {
        filteredFoodItems.reduce(0) { $0 + $1.protein }
    }
    
    private var filteredHealthScore: Double {
        guard !filteredFoodItems.isEmpty else { return 0 }
        return Double(filteredFoodItems.reduce(0) { $0 + $1.healthScore }) / Double(filteredFoodItems.count)
    }
    
    private var timeframeDescription: String {
        switch selectedTimeframe {
        case .week:
            return "Last 7 days"
        case .month:
            return "Last 30 days"
        case .year:
            return "Last 365 days"
        }
    }
    
    private func healthScoreColor(for score: Double) -> Color {
        switch score {
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Selector
                    timeframeSelector
                    
                    // Health Trends
                    healthTrendsSection
                    
                    // Nutrition Patterns
                    nutritionPatternsSection
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding()
            }
            .navigationTitle("Health Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Health Trends Section
    private var healthTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Trends")
                .font(.headline)
            
            // Filtered data based on selected timeframe
            VStack(spacing: 12) {
                Text(timeframeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                TrendCard(
                    title: "Average Health Score",
                    currentValue: filteredHealthScore,
                    previousValue: max(0, filteredHealthScore - 0.5),
                    unit: "/10",
                    color: healthScoreColor(for: filteredHealthScore)
                )
                
                TrendCard(
                    title: "Total Calories",
                    currentValue: filteredCalories,
                    previousValue: max(0, filteredCalories - 100),
                    unit: "kcal",
                    color: .blue
                )
                
                TrendCard(
                    title: "Total Protein",
                    currentValue: filteredProtein,
                    previousValue: max(0, filteredProtein - 20),
                    unit: "g",
                    color: .green
                )
                
                TrendCard(
                    title: "Food Items",
                    currentValue: Double(filteredFoodItems.count),
                    previousValue: max(0, Double(filteredFoodItems.count) - 1),
                    unit: "items",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Nutrition Patterns Section
    private var nutritionPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Patterns")
                .font(.headline)
            
            VStack(spacing: 12) {
                PatternCard(
                    title: "Meal Distribution",
                    items: [
                        "Breakfast: \(filteredFoodItems.filter { $0.mealType == .breakfast }.count) items",
                        "Lunch: \(filteredFoodItems.filter { $0.mealType == .lunch }.count) items", 
                        "Dinner: \(filteredFoodItems.filter { $0.mealType == .dinner }.count) items",
                        "Snacks: \(filteredFoodItems.filter { $0.mealType == .snack }.count) items"
                    ],
                    icon: "clock"
                )
                
                PatternCard(
                    title: "Nutrition Trends",
                    items: [
                        "Average Health Score: \(String(format: "%.1f", filteredHealthScore))/10",
                        "Total Foods: \(filteredFoodItems.count)",
                        "Average Daily Calories: \(String(format: "%.0f", filteredCalories / max(1, Double(selectedTimeframe == .week ? 7 : selectedTimeframe == .month ? 30 : 365))))"
                    ],
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Recommendations")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Check if no food has been logged
                if filteredFoodItems.isEmpty {
                    RecommendationCard(
                        title: "Start Tracking Your Food",
                        description: "Take photos of your meals to get personalized insights and recommendations",
                        action: "Use the camera to snap your first food photo",
                        color: .blue
                    )
                } else {
                    // Health score recommendation based on filtered data
                    if filteredHealthScore < 6 {
                        RecommendationCard(
                            title: "Improve Food Choices",
                            description: "Your \(timeframeDescription.lowercased()) health score is \(String(format: "%.1f", filteredHealthScore))/10",
                            action: "Add more vegetables and whole foods",
                            color: .red
                        )
                    } else if filteredHealthScore >= 8 {
                        RecommendationCard(
                            title: "Excellent Health Choices!",
                            description: "Your \(timeframeDescription.lowercased()) health score is \(String(format: "%.1f", filteredHealthScore))/10",
                            action: "Keep up the excellent choices!",
                            color: .green
                        )
                    } else {
                        RecommendationCard(
                            title: "Good Progress",
                            description: "Your \(timeframeDescription.lowercased()) health score is \(String(format: "%.1f", filteredHealthScore))/10",
                            action: "Continue making healthy choices",
                            color: .yellow
                        )
                    }
                    
                    // Activity level recommendation
                    if filteredFoodItems.count < 3 {
                        RecommendationCard(
                            title: "Track More Foods",
                            description: "You've logged \(filteredFoodItems.count) foods in the \(timeframeDescription.lowercased())",
                            action: "Take more photos to get better insights",
                            color: .blue
                        )
                    } else if filteredFoodItems.count > 20 {
                        RecommendationCard(
                            title: "Great Tracking!",
                            description: "You've logged \(filteredFoodItems.count) foods in the \(timeframeDescription.lowercased())",
                            action: "Your detailed tracking is helping your health",
                            color: .green
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Supporting Views
struct TrendCard: View {
    let title: String
    let currentValue: Double
    let previousValue: Double
    let unit: String
    let color: Color
    
    private var trend: Double {
        currentValue - previousValue
    }
    
    private var trendIcon: String {
        trend > 0 ? "arrow.up.right" : "arrow.down.right"
    }
    
    private var trendColor: Color {
        trend > 0 ? .green : .red
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(String(format: "%.1f", currentValue))\(unit)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    HStack(spacing: 2) {
                        Image(systemName: trendIcon)
                            .font(.caption)
                        Text("\(String(format: "%.1f", abs(trend)))\(unit)")
                            .font(.caption)
                    }
                    .foregroundColor(trendColor)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PatternCard: View {
    let title: String
    let items: [String]
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let action: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(action)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
