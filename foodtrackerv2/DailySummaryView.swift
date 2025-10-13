import SwiftUI
import Combine

struct DailySummaryView: View {
    @ObservedObject var analysis: NutritionAnalysis
    @State private var showingSuggestions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Health Score
                    healthScoreSection
                    
                    // Nutrition Overview
                    nutritionOverviewSection
                    
                    // Meal Breakdown
                    mealBreakdownSection
                    
                    // Goals Status
                    goalsStatusSection
                    
                    // Improvement Suggestions
                    suggestionsSection
                }
                .padding()
            }
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("How did you do today?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(DateFormatter.dayFormatter.string(from: Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Health Score Section
    private var healthScoreSection: some View {
        VStack(spacing: 12) {
            Text("Overall Health Score")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(analysis.overallHealthScore / 10))
                    .stroke(analysis.healthScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(analysis.overallHealthScore))/10")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Health Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(analysis.healthScoreDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(analysis.healthScoreColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Nutrition Overview Section
    private var nutritionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Overview")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NutritionCard(
                    title: "Calories",
                    current: analysis.dailyLog.totalCalories,
                    goal: analysis.goals.dailyCalories,
                    unit: "kcal",
                    color: .blue
                )
                
                NutritionCard(
                    title: "Protein",
                    current: analysis.dailyLog.totalProtein,
                    goal: analysis.goals.dailyProtein,
                    unit: "g",
                    color: .green
                )
                
                NutritionCard(
                    title: "Carbs",
                    current: analysis.dailyLog.totalCarbs,
                    goal: analysis.goals.dailyCarbs,
                    unit: "g",
                    color: .orange
                )
                
                NutritionCard(
                    title: "Fat",
                    current: analysis.dailyLog.totalFat,
                    goal: analysis.goals.dailyFat,
                    unit: "g",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Meal Breakdown Section
    private var mealBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Breakdown")
                .font(.headline)
            
            ForEach(analysis.generateDailySummary().mealBreakdown, id: \.mealType) { breakdown in
                MealBreakdownRow(breakdown: breakdown)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Goals Status Section
    private var goalsStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals Status")
                .font(.headline)
            
            ForEach(Array(analysis.generateDailySummary().goalsMet.keys.sorted()), id: \.self) { goal in
                HStack {
                    Image(systemName: analysis.generateDailySummary().goalsMet[goal] == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(analysis.generateDailySummary().goalsMet[goal] == true ? .green : .red)
                    
                    Text(goal)
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Suggestions Section
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Improvement Suggestions")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingSuggestions.toggle() }) {
                    Text(showingSuggestions ? "Hide" : "Show")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if showingSuggestions {
                ForEach(analysis.generateImprovementSuggestions(), id: \.self) { suggestion in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(suggestion)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
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
struct NutritionCard: View {
    let title: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(current / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("\(Int(current))")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("/ \(Int(goal)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MealBreakdownRow: View {
    let breakdown: MealBreakdown
    
    var body: some View {
        HStack {
            Text(breakdown.mealType.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(breakdown.mealType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(breakdown.calories)) calories • \(breakdown.itemCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if breakdown.averageHealthScore > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<Int(breakdown.averageHealthScore), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}
