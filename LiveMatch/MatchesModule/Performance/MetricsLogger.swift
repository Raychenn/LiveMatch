//
//  MetricsLogger.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import Foundation
import os.log

// MARK: - Metrics Logger

class MetricsLogger {
    
    // MARK: - Singleton
    
    static let shared = MetricsLogger()
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.livematch.app", category: "metrics")
    private let fileManager = FileManager.default
    private var metricsFileURL: URL?
    
    // MARK: - Metrics Storage
    
    private var sessionMetrics: SessionMetrics = SessionMetrics()
    private let metricsQueue = DispatchQueue(label: "metrics.queue", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Interface
    
    func logUpdateReceived(matchID: Int, latency: TimeInterval) {
        metricsQueue.async { [weak self] in
            self?.sessionMetrics.updatesReceived += 1
            self?.sessionMetrics.totalLatency += latency
            self?.sessionMetrics.lastUpdateTime = Date()
            
            self?.logger.info("📊 Update received - Match: \(matchID), Latency: \(String(format: "%.3f", latency))s")
        }
    }
    
    func logUIUpdate(matchesCount: Int, updateType: UIUpdateType) {
        metricsQueue.async { [weak self] in
            self?.sessionMetrics.uiUpdates += 1
            self?.sessionMetrics.lastUIUpdateTime = Date()
            
            self?.logger.info("🖥️ UI Update - Type: \(updateType.rawValue), Matches: \(matchesCount)")
        }
    }
    
    func logError(_ error: Error, context: String) {
        metricsQueue.async { [weak self] in
            self?.sessionMetrics.errors += 1
            
            self?.logger.error("❌ Error in \(context): \(error.localizedDescription)")
        }
    }
    
    func logPerformanceMetrics() {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let avgLatency = self.sessionMetrics.updatesReceived > 0 ? 
                self.sessionMetrics.totalLatency / Double(self.sessionMetrics.updatesReceived) : 0
            
            let metrics = """
            📊 Performance Metrics:
            - Updates Received: \(self.sessionMetrics.updatesReceived)
            - UI Updates: \(self.sessionMetrics.uiUpdates)
            - Errors: \(self.sessionMetrics.errors)
            - Average Latency: \(String(format: "%.3f", avgLatency))s
            - Session Duration: \(String(format: "%.1f", self.sessionMetrics.sessionDuration))s
            """
            
            self.logger.info("\(metrics)")
        }
    }
    
    func getCurrentMetrics() -> SessionMetrics {
        return sessionMetrics
    }
    
    func resetSession() {
        metricsQueue.async { [weak self] in
            self?.sessionMetrics = SessionMetrics()
            self?.logger.info("🔄 Session metrics reset")
        }
    }
}

// MARK: - Supporting Types

struct SessionMetrics: Codable {
    var sessionStartTime: Date = Date()
    var updatesReceived: Int = 0
    var uiUpdates: Int = 0
    var errors: Int = 0
    var totalLatency: TimeInterval = 0
    var lastUpdateTime: Date?
    var lastUIUpdateTime: Date?
    
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }
    
    var averageLatency: TimeInterval {
        updatesReceived > 0 ? totalLatency / Double(updatesReceived) : 0
    }
}

enum UIUpdateType: String, Codable {
    case initialLoad = "Initial Load"
    case batchUpdate = "Batch Update"
    case singleUpdate = "Single Update"
    case refresh = "Refresh"
}

