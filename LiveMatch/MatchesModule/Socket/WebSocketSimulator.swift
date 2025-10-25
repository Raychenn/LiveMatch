//
//  WebSocketSimulator.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import Foundation
import Combine

// MARK: - WebSocket Simulator

class WebSocketSimulator: WebSocketSimulatorProtocol {
    
    // MARK: - Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let matchesStore: MatchesStoreProtocol
    
    // Configuration
    private let updateInterval: TimeInterval = 1.0 // 1 second
    private let maxUpdatesPerSecond = 10
    
    // MARK: - Initialization
    
    init(matchesStore: MatchesStoreProtocol) {
        self.matchesStore = matchesStore
    }
    
    // MARK: - Public Interface
    
    func startSimulation() {
        print("🚀 Starting WebSocket simulation...")
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendRandomUpdates()
            }
        }
    }
    
    func stopSimulation() {
        print("⏹️ Stopping WebSocket simulation...")
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Private Methods
    
    private func sendRandomUpdates() async {
        let allMatches = await matchesStore.getAllMatchesWithOdds()
        
        guard !allMatches.isEmpty else {
            print("⚠️ No matches available for updates - waiting for initial data")
            return
        }
        
        let numberOfUpdates = Int.random(in: 1...maxUpdatesPerSecond)
        
        for _ in 0..<numberOfUpdates {
            let update = generateRandomOddsUpdate(from: allMatches)
            await matchesStore.updateOdds(update)
            
            // Small delay between updates to simulate real network conditions
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    private func generateRandomOddsUpdate(from matches: [MatchWithOdds]) -> OddsUpdate {
        guard let randomMatch = matches.randomElement() else {
            // Fallback if no matches available
            return OddsUpdate(matchID: 1001, teamAOdds: 2.0, teamBOdds: 2.0)
        }
        
        let matchID = randomMatch.match.id
        let currentOdds = randomMatch.odds
        
        // Generate realistic odds changes (±0.05 to ±0.15)
        let changeRange = 0.05...0.15
        let teamAChange = Double.random(in: -changeRange.upperBound...changeRange.upperBound)
        let teamBChange = Double.random(in: -changeRange.upperBound...changeRange.upperBound)
        
        let newTeamAOdds = max(1.1, min(5.0, currentOdds.teamAOdds + teamAChange))
        let newTeamBOdds = max(1.1, min(5.0, currentOdds.teamBOdds + teamBChange))
        
        return OddsUpdate(
            matchID: matchID,
            teamAOdds: round(newTeamAOdds * 100) / 100, // Round to 2 decimal places
            teamBOdds: round(newTeamBOdds * 100) / 100
        )
    }
}

