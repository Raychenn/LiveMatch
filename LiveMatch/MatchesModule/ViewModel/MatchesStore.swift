//
//  MatchesStore.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import Foundation
import Combine

// MARK: - Thread-Safe MatchesStore Actor

actor MatchesStore: MatchesStoreProtocol {
    
    // MARK: - Properties
    
    private var matches: [Int: Match] = [:]
    private var odds: [Int: Odds] = [:]
    private let updateSubject = PassthroughSubject<[MatchWithOdds], Never>()
    private let metricsSubject = PassthroughSubject<UpdateMetrics, Never>()
    
    private var metrics = UpdateMetrics()
    private var updateCount = 0
    private var latencySum: TimeInterval = 0
    
    // MARK: - Public Interface
    
    var updatePublisher: AnyPublisher<[MatchWithOdds], Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    var metricsPublisher: AnyPublisher<UpdateMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    func initializeWithSampleData() async {
        do {
            // Simulate API calls for initial data loading
            print("🔄 Loading initial data from API...")
            
            let loadedMatches = try await APISimulator.shared.getMatches()
            let loadedOdds = try await APISimulator.shared.getOdds()
            
            await loadMatches(loadedMatches)
            await loadOdds(loadedOdds)
            
            print("✅ Initial data loaded from API: \(loadedMatches.count) matches, \(loadedOdds.count) odds")
            
            let initialMatchesWithOdds = await getAllMatchesWithOdds()
            Task { @MainActor in
                await updateSubject.send(initialMatchesWithOdds)
            }
            
        } catch {
            print("❌ Failed to load initial data: \(error)")
            // Fallback to minimal sample data
            await loadFallbackData()
        }
    }
    
    private func loadFallbackData() async {
        let fallbackMatches = createSampleMatches()
        let fallbackOdds = createSampleOdds()
        
        await loadMatches(fallbackMatches)
        await loadOdds(fallbackOdds)
        
        print("⚠️ Using fallback data: \(fallbackMatches.count) matches, \(fallbackOdds.count) odds")
        
        let fallbackMatchesWithOdds = await getAllMatchesWithOdds()
        Task { @MainActor in
            await updateSubject.send(fallbackMatchesWithOdds)
        }
    }
    
    // MARK: - Data Loading
    
    func loadMatches(_ matches: [Match]) async {
        for match in matches {
            self.matches[match.id] = match
        }
        print("📊 Loaded \(matches.count) matches")
    }
    
    func loadOdds(_ odds: [Odds]) async {
        for odd in odds {
            self.odds[odd.id] = odd
        }
        print("📊 Loaded \(odds.count) odds")
    }
    
    // MARK: - Odds Updates
    
    func updateOdds(_ update: OddsUpdate) async {
        let startTime = Date()
        
        guard let existingOdds = odds[update.matchID] else {
            print("⚠️ No existing odds found for match \(update.matchID)")
            return
        }
        
        let newOdds = Odds(
            id: update.matchID,
            teamAOdds: update.teamAOdds,
            teamBOdds: update.teamBOdds
        )
        
        // Check if odds actually changed
        let hasChanged = existingOdds.teamAOdds != newOdds.teamAOdds || 
                        existingOdds.teamBOdds != newOdds.teamBOdds
        
        if hasChanged {
            odds[update.matchID] = newOdds
            updateCount += 1
            
            // Calculate latency
            let latency = Date().timeIntervalSince(startTime)
            latencySum += latency
            
            // Log metrics
            MetricsLogger.shared.logUpdateReceived(matchID: update.matchID, latency: latency)
            
            // Update metrics
            metrics = UpdateMetrics(
                receivedUpdates: updateCount,
                uiUpdates: metrics.uiUpdates,
                averageLatency: latencySum / Double(updateCount),
                lastUpdateTime: Date()
            )
            
            // Publish update
            let matchWithOdds = await getAllMatchesWithOdds()
            Task { @MainActor in
                await updateSubject.send(matchWithOdds)
                await metricsSubject.send(metrics)
            }
            
            print("🔄 Updated odds for match \(update.matchID): \(update.teamAOdds) vs \(update.teamBOdds)")
        }
    }
    
    // MARK: - Data Access
    
    func getAllMatchesWithOdds() async -> [MatchWithOdds] {
        var result: [MatchWithOdds] = []
        
        for (matchId, match) in matches {
            if let matchOdds = odds[matchId] {
                result.append(MatchWithOdds(match: match, odds: matchOdds))
            }
        }
        
        // Sort by start time (most recent first)
        return result.sorted { $0.match.startTime > $1.match.startTime }
    }
    
    // MARK: - Metrics
    
    func recordUIUpdate() async {
        metrics = UpdateMetrics(
            receivedUpdates: metrics.receivedUpdates,
            uiUpdates: metrics.uiUpdates + 1,
            averageLatency: metrics.averageLatency,
            lastUpdateTime: Date()
        )
        Task { @MainActor in
            await metricsSubject.send(metrics)
        }
        
        // Log UI update metrics
        let matchWithOdds = await getAllMatchesWithOdds()
        MetricsLogger.shared.logUIUpdate(matchesCount: matchWithOdds.count, updateType: .batchUpdate)
    }
    
    func getCurrentMetrics() async -> UpdateMetrics {
        return metrics
    }
    
    // MARK: - Sample Data
    
    private func createSampleMatches() -> [Match] {
        let formatter = ISO8601DateFormatter()
        return [
            Match(id: 1001, teamA: "Eagles", teamB: "Tigers", startTime: formatter.date(from: "2025-07-04T13:00:00Z") ?? Date()),
            Match(id: 1002, teamA: "Lions", teamB: "Bears", startTime: formatter.date(from: "2025-07-04T14:30:00Z") ?? Date()),
            Match(id: 1003, teamA: "Wolves", teamB: "Hawks", startTime: formatter.date(from: "2025-07-04T16:00:00Z") ?? Date()),
            Match(id: 1004, teamA: "Sharks", teamB: "Dolphins", startTime: formatter.date(from: "2025-07-04T17:30:00Z") ?? Date()),
            Match(id: 1005, teamA: "Falcons", teamB: "Ravens", startTime: formatter.date(from: "2025-07-04T19:00:00Z") ?? Date())
        ]
    }
    
    private func createSampleOdds() -> [Odds] {
        return [
            Odds(id: 1001, teamAOdds: 1.95, teamBOdds: 2.10),
            Odds(id: 1002, teamAOdds: 1.85, teamBOdds: 2.25),
            Odds(id: 1003, teamAOdds: 2.05, teamBOdds: 1.90),
            Odds(id: 1004, teamAOdds: 1.75, teamBOdds: 2.35),
            Odds(id: 1005, teamAOdds: 2.15, teamBOdds: 1.80)
        ]
    }
}
