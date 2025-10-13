//
//  ContentView.swift
//  FoodTrackerApp
//
//  Created by Divakar Saini on 10/11/25.
//

import SwiftUI
import Combine
internal import AVFoundation

struct ContentView: View {
    @StateObject private var dailyLog = DailyFoodLog()
    @StateObject private var userProfile = UserProfile()
    @StateObject private var cameraPermissions = CameraPermissionManager()
    
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    // Computed property to create analysis with personalized goals
    private var analysis: NutritionAnalysis {
        NutritionAnalysis(dailyLog: dailyLog, goals: userProfile.nutritionGoals)
    }
    
    var body: some View {
        TabView {
            // Daily Summary Tab
            DailySummaryView(analysis: analysis)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Today")
                }
            
            // Add Food Tab
            AddFoodView(dailyLog: dailyLog, analysis: analysis)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Food")
                }
            
            // Health Insights Tab
            HealthInsightsView(analysis: analysis)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Insights")
                }
        }
    }
}

// MARK: - Add Food View
struct AddFoodView: View {
    @ObservedObject var dailyLog: DailyFoodLog
    @ObservedObject var analysis: NutritionAnalysis
    @StateObject private var cameraPermissions = CameraPermissionManager()
    @StateObject private var foodRecognition = FoodRecognitionService()
    
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Food")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    if cameraPermissions.permissionStatus == .authorized {
                        showingCamera = true
                    } else {
                        cameraPermissions.requestPermission()
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo of Food")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(foodRecognition.isAnalyzing)
                
                if foodRecognition.isAnalyzing {
                    ProgressView("Analyzing food...")
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingCamera) {
                CameraView(
                    isPresented: $showingCamera,
                    capturedImage: $capturedImage
                ) { image in
                    capturedImage = image
                    foodRecognition.analyzeFoodImage(image)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
