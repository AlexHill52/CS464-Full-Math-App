//
//  DataExporter.swift
//  Notifications
//
//  Created by Kalena Lam on 11/11/25.
//

import Foundation
import SwiftUI
import SwiftData

class DataExporter {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func exportAllData() -> URL? {
        let descriptor = FetchDescriptor<NotificationRecord>()
        let records: [NotificationRecord]
        let experimentDescriptor = FetchDescriptor<ExperimentData>()
        let experiments: [ExperimentData]
        
        do {
            records = try modelContext.fetch(descriptor)
            experiments = try modelContext.fetch(experimentDescriptor)
        } catch {
            print("Error fetching data: \(error)")
            return nil
        }
        
        // Create CSV content
        var csvString = "participant_id,notification_level,sent_time,clicked_time,response_latency,problems_attempted,problems_correct,timestamp\n"
        
        for record in records {
            let clickedTime = record.notificationClickedTime?.ISO8601Format() ?? "N/A"
            let latency = record.responseLatency?.description ?? "N/A"
            
            csvString += "\"\(record.participantId)\",\"\(record.notificationLevel)\",\"\(record.notificationSentTime.ISO8601Format())\",\"\(clickedTime)\",\"\(latency)\",\"\(record.problemsAttempted)\",\"\(record.problemsCorrect)\",\"\(record.timestamp.ISO8601Format())\"\n"
        }
        
        // Save to temporary file
        let filename = "research_data_\(Date().ISO8601Format()).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error writing CSV: \(error)")
            return nil
        }
    }
}
