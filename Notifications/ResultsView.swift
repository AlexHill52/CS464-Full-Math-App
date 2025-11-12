import SwiftUI
import SwiftData

struct ResultsView: View {
    var participantId: String
    var records: [NotificationRecord]
    var onBack: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingExportSheet = false
    @State private var exportFile: URL?
    
    var sortedRecords: [NotificationRecord] {
        records.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack {
            Text("Experiment Results")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            if records.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No data recorded yet")
                        .foregroundColor(.secondary)
                    
                    Text("Complete some math problems to see your results here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary Cards
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Total",
                                value: "\(records.count)",
                                icon: "bell.fill",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Clicked",
                                value: "\(records.filter { $0.notificationClickedTime != nil }.count)",
                                icon: "hand.tap.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Solved",
                                value: "\(records.filter { $0.problemsAttempted > 0 }.count)",
                                icon: "checkmark.circle.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        
                        // Records List
                        VStack(spacing: 12) {
                            ForEach(sortedRecords, id: \.id) { record in
                                RecordCard(record: record)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            
            VStack(spacing: 12) {
                Button("Export Research Data") {
                    exportResearchData()
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: onBack) {
                    Text("Back to Dashboard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let file = exportFile {
                ShareSheet(activityItems: [file])
            }
        }
    }
    
    func exportResearchData() {
        let exporter = DataExporter(modelContext: modelContext)
        exportFile = exporter.exportAllData()
        showingExportSheet = true
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecordCard: View {
    let record: NotificationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(levelColor)
                        .frame(width: 8, height: 8)
                    
                    Text(record.notificationLevel.capitalized)
                        .font(.headline)
                }
                
                Spacer()
                
                if let latency = record.responseLatency {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("\(Int(latency))s")
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline)
                }
            }
            
            Text("Day \(record.dayNumber) • \(record.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if record.problemsAttempted > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Solved: \(record.problemsCorrect)/\(record.problemsAttempted)")
                        .font(.caption)
                    
                    if record.problemsAttempted > 0 {
                        let accuracy = Double(record.problemsCorrect) / Double(record.problemsAttempted) * 100
                        Text("(\(Int(accuracy))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if record.notificationClickedTime == nil {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Not clicked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    var levelColor: Color {
        switch record.notificationLevel {
        case "direct": return .red
        case "polite": return .orange
        case "affable": return .green
        default: return .gray
        }
    }
}

// Share Sheet for exporting
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
