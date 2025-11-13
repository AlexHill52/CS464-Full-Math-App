//
//  AppDelegate.swift
//  Notifications
//
//  Created by Kalena Lam on 11/13/25.
//
import SwiftUI
import SwiftData
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var modelContext: ModelContext?
    static var shared: AppDelegate?
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AppDelegate.shared = self
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("🔔 User tapped notification!")
        
        let userInfo = response.notification.request.content.userInfo
        
        if let level = userInfo["level"] as? String,
           let participantId = userInfo["participantId"] as? String,
           let scheduledTime = userInfo["scheduledTime"] as? TimeInterval,
           let day = userInfo["day"] as? Int {
            
            let sentTime = Date(timeIntervalSince1970: scheduledTime)
            let clickedTime = Date()
            let latency = clickedTime.timeIntervalSince(sentTime)
            
            print("📊 Recording notification click:")
            print("   Participant: \(participantId)")
            print("   Level: \(level)")
            print("   Day: \(day)")
            print("   Latency: \(Int(latency)) seconds")
            
            if let context = modelContext {
                let record = NotificationRecord(
                    participantId: participantId,
                    notificationLevel: level,
                    notificationSentTime: sentTime,
                    notificationClickedTime: clickedTime,
                    responseLatency: latency,
                    problemsAttempted: 0,
                    problemsCorrect: 0,
                    dayNumber: day
                )
                
                context.insert(record)
                
                do {
                    try context.save()
                    print("✅ Notification click saved to database")
                } catch {
                    print("❌ Error saving notification click: \(error)")
                }
            }
            
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenMathProblems"),
                object: nil,
                userInfo: ["participantId": participantId, "day": day, "level": level]
            )
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification received while app is open")
        completionHandler([.banner, .sound, .badge])
    }
}
