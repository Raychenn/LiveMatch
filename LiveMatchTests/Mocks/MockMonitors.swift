import Foundation
@testable import LiveMatch

class MockPerformanceMonitor: PerformanceMonitorProtocol {
    var trackUIUpdateCallCount = 0
    var lastTrackedMatchesCount: Int?
    var lastTrackedUpdateType: UIUpdateType?
    
    func trackUIUpdate(matchesCount: Int, updateType: UIUpdateType) {
        trackUIUpdateCallCount += 1
        lastTrackedMatchesCount = matchesCount
        lastTrackedUpdateType = updateType
    }
}
