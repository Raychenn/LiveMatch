import XCTest
import Combine
@testable import LiveMatch

@MainActor
final class MatchesViewModelTests: XCTestCase {
    var mockStore: MockMatchesStore!
    var mockWebSocket: MockWebSocketSimulator!
    var mockPerformanceMonitor: MockPerformanceMonitor!
    var viewModel: MatchesViewModel!
    var cancellables: Set<AnyCancellable>!
    var input: PassthroughSubject<MatchesViewModel.Input, Never>!
    
    override func setUp() async throws {
        mockStore = MockMatchesStore()
        mockWebSocket = MockWebSocketSimulator()
        mockPerformanceMonitor = MockPerformanceMonitor()
        viewModel = MatchesViewModel(
            performanceMonitor: mockPerformanceMonitor,
            matchesStore: mockStore,
            webSocketSimulator: mockWebSocket
        )
        cancellables = []
        input = PassthroughSubject()
    }
    
    override func tearDown() {
        mockStore = nil
        mockWebSocket = nil
        mockPerformanceMonitor = nil
        viewModel = nil
        cancellables = nil
        input = nil
    }
    
    func test_viewDidLoad_shouldStartUpdatesAndMonitoring() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let expectation = expectation(description: "Initial data loaded")
        
        output.$matches
            .dropFirst() // Skip initial empty value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        input.send(.lifeCycele(.viewDidLoad))
        
        // Then
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(mockWebSocket.startSimulationCallCount, 1)
        let counts = await mockStore.getCallCounts()
        XCTAssertEqual(counts.initialize, 1)
    }
    
    func test_viewDidDisappear_shouldStopUpdatesAndMonitoring() {
        // Given
        let _ = viewModel.transform(input: input.eraseToAnyPublisher())
        
        // When
        input.send(.lifeCycele(.viewDidDisappear))
        
        // Then
        XCTAssertEqual(mockWebSocket.stopSimulationCallCount, 1)
    }
    
    func test_reloadData_shouldReloadInitialData() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let expectation = expectation(description: "Initial data loaded")
        
        output.$matches
            .dropFirst() // Skip initial empty value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        input.send(.reloadData)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1)
        let counts = await mockStore.getCallCounts()
        XCTAssertEqual(counts.initialize, 1)
    }
    
    func test_matchesUpdate_shouldUpdateOutput() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let expectation = expectation(description: "Matches update")
        var receivedMatches: [MatchWithOdds] = []
        
        output.$matches
            .dropFirst() // Skip initial empty value
            .sink { matches in
                receivedMatches = matches
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await mockStore.initializeWithSampleData()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertFalse(receivedMatches.isEmpty)
        XCTAssertEqual(receivedMatches.count, 1)
        XCTAssertEqual(receivedMatches[0].match.teamA, "Team A")
    }
    
    func test_metricsUpdate_shouldUpdateOutput() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let initExpectation = expectation(description: "Initial data loaded")
        let metricsExpectation = expectation(description: "Metrics update")
        var receivedMetrics: UpdateMetrics?
        
        output.$matches
            .dropFirst() // Skip initial empty value
            .sink { _ in
                initExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        output.$metrics
            .dropFirst() // Skip initial empty value
            .sink { metrics in
                receivedMetrics = metrics
                metricsExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await mockStore.initializeWithSampleData()
        await fulfillment(of: [initExpectation], timeout: 1)
        
        let newMetrics = UpdateMetrics(receivedUpdates: 1, uiUpdates: 1, averageLatency: 0.1, lastUpdateTime: Date())
        await mockStore.simulateMetricsUpdate(newMetrics)
        
        // Then
        await fulfillment(of: [metricsExpectation], timeout: 1)
        XCTAssertEqual(receivedMetrics?.receivedUpdates, 1)
        XCTAssertEqual(receivedMetrics?.uiUpdates, 1)
    }
    
    func test_didFinishUpdateSource_shouldTrackUIUpdate() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let expectation = expectation(description: "Initial data loaded")
        
        output.$matches
            .dropFirst() // Skip initial empty value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await mockStore.initializeWithSampleData()
        await fulfillment(of: [expectation], timeout: 1)
        
        // When
        input.send(.didFinishUpdateSource)
        
        // Then
        XCTAssertEqual(mockPerformanceMonitor.trackUIUpdateCallCount, 1)
        XCTAssertEqual(mockPerformanceMonitor.lastTrackedMatchesCount, 1)
        XCTAssertEqual(mockPerformanceMonitor.lastTrackedUpdateType, .batchUpdate)
    }
    
    func test_recordUIUpdate_shouldIncrementCountAndUpdateMetrics() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let expectation = expectation(description: "Metrics updated")
        
        var receivedMetrics: UpdateMetrics?
        output.$metrics
            .dropFirst()
            .sink { metrics in
                receivedMetrics = metrics
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await mockStore.recordUIUpdate()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1)
        let stats = await mockStore.getUIUpdateStats()
        XCTAssertEqual(stats.callCount, 1)
        XCTAssertNotNil(stats.lastUpdate)
        XCTAssertEqual(stats.history.count, 1)
        XCTAssertEqual(receivedMetrics?.uiUpdates, 1)
    }
    
    func test_multipleUIUpdates_shouldTrackHistory() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        
        // When
        await mockStore.recordUIUpdate()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        await mockStore.recordUIUpdate()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        await mockStore.recordUIUpdate()
        
        // Then
        let stats = await mockStore.getUIUpdateStats()
        XCTAssertEqual(stats.callCount, 3)
        XCTAssertEqual(stats.history.count, 3)
        
        // 檢查時間間隔
        if stats.history.count >= 2 {
            let interval = stats.history[1].time.timeIntervalSince(stats.history[0].time)
            XCTAssertGreaterThan(interval, 0.09) // 確保時間間隔至少 0.09 秒
        }
    }
    
    func test_recordUIUpdate_shouldUpdateMetricsCorrectly() async {
        // Given
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        let metricsExpectation = expectation(description: "Metrics updated")
        metricsExpectation.expectedFulfillmentCount = 2 // 期望收到兩次更新
        
        var receivedMetrics: [UpdateMetrics] = []
        output.$metrics
            .dropFirst()
            .sink { metrics in
                receivedMetrics.append(metrics)
                metricsExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await mockStore.recordUIUpdate()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        await mockStore.recordUIUpdate()
        
        // Then
        await fulfillment(of: [metricsExpectation], timeout: 1)
        XCTAssertEqual(receivedMetrics.count, 2)
        XCTAssertEqual(receivedMetrics.last?.uiUpdates, 2)
        XCTAssertNotNil(receivedMetrics.last?.lastUpdateTime)
    }
}
