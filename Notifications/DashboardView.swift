import SwiftUI

struct DashboardView: View {
    var participantId: String
    var dayNumber: Int
    var notificationsEnabled: Bool
    var onStartProblems: () -> Void
    var onViewResults: () -> Void
    var onTestNotification: (() -> Void)? = nil
    var onCheckScheduled: (() -> Void)? = nil
    var onGetStats: (() -> Void)? = nil
    var onGetResponseRates: (() -> Void)? = nil
    @State private var showDebugMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Math Notification Study")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Participant: \(participantId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Study Progress Card
            InfoCard(
                icon: "calendar",
                title: "Study Progress",
                value: "Day \(dayNumber) of 7"
            )
            .padding(.horizontal)
            .padding(.bottom, 30)
            
            Spacer()
            
            // Big Math Problems Button in Center
            VStack(spacing: 20) {
                Text("Ready to Practice?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Button(action: onStartProblems) {
                    VStack(spacing: 15) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Start Math Problems")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("3 quick problems")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                
                Text("When you receive notifications, tap them immediately to solve problems")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // View Results Button at Bottom
            VStack(spacing: 12) {
                Button(action: onViewResults) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Results")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Notification Status
                HStack {
                    Image(systemName: notificationsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notificationsEnabled ? .green : .red)
                    Text(notificationsEnabled ? "Notifications enabled" : "Notifications disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
            }
        }
        .padding(.vertical)
        // Long press gesture for debug menu (only if debug functions are provided)
        .gesture(
            LongPressGesture(minimumDuration: 2.0)
                .onEnded { _ in
                    if onTestNotification != nil { // Only show if debug functions exist
                        showDebugMenu = true
                    }
                }
        )
        .sheet(isPresented: $showDebugMenu) {
            if let onTestNotification = onTestNotification,
               let onCheckScheduled = onCheckScheduled,
               let onGetStats = onGetStats,
               let onGetResponseRates = onGetResponseRates {
                DebugTestView(
                    onTestNotification: onTestNotification,
                    onCheckScheduled: onCheckScheduled,
                    onGetStats: onGetStats,
                    onGetResponseRates: onGetResponseRates
                )
            }
        }
    }
}

struct InfoCard: View {
    var icon: String
    var title: String
    var value: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
