import Foundation

class PerformanceMonitor: PerformanceMonitorProtocol {
    func trackUIUpdate(matchesCount: Int, updateType: UIUpdateType) {
        // Track UI update performance
        print("📊 UI Update: \(matchesCount) matches, type: \(updateType)")
    }
}
