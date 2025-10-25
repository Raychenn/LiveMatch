import Foundation
import Combine

// MARK: - Store Protocol
protocol MatchesStoreProtocol: Actor {
    var updatePublisher: AnyPublisher<[MatchWithOdds], Never> { get }
    var metricsPublisher: AnyPublisher<UpdateMetrics, Never> { get }
    
    func initializeWithSampleData() async
    func getAllMatchesWithOdds() async -> [MatchWithOdds]
    func updateOdds(_ update: OddsUpdate) async
    func recordUIUpdate() async
}

// MARK: - WebSocket Protocol
protocol WebSocketSimulatorProtocol {
    func startSimulation()
    func stopSimulation()
}

// MARK: - Monitor Protocols
protocol PerformanceMonitorProtocol {
    func trackUIUpdate(matchesCount: Int, updateType: UIUpdateType)
}


// MARK: - ViewModel Protocol
@preconcurrency protocol MatchesViewModelProtocol {
    func transform(input: AnyPublisher<MatchesViewModel.Input, Never>) -> MatchesViewModel.Output
    func startRealTimeUpdates()
    func stopRealTimeUpdates()
}
