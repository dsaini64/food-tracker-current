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
            
            // Mock trend data - in a real app, this would come from historical data
            VStack(spacing: 12) {
                TrendCard(
                    title: "Average Health Score",
                    currentValue: analysis.overallHealthScore,
                    previousValue: analysis.overallHealthScore - 0.5,
                    unit: "/10",
                    color: analysis.healthScoreColor
                )
                
                TrendCard(
                    title: "Daily Calories",
                    currentValue: analysis.dailyLog.totalCalories,
                    previousValue: analysis.dailyLog.totalCalories - 50,
                    unit: "kcal",
                    color: .blue
                )
                
                TrendCard(
                    title: "Protein Intake",
                    currentValue: analysis.dailyLog.totalProtein,
                    previousValue: analysis.dailyLog.totalProtein - 10,
                    unit: "g",
                    color: .green
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
                    title: "Most Common Foods",
                    items: ["Chicken Breast", "Mixed Salad", "Apple", "Greek Yogurt"],
                    icon: "fork.knife"
                )
                
                PatternCard(
                    title: "Best Meal Times",
                    items: ["Breakfast: 8:00 AM", "Lunch: 12:30 PM", "Dinner: 7:00 PM"],
                    icon: "clock"
                )
                
                PatternCard(
                    title: "Healthiest Choices",
                    items: ["Grilled Chicken", "Fresh Vegetables", "Whole Grains"],
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
                RecommendationCard(
                    title: "Increase Protein",
                    description: "Add more lean proteins to reach your daily goal",
                    action: "Try grilled fish or legumes",
                    color: .green
                )
                
                RecommendationCard(
                    title: "Hydration Reminder",
                    description: "Aim for 8 glasses of water daily",
                    action: "Set hourly reminders",
                    color: .blue
                )
                
                RecommendationCard(
                    title: "Meal Timing",
                    description: "Consider eating dinner 2-3 hours before bed",
                    action: "Plan evening meals",
                    color: .orange
                )
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
