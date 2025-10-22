import SwiftUI
import SwiftUI
import Combine

struct DailySummaryView: View {
    @ObservedObject var analysis: NutritionAnalysis
    @State private var showingSuggestions = false
    @State private var showingFoodManagement = false
    
    // Computed property to avoid multiple expensive calls
    private var dailySummary: DailySummary {
        analysis.generateDailySummary()
    }
    
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
                    
                    // Recent Food Analysis
                    recentFoodAnalysisSection
                    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage Foods") {
                        showingFoodManagement = true
                    }
                }
            }
            .sheet(isPresented: $showingFoodManagement) {
                FoodManagementView(analysis: analysis)
            }
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
    
    // MARK: - Recent Food Analysis Section
    private var recentFoodAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Food Analysis")
                .font(.headline)
            
            if analysis.dailyLog.foodItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("No food logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Take a photo to get started!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                List {
                    ForEach(Array(analysis.dailyLog.foodItems.suffix(3).reversed())) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("\(Int(item.calories)) cal • \(Int(item.protein))g protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(item.healthScore))/10")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(item.healthScoreColor)
                                
                                HStack(spacing: 1) {
                                    ForEach(0..<min(Int(item.healthScore), 10), id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        let items = Array(analysis.dailyLog.foodItems.suffix(3).reversed())
                        for index in indexSet {
                            if index < items.count {
                                analysis.dailyLog.removeFoodItem(items[index])
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .frame(height: 200)
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
            
            ForEach(dailySummary.mealBreakdown, id: \.mealType) { breakdown in
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
            
            ForEach(Array(dailySummary.goalsMet.keys.sorted()), id: \.self) { goal in
                HStack {
                    Image(systemName: dailySummary.goalsMet[goal] == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(dailySummary.goalsMet[goal] == true ? .green : .red)
                    
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
                    ForEach(0..<min(Int(breakdown.averageHealthScore), 10), id: \.self) { _ in
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

// MARK: - FoodItem Extension for Health Score Color
extension FoodItem {
    var healthScoreColor: Color {
        switch healthScore {
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
}
