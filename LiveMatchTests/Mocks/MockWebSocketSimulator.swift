import Foundation
@testable import LiveMatch

class MockWebSocketSimulator: WebSocketSimulatorProtocol {
    var startSimulationCallCount = 0
    var stopSimulationCallCount = 0
    
    func startSimulation() {
        startSimulationCallCount += 1
    }
    
    func stopSimulation() {
        stopSimulationCallCount += 1
    }
}
