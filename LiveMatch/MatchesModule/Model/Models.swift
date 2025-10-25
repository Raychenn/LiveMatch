//
//  Models.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import Foundation

// MARK: - Data Models

struct Match: Codable, Identifiable, Hashable {
    let id: Int
    let teamA: String
    let teamB: String
    let startTime: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "matchID"
        case teamA, teamB, startTime
    }
    
    init(id: Int, teamA: String, teamB: String, startTime: Date) {
        self.id = id
        self.teamA = teamA
        self.teamB = teamB
        self.startTime = startTime
    }
}

struct Odds: Codable, Identifiable, Hashable {
    let id: Int
    let teamAOdds: Double
    let teamBOdds: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "matchID"
        case teamAOdds, teamBOdds
    }
    
    init(id: Int, teamAOdds: Double, teamBOdds: Double) {
        self.id = id
        self.teamAOdds = teamAOdds
        self.teamBOdds = teamBOdds
    }
}

struct MatchWithOdds: Identifiable, Hashable {
    let match: Match
    let odds: Odds
    
    var id: Int { match.id }
    
    init(match: Match, odds: Odds) {
        self.match = match
        self.odds = odds
    }
}

// MARK: - API Response Models

struct MatchesResponse: Codable {
    let matches: [Match]
}

struct OddsResponse: Codable {
    let odds: [Odds]
}

// MARK: - WebSocket Update Model

struct OddsUpdate: Codable {
    let matchID: Int
    let teamAOdds: Double
    let teamBOdds: Double
}

// MARK: - Metrics Model

struct UpdateMetrics {
    let receivedUpdates: Int
    let uiUpdates: Int
    let averageLatency: TimeInterval
    let lastUpdateTime: Date
    
    init(receivedUpdates: Int = 0, uiUpdates: Int = 0, averageLatency: TimeInterval = 0, lastUpdateTime: Date = Date()) {
        self.receivedUpdates = receivedUpdates
        self.uiUpdates = uiUpdates
        self.averageLatency = averageLatency
        self.lastUpdateTime = lastUpdateTime
    }
}
