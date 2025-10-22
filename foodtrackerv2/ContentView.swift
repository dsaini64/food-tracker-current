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
    @StateObject private var foodRecognition = FoodRecognitionService()
    @StateObject private var notificationManager = NotificationManager()
    
    @State private var capturedImage: UIImage?
    @State private var selectedTab = 0
    
    // Computed property to create analysis with personalized goals
    private var analysis: NutritionAnalysis {
        NutritionAnalysis(dailyLog: dailyLog, goals: userProfile.nutritionGoals)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Tab - Main Screen (like Snapchat)
            SnapchatCameraView(
                analysis: analysis,
                foodRecognition: foodRecognition
            )
            .tag(0)
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Camera")
            }
            
            // Daily Summary Tab
            DailySummaryView(analysis: analysis)
                .tag(1)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Today")
                }
            
            // Health Insights Tab
            HealthInsightsView(analysis: analysis)
                .tag(2)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Insights")
                }
            
            // Settings Tab
            NotificationSettingsView(
                userProfile: userProfile,
                notificationManager: notificationManager
            )
            .tag(3)
            .tabItem {
                Image(systemName: "bell.fill")
                Text("Settings")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FoodAnalyzed"))) { notification in
            if let foodItem = notification.object as? FoodItem {
                dailyLog.addFoodItem(foodItem)
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            // Check for new day every minute
            dailyLog.checkForNewDay()
        }
        .onAppear {
            // Request notification permission on app launch
            if userProfile.notificationsEnabled {
                notificationManager.requestNotificationPermission()
            }
        }
    }
}


// MARK: - Add Food View (Legacy - now integrated into CameraMainView)
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
