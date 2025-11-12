import SwiftUI

struct DebugTestView: View {
    var onTestNotification: () -> Void
    var onCheckScheduled: () -> Void
    var onGetStats: () -> Void
    var onGetResponseRates: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Notification Testing") {
                    Button("Send Test Notification (5 seconds)") {
                        onTestNotification()
                        dismiss()
                    }
                    
                    Button("Check Scheduled Notifications") {
                        onCheckScheduled()
                    }
                }
                
                Section("Data Retrieval Testing") {
                    Button("Get Notification Stats") {
                        onGetStats()
                    }
                    
                    Button("Get Response Rates by Level") {
                        onGetResponseRates()
                    }
                }
                
                Section("Debug Info") {
                    Text("Check Xcode Console for data logs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Test notification appears in 5 seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
