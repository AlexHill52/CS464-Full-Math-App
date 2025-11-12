import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var experimentData: [ExperimentData]
    @Query private var notificationRecords: [NotificationRecord]
    
    @State private var participantId: String = ""
    @State private var hasConsented: Bool = false
    @State private var currentScreen: AppScreen = .consent
    @State private var notificationsEnabled: Bool = false
    @State private var currentDayNumber: Int = 1
    @State private var showDebugMenu = false
    
    enum AppScreen {
        case consent
        case dashboard
        case mathProblems
        case results
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentScreen {
                case .consent:
                    ConsentView(
                        participantId: $participantId,
                        onConsent: {
                            hasConsented = true
                            requestNotificationPermission()
                            currentScreen = .dashboard
                        }
                    )
                case .dashboard:
                    DashboardView(
                        participantId: participantId,
                        dayNumber: currentDayNumber,
                        notificationsEnabled: notificationsEnabled,
                        onStartProblems: {
                            currentScreen = .mathProblems
                        },
                        onViewResults: {
                            currentScreen = .results
                        },
                        onTestNotification: {
                            scheduleTestNotification()
                        },
                        onCheckScheduled: {
                            checkScheduledNotifications()
                        },
                        onGetStats: {
                            getNotificationStats()
                        },
                        onGetResponseRates: {
                            getResponseRatesByLevel()
                        }
                    )
                case .mathProblems:
                    MathProblemsView(
                        participantId: participantId,
                        onComplete: { problems, correct in
                            recordProblemCompletion(attempted: problems, correct: correct)
                            currentScreen = .dashboard
                        }
                    )
                case .results:
                    ResultsView(
                        participantId: participantId,
                        records: notificationRecords.filter { $0.participantId == participantId },
                        onBack: {
                            currentScreen = .dashboard
                        }
                    )
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
            scheduleAllNotifications()
            checkScheduledNotifications()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                notificationsEnabled = success
                if success {
                    scheduleAllNotifications()
                    checkScheduledNotifications()
                }
            }
        }
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleAllNotifications() {
        guard notificationsEnabled, !participantId.isEmpty else { return }
        
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let directMessages = [
            "Complete your math question by 11:59pm.",
            "Math tasks due by midnight.",
            "Finish your daily math problems before 11:59pm.",
            "Your math assignment expires at midnight.",
            "Complete the math exercises by end of day.",
            "Math problems must be completed by 11:59pm today.",
            "Submit your math solutions before midnight."
        ]
        
        let politeMessages = [
            "Please solve your questions for today.",
            "We'd appreciate if you complete today's math problems.",
            "Kindly complete your daily math exercises.",
            "Your participation in today's math tasks is requested.",
            "Would you mind solving today's math problems?",
            "We invite you to complete your daily math questions.",
            "Please take a moment for today's math exercises."
        ]
        
        let affableMessages = [
            "A new math challenge awaits! Can you solve today's problems? 🧠",
            "Ready for some brain exercise? Your math problems are waiting! 💪",
            "Hey there! Time to flex those math muscles! ✨",
            "Your daily math adventure is here! Let's solve some problems! 🚀",
            "Feeling smart today? Prove it with these math questions! 😎",
            "Math time! Let's make those neurons dance! 💃",
            "Hello! Your brain will thank you for these math exercises! 🎯"
        ]
        
        let levels = ["direct", "polite", "affable"]
        let times = [10, 14, 18] // 10am, 2pm, 6pm
        let totalDays = 7
        
        let calendar = Calendar.current
        let now = Date()
        
        for day in 0..<totalDays {
            for (timeIndex, hour) in times.enumerated() {
                let levelIndex = timeIndex // 10am=direct, 2pm=polite, 6pm=affable
                let messageIndex = day % 7 // Cycle through 7 messages for each level
                
                let message: String
                switch levelIndex {
                case 0: // direct
                    message = directMessages[messageIndex]
                case 1: // polite
                    message = politeMessages[messageIndex]
                case 2: // affable
                    message = affableMessages[messageIndex]
                default:
                    message = "Please complete your math problems."
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Math Problems"
                content.body = message
                content.sound = .default
                content.userInfo = [
                    "level": levels[levelIndex],
                    "participantId": participantId,
                    "scheduledTime": Date().timeIntervalSince1970,
                    "day": day + 1,
                    "timeIndex": timeIndex
                ]
                
                // Calculate the specific date for this notification
                var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                dateComponents.hour = hour
                dateComponents.minute = 0
                
                if let baseDate = calendar.date(from: dateComponents) {
                    if let notificationDate = calendar.date(byAdding: .day, value: day, to: baseDate) {
                        // Only schedule if it's in the future
                        if notificationDate > now {
                            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                            
                            let identifier = "math-\(participantId)-day\(day+1)-\(levels[levelIndex])-\(hour)00"
                            let request = UNNotificationRequest(
                                identifier: identifier,
                                content: content,
                                trigger: trigger
                            )
                            
                            UNUserNotificationCenter.current().add(request)
                            print("Scheduled: Day \(day+1) \(hour):00 - \(levels[levelIndex])")
                        }
                    }
                }
            }
        }
        
        print("Scheduled \(totalDays * times.count) notifications for participant \(participantId)")
    }
    
    func checkScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("=== SCHEDULED NOTIFICATIONS ===")
            print("Total scheduled: \(requests.count)")
            
            let sortedRequests = requests.sorted { first, second in
                guard let firstTrigger = first.trigger as? UNCalendarNotificationTrigger,
                      let secondTrigger = second.trigger as? UNCalendarNotificationTrigger,
                      let firstDate = Calendar.current.date(from: firstTrigger.dateComponents),
                      let secondDate = Calendar.current.date(from: secondTrigger.dateComponents) else {
                    return false
                }
                return firstDate < secondDate
            }
            
            for request in sortedRequests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let date = Calendar.current.date(from: trigger.dateComponents) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, h:mm a"
                    print("\(formatter.string(from: date)) - \(request.content.body)")
                }
            }
            print("===============================")
        }
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Math Problems - TEST"
        content.body = "This is a test notification. Please complete your math problems."
        content.sound = .default
        content.userInfo = [
            "level": "test",
            "participantId": participantId,
            "scheduledTime": Date().timeIntervalSince1970
        ]
        
        // Trigger in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification-\(UUID())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("✅ Test notification scheduled for 5 seconds from now")
    }

    func scheduleMultipleTestNotifications() {
        let testMessages = [
            "Test 1: Direct style notification",
            "Test 2: Polite style notification",
            "Test 3: Affable style notification 🎉"
        ]
        
        for (index, message) in testMessages.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Math Problems - TEST"
            content.body = message
            content.sound = .default
            content.userInfo = [
                "level": "test",
                "participantId": participantId,
                "scheduledTime": Date().timeIntervalSince1970
            ]
            
            // Schedule each test 10 seconds apart
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(5 + (index * 10)), repeats: false)
            let request = UNNotificationRequest(identifier: "test-batch-\(UUID())", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            print("✅ Test notification \(index + 1) scheduled")
        }
    }
    
    // Data Retrieval Functions
    func getNotificationStats() {
        let directNotifications = notificationRecords.filter { $0.notificationLevel == "direct" && $0.participantId == participantId }
        let politeNotifications = notificationRecords.filter { $0.notificationLevel == "polite" && $0.participantId == participantId }
        let affableNotifications = notificationRecords.filter { $0.notificationLevel == "affable" && $0.participantId == participantId }
        
        print("=== NOTIFICATION STATS ===")
        print("Direct notifications: \(directNotifications.count)")
        print("Polite notifications: \(politeNotifications.count)")
        print("Affable notifications: \(affableNotifications.count)")
        
        // Print details for each type
        printNotificationDetails(notifications: directNotifications, level: "Direct")
        printNotificationDetails(notifications: politeNotifications, level: "Polite")
        printNotificationDetails(notifications: affableNotifications, level: "Affable")
        print("==========================")
    }
    
    func printNotificationDetails(notifications: [NotificationRecord], level: String) {
        if !notifications.isEmpty {
            print("\n\(level) Notifications:")
            for notification in notifications.sorted(by: { $0.dayNumber < $1.dayNumber }) {
                let clicked = notification.notificationClickedTime != nil ? "YES" : "NO"
                let latency = notification.responseLatency != nil ? "\(Int(notification.responseLatency!))s" : "N/A"
                let accuracy = notification.problemsAttempted > 0 ?
                    "\(Int(Double(notification.problemsCorrect) / Double(notification.problemsAttempted) * 100))%" : "N/A"
                
                print("  Day \(notification.dayNumber): Clicked=\(clicked), Latency=\(latency), Problems=\(notification.problemsCorrect)/\(notification.problemsAttempted), Accuracy=\(accuracy)")
            }
        } else {
            print("\n\(level) Notifications: None recorded")
        }
    }
    
    func getResponseRatesByLevel() {
        let levels = ["direct", "polite", "affable"]
        
        print("=== RESPONSE RATES BY LEVEL ===")
        for level in levels {
            let notifications = notificationRecords.filter { $0.notificationLevel == level && $0.participantId == participantId }
            let clickedCount = notifications.filter { $0.notificationClickedTime != nil }.count
            let responseRate = notifications.count > 0 ? Double(clickedCount) / Double(notifications.count) * 100 : 0
            
            print("\(level.capitalized): \(clickedCount)/\(notifications.count) (\(String(format: "%.1f", responseRate))%)")
        }
        print("===============================")
    }
    
    func recordProblemCompletion(attempted: Int, correct: Int) {
        let record = NotificationRecord(
            participantId: participantId,
            notificationLevel: "test",
            notificationSentTime: Date(),
            problemsAttempted: attempted,
            problemsCorrect: correct
        )
        modelContext.insert(record)
    }
}
