import Foundation
import Combine
@testable import LiveMatch

actor MockMatchesStore: MatchesStoreProtocol {
    private let updateSubject = PassthroughSubject<[MatchWithOdds], Never>()
    private let metricsSubject = PassthroughSubject<UpdateMetrics, Never>()
    
    var updatePublisher: AnyPublisher<[MatchWithOdds], Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    var metricsPublisher: AnyPublisher<UpdateMetrics, Never> {
        metricsSubject.eraseToAnyPublisher()
    }
    
    private(set) var initializeCallCount = 0
    private(set) var updateOddsCallCount = 0
    private(set) var getAllMatchesCallCount = 0
    private(set) var recordUIUpdateCallCount = 0
    private(set) var lastUIUpdateTime: Date?
    private(set) var uiUpdateHistory: [(count: Int, time: Date)] = []
    
    private(set) var matches: [MatchWithOdds] = []
    private(set) var metrics = UpdateMetrics()
    
    func initializeWithSampleData() async {
        initializeCallCount += 1
        let match = Match(id: 1, teamA: "Team A", teamB: "Team B", startTime: Date())
        let odds = Odds(id: 1, teamAOdds: 1.5, teamBOdds: 2.5)
        matches = [MatchWithOdds(match: match, odds: odds)]
        Task { @MainActor in
            await updateSubject.send(matches)
        }
    }
    
    func getAllMatchesWithOdds() async -> [MatchWithOdds] {
        getAllMatchesCallCount += 1
        return matches
    }
    
    func updateOdds(_ update: OddsUpdate) async {
        updateOddsCallCount += 1
        let match = matches.first?.match
        let newOdds = Odds(id: update.matchID, teamAOdds: update.teamAOdds, teamBOdds: update.teamBOdds)
        if let match = match {
            matches = [MatchWithOdds(match: match, odds: newOdds)]
            Task { @MainActor in
                await updateSubject.send(matches)
            }
        }
    }
    
    func simulateMetricsUpdate(_ metrics: UpdateMetrics) async {
        self.metrics = metrics
        Task { @MainActor in
            await metricsSubject.send(metrics)
        }
    }
    
    func getCallCounts() async -> (initialize: Int, updateOdds: Int, getAllMatches: Int) {
        return (initializeCallCount, updateOddsCallCount, getAllMatchesCallCount)
    }
    
    func recordUIUpdate() async {
        recordUIUpdateCallCount += 1
        let updateTime = Date()
        lastUIUpdateTime = updateTime
        uiUpdateHistory.append((recordUIUpdateCallCount, updateTime))
        
        metrics = UpdateMetrics(
            receivedUpdates: metrics.receivedUpdates,
            uiUpdates: recordUIUpdateCallCount,
            averageLatency: metrics.averageLatency,
            lastUpdateTime: updateTime
        )
        
        Task { @MainActor in
            await metricsSubject.send(metrics)
        }
    }
    
    func getUIUpdateStats() async -> (callCount: Int, lastUpdate: Date?, history: [(count: Int, time: Date)]) {
        return (recordUIUpdateCallCount, lastUIUpdateTime, uiUpdateHistory)
    }
}
