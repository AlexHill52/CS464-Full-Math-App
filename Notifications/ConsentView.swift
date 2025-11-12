import SwiftUI

struct ConsentView: View {
    @Binding var participantId: String
    var onConsent: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Research Study Consent")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Purpose")
                        .font(.headline)
                    Text("This study examines how notification framing affects user engagement with math tasks.")
                    
                    Text("What You'll Do")
                        .font(.headline)
                        .padding(.top)
                    Text("• Receive 3 notifications daily at 10am, 2pm, and 6pm")
                    Text("• Each notification will prompt you to solve 3 simple math problems")
                    Text("• Study duration: 7 days")
                    Text("• Tap the '+' button when you see a notification")
                    
                    Text("Data Collected")
                        .font(.headline)
                        .padding(.top)
                    Text("• Participant ID")
                    Text("• Notification level (low/medium/high affability)")
                    Text("• Time notification sent")
                    Text("• Time notification clicked")
                    Text("• Response latency")
                    Text("• Number of problems solved and accuracy")
                    
                    Text("Privacy")
                        .font(.headline)
                        .padding(.top)
                    Text("All data is stored locally on your device. No personal information is collected.")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Participant ID")
                        .font(.headline)
                    TextField("Enter ID (e.g., P001)", text: $participantId)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                }
                .padding(.vertical)
                
                Button(action: onConsent) {
                    Text("I Consent to Participate")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(participantId.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
//                .disabled(participantId.isEmpty)
            }
            .padding()
        }
    }
}
