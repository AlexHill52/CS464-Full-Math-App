import SwiftUI
import SwiftData
import UserNotifications

@main
struct NotificationsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExperimentData.self,
            NotificationRecord.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // CRITICAL: Stores to disk permanently
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully - Data persists on disk")
            return container
        } catch {
            print("❌ Fatal error creating ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Set up notification delegate
                    UNUserNotificationCenter.current().delegate = appDelegate
                    // Pass model context to app delegate
                    appDelegate.modelContext = sharedModelContainer.mainContext
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
