import SwiftUI

struct FoodManagementView: View {
    @ObservedObject var analysis: NutritionAnalysis
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: FoodItem?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(analysis.dailyLog.foodItems.reversed()) { item in
                    FoodItemRow(item: item)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                itemToDelete = item
                                showingDeleteAlert = true
                            }
                            .tint(.red)
                        }
                }
            }
            .navigationTitle("Today's Foods")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Food Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        analysis.dailyLog.removeFoodItem(item)
                    }
                }
            } message: {
                if let item = itemToDelete {
                    Text("Are you sure you want to delete '\(item.name)'? This action cannot be undone.")
                }
            }
        }
    }
}

struct FoodItemRow: View {
    let item: FoodItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("\(Int(item.calories)) cal • \(Int(item.protein))g protein • \(Int(item.carbs))g carbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.mealType.rawValue)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(item.healthScore))/10")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(item.healthScoreColor)
                
                HStack(spacing: 1) {
                    ForEach(0..<min(Int(item.healthScore), 10), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(DateFormatter.timeFormatter.string(from: item.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    FoodManagementView(analysis: NutritionAnalysis(dailyLog: DailyFoodLog()))
}
