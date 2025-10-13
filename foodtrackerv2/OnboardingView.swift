//
//  OnboardingView.swift
//  foodtrackerv2
//
//  Created by Divakar Saini on 10/13/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    let onboardingPages = [
        OnboardingPage(
            title: "Welcome to FoodTracker",
            subtitle: "Track your nutrition and build healthy eating habits",
            imageName: "fork.knife.circle.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Snap & Track",
            subtitle: "Take photos of your meals for instant nutrition analysis",
            imageName: "camera.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Get Insights",
            subtitle: "See detailed nutrition breakdowns and health insights",
            imageName: "chart.line.uptrend.xyaxis",
            color: .purple
        )
    ]
    
    var body: some View {
        VStack {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Bottom button
            VStack(spacing: 16) {
                if currentPage < onboardingPages.count - 1 {
                    HStack {
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Get Started") {
                        hasCompletedOnboarding = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}