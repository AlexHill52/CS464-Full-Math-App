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
                            saveParticipantId()  // Save to UserDefaults
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
            loadParticipantId()  // Restore from UserDefaults
            checkNotificationPermission()
            if !participantId.isEmpty && hasConsented {
                scheduleAllNotifications()
            }
            calculateCurrentDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMathProblems"))) { notification in
            // Handle notification tap - open math problems
            if let userInfo = notification.userInfo,
               let participantId = userInfo["participantId"] as? String {
                self.participantId = participantId
                self.currentScreen = .mathProblems
            }
        }
    }
    
    // MARK: - Persistence Functions
    
    func saveParticipantId() {
        UserDefaults.standard.set(participantId, forKey: "participantId")
        UserDefaults.standard.set(hasConsented, forKey: "hasConsented")
        UserDefaults.standard.set(Date(), forKey: "studyStartDate")
        print("💾 Saved participant ID: \(participantId)")
    }
    
    func loadParticipantId() {
        if let savedId = UserDefaults.standard.string(forKey: "participantId") {
            participantId = savedId
            hasConsented = UserDefaults.standard.bool(forKey: "hasConsented")
            if hasConsented {
                currentScreen = .dashboard
            }
            print("📂 Loaded participant ID: \(participantId)")
        }
    }
    
    func calculateCurrentDay() {
        if let startDate = UserDefaults.standard.object(forKey: "studyStartDate") as? Date {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            currentDayNumber = min(days + 1, 7)
        }
    }
    
    // MARK: - Notification Functions
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                notificationsEnabled = success
                if success {
                    print("✅ Notifications authorized")
                    scheduleAllNotifications()
                } else {
                    print("❌ Notifications denied: \(error?.localizedDescription ?? "unknown")")
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
        guard notificationsEnabled, !participantId.isEmpty else {
            print("⚠️ Cannot schedule notifications - enabled: \(notificationsEnabled), ID: \(participantId)")
            return
        }
        
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
                let levelIndex = timeIndex
                let messageIndex = day % 7
                
                let message: String
                switch levelIndex {
                case 0: message = directMessages[messageIndex]
                case 1: message = politeMessages[messageIndex]
                case 2: message = affableMessages[messageIndex]
                default: message = "Please complete your math problems."
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
                
                var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                dateComponents.hour = hour
                dateComponents.minute = 0
                
                if let baseDate = calendar.date(from: dateComponents) {
                    if let notificationDate = calendar.date(byAdding: .day, value: day, to: baseDate) {
                        if notificationDate > now {
                            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                            
                            let identifier = "math-\(participantId)-day\(day+1)-\(levels[levelIndex])-\(hour)00"
                            let request = UNNotificationRequest(
                                identifier: identifier,
                                content: content,
                                trigger: trigger
                            )
                            
                            UNUserNotificationCenter.current().add(request) { error in
                                if let error = error {
                                    print("❌ Error scheduling notification: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print("✅ Scheduled \(totalDays * times.count) notifications for participant \(participantId)")
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
        content.body = "This is a test notification. Tap to open math problems."
        content.sound = .default
        content.userInfo = [
            "level": "test",
            "participantId": participantId,
            "scheduledTime": Date().timeIntervalSince1970,
            "day": 1,
            "timeIndex": 0
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-\(UUID())", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("✅ Test notification scheduled for 5 seconds from now")
    }
    
    // MARK: - Data Functions
    
    func recordProblemCompletion(attempted: Int, correct: Int) {
        // Find the most recent notification record that hasn't been completed
        let descriptor = FetchDescriptor<NotificationRecord>(
            predicate: #Predicate { record in
                record.participantId == participantId &&
                record.problemsAttempted == 0
            },
            sortBy: [SortDescriptor(\.notificationClickedTime, order: .reverse)]
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            if let recentRecord = records.first {
                recentRecord.problemsAttempted = attempted
                recentRecord.problemsCorrect = correct
                try modelContext.save()
                print("✅ Updated notification record with problem results: \(correct)/\(attempted)")
            } else {
                // If no notification record found, create standalone record
                let record = NotificationRecord(
                    participantId: participantId,
                    notificationLevel: "manual",
                    notificationSentTime: Date(),
                    notificationClickedTime: Date(),
                    responseLatency: 0,
                    problemsAttempted: attempted,
                    problemsCorrect: correct,
                    dayNumber: currentDayNumber
                )
                modelContext.insert(record)
                try modelContext.save()
                print("✅ Created new record for manual problem completion")
            }
        } catch {
            print("❌ Error recording problem completion: \(error)")
        }
    }
    
    func getNotificationStats() {
        let allRecords = notificationRecords.filter { $0.participantId == participantId }
        
        let directNotifications = allRecords.filter { $0.notificationLevel == "direct" }
        let politeNotifications = allRecords.filter { $0.notificationLevel == "polite" }
        let affableNotifications = allRecords.filter { $0.notificationLevel == "affable" }
        
        print("=== NOTIFICATION STATS ===")
        print("Total records: \(allRecords.count)")
        print("Direct notifications: \(directNotifications.count)")
        print("Polite notifications: \(politeNotifications.count)")
        print("Affable notifications: \(affableNotifications.count)")
        print("==========================")
    }
    
    func getResponseRatesByLevel() {
        let levels = ["direct", "polite", "affable"]
        
        print("=== RESPONSE RATES BY LEVEL ===")
        for level in levels {
            let notifications = notificationRecords.filter {
                $0.notificationLevel == level && $0.participantId == participantId
            }
            let clickedCount = notifications.filter { $0.notificationClickedTime != nil }.count
            let responseRate = notifications.count > 0 ?
                Double(clickedCount) / Double(notifications.count) * 100 : 0
            
            print("\(level.capitalized): \(clickedCount)/\(notifications.count) (\(String(format: "%.1f", responseRate))%)")
        }
        print("===============================")
    }
}
