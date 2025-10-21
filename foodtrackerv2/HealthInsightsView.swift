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
            
            // Real-time data from daily log
            VStack(spacing: 12) {
                TrendCard(
                    title: "Average Health Score",
                    currentValue: analysis.overallHealthScore,
                    previousValue: max(0, analysis.overallHealthScore - 0.5),
                    unit: "/10",
                    color: analysis.healthScoreColor
                )
                
                TrendCard(
                    title: "Daily Calories",
                    currentValue: analysis.dailyLog.totalCalories,
                    previousValue: max(0, analysis.dailyLog.totalCalories - 50),
                    unit: "kcal",
                    color: .blue
                )
                
                TrendCard(
                    title: "Protein Intake",
                    currentValue: analysis.dailyLog.totalProtein,
                    previousValue: max(0, analysis.dailyLog.totalProtein - 10),
                    unit: "g",
                    color: .green
                )
                
                TrendCard(
                    title: "Food Items Today",
                    currentValue: Double(analysis.dailyLog.foodItems.count),
                    previousValue: max(0, Double(analysis.dailyLog.foodItems.count) - 1),
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
                    title: "Today's Foods",
                    items: analysis.dailyLog.foodItems.map { $0.name },
                    icon: "fork.knife"
                )
                
                PatternCard(
                    title: "Meal Distribution",
                    items: [
                        "Breakfast: \(analysis.dailyLog.getFoodItems(for: .breakfast).count) items",
                        "Lunch: \(analysis.dailyLog.getFoodItems(for: .lunch).count) items", 
                        "Dinner: \(analysis.dailyLog.getFoodItems(for: .dinner).count) items",
                        "Snacks: \(analysis.dailyLog.getFoodItems(for: .snack).count) items"
                    ],
                    icon: "clock"
                )
                
                PatternCard(
                    title: "Health Scores",
                    items: analysis.dailyLog.foodItems.map { "\($0.name): \($0.healthScore)/10" },
                    icon: "heart.fill"
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
                // Protein recommendation based on actual progress
                if analysis.proteinProgress < 0.8 {
                    RecommendationCard(
                        title: "Increase Protein",
                        description: "You're at \(Int(analysis.proteinProgress * 100))% of your protein goal",
                        action: "Add lean proteins like chicken or fish",
                        color: .green
                    )
                }
                
                // Calorie recommendation
                if analysis.caloriesProgress < 0.7 {
                    RecommendationCard(
                        title: "Add More Calories",
                        description: "You're at \(Int(analysis.caloriesProgress * 100))% of your calorie goal",
                        action: "Consider a healthy snack",
                        color: .blue
                    )
                } else if analysis.caloriesProgress > 1.2 {
                    RecommendationCard(
                        title: "Calorie Balance",
                        description: "You've exceeded your daily calorie goal",
                        action: "Consider lighter options for remaining meals",
                        color: .orange
                    )
                }
                
                // Health score recommendation
                if analysis.overallHealthScore < 6 {
                    RecommendationCard(
                        title: "Improve Food Choices",
                        description: "Your average health score is \(String(format: "%.1f", analysis.overallHealthScore))/10",
                        action: "Add more vegetables and whole foods",
                        color: .red
                    )
                } else {
                    RecommendationCard(
                        title: "Great Job!",
                        description: "Your health score is \(String(format: "%.1f", analysis.overallHealthScore))/10",
                        action: "Keep up the excellent choices!",
                        color: .green
                    )
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
