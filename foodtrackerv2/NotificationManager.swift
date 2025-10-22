//
//  NotificationManager.swift
//  foodtrackerv2
//
//  Created by Divakar Saini on 10/13/25.
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var notificationsEnabled = true
    
    private let center = UNUserNotificationCenter.current()
    
    // Default meal times
    private let defaultMealTimes = [
        "breakfast": (hour: 8, minute: 0),
        "lunch": (hour: 12, minute: 30),
        "dinner": (hour: 18, minute: 30)
    ]
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleMealReminders()
                } else {
                    print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Meal Reminder Scheduling
    func scheduleMealReminders() {
        guard isAuthorized && notificationsEnabled else { return }
        
        // Clear existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Schedule breakfast reminder
        scheduleMealReminder(
            identifier: "breakfast_reminder",
            title: "🌅 Breakfast Time!",
            body: "Don't forget to snap a photo of your breakfast before you eat!",
            hour: defaultMealTimes["breakfast"]!.hour,
            minute: defaultMealTimes["breakfast"]!.minute
        )
        
        // Schedule lunch reminder
        scheduleMealReminder(
            identifier: "lunch_reminder",
            title: "☀️ Lunch Time!",
            body: "Time for lunch! Take a photo to track your midday meal.",
            hour: defaultMealTimes["lunch"]!.hour,
            minute: defaultMealTimes["lunch"]!.minute
        )
        
        // Schedule dinner reminder
        scheduleMealReminder(
            identifier: "dinner_reminder",
            title: "🌙 Dinner Time!",
            body: "Don't forget to capture your dinner before eating!",
            hour: defaultMealTimes["dinner"]!.hour,
            minute: defaultMealTimes["dinner"]!.minute
        )
        
        print("📅 Scheduled meal reminders for breakfast (8:00 AM), lunch (12:30 PM), and dinner (6:30 PM)")
    }
    
    private func scheduleMealReminder(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule \(identifier): \(error.localizedDescription)")
            } else {
                print("✅ Scheduled \(identifier) for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // MARK: - Notification Control
    func toggleNotifications() {
        notificationsEnabled.toggle()
        if notificationsEnabled {
            scheduleMealReminders()
        } else {
            center.removeAllPendingNotificationRequests()
        }
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all meal reminder notifications")
    }
    
    // MARK: - Custom Meal Times
    func updateMealTimes(breakfast: (Int, Int), lunch: (Int, Int), dinner: (Int, Int)) {
        // Update default meal times
        // This would be called when user customizes their meal times
        scheduleMealReminders()
    }
}
