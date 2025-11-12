//
//  ExperimentData.swift
//  Notifications
//
//  Created by Kalena Lam on 11/11/25.
//

import Foundation
import SwiftData
import Foundation
import SwiftData

@Model
final class ExperimentData {
    @Attribute(.unique) var id: UUID
    var participantId: String
    var dayNumber: Int
    var problemsSolved: Int
    var timestamp: Date
    
    init(participantId: String, dayNumber: Int, problemsSolved: Int = 0, timestamp: Date = Date()) {
        self.id = UUID()
        self.participantId = participantId
        self.dayNumber = dayNumber
        self.problemsSolved = problemsSolved
        self.timestamp = timestamp
    }
}

@Model
final class NotificationRecord {
    @Attribute(.unique) var id: UUID
    var participantId: String
    var notificationLevel: String // "direct", "polite", "affable"
    var notificationSentTime: Date
    var notificationClickedTime: Date?
    var responseLatency: Double? // in seconds
    var problemsAttempted: Int
    var problemsCorrect: Int
    var timestamp: Date
    var dayNumber: Int
    
    init(participantId: String,
         notificationLevel: String,
         notificationSentTime: Date,
         notificationClickedTime: Date? = nil,
         responseLatency: Double? = nil,
         problemsAttempted: Int = 0,
         problemsCorrect: Int = 0,
         timestamp: Date = Date(),
         dayNumber: Int = 1) {
        
        self.id = UUID()
        self.participantId = participantId
        self.notificationLevel = notificationLevel
        self.notificationSentTime = notificationSentTime
        self.notificationClickedTime = notificationClickedTime
        self.responseLatency = responseLatency
        self.problemsAttempted = problemsAttempted
        self.problemsCorrect = problemsCorrect
        self.timestamp = timestamp
        self.dayNumber = dayNumber
    }
}
