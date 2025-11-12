import SwiftUI
import SwiftData
import UserNotifications

@main
struct NotificationsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExperimentData.self,
            NotificationRecord.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully")
            return container
        } catch {
            print("❌ Fatal error creating ModelContainer: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Try to create with in-memory fallback
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            do {
                let fallbackContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("⚠️ Using in-memory ModelContainer as fallback")
                return fallbackContainer
            } catch {
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
