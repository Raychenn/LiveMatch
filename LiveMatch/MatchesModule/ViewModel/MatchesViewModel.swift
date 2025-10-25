//
//  MatchesViewModel.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import Foundation
import Combine
import UIKit

class MatchesViewModel: MatchesViewModelProtocol {
    
    // MARK: - Properties
    
    enum Input {
        case lifeCycele(ViewControllerLifeCycle)
        case didFinishUpdateSource
        case reloadData
    }
    
    class Output {
        @Published var matches: [MatchWithOdds] = []
        @Published var metrics: UpdateMetrics = UpdateMetrics()
        @Published var isLoading = false
        @Published var errorMessage: String?
    }
    
    private let matchesStore: MatchesStoreProtocol
    private let performanceMonitor: PerformanceMonitorProtocol
    private let webSocketSimulator: WebSocketSimulatorProtocol
    private let state = Output()
    private var cancellables = Set<AnyCancellable>()
        
    // MARK: - Initialization
    
    init(performanceMonitor: PerformanceMonitorProtocol, 
         matchesStore: MatchesStoreProtocol,
         webSocketSimulator: WebSocketSimulatorProtocol? = nil) {
        self.matchesStore = matchesStore
        self.webSocketSimulator = webSocketSimulator ?? WebSocketSimulator(matchesStore: matchesStore)
        self.performanceMonitor = performanceMonitor
        setupBindings()
    }
    
    deinit {
        webSocketSimulator.stopSimulation()
    }
    
    // MARK: - Public Interface
    
    func transform(input: AnyPublisher<MatchesViewModel.Input, Never>) -> MatchesViewModel.Output {
        input.sink { [weak self] event in
            guard let self else { return }
            
            switch event {
            case .lifeCycele(let viewControllerLifeCycle):
                switch viewControllerLifeCycle {
                case .viewDidLoad:
                    loadInitialData()
                    startRealTimeUpdates()
                    startMonitoring()
                case .viewDidAppear:
                    startRealTimeUpdates()
                case .viewDidDisappear:
                    stopRealTimeUpdates()
                    stopMonitoring()
                case .viewWillAppear:
                    break
                case .viewWillDisappear:
                    break
                @unknown default:
                    break
                }
            case .didFinishUpdateSource:
                performanceMonitor.trackUIUpdate(matchesCount: state.matches.count, updateType: .batchUpdate)
                Task { await self.matchesStore.recordUIUpdate() }
            case .reloadData:
                loadInitialData()
            }
        }
        .store(in: &cancellables)
        
        return state
    }
    
    func startRealTimeUpdates() {
        webSocketSimulator.startSimulation()
    }
    
    func stopRealTimeUpdates() {
        webSocketSimulator.stopSimulation()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        Task {
            // Subscribe to matches updates with debouncing
            let updatePublisher = await matchesStore.updatePublisher
            updatePublisher
                .receive(on: DispatchQueue.main)
                .debounce(for: 0.15, scheduler: RunLoop.main)
                .sink { [weak self] updatedMatches in
                    self?.state.matches = updatedMatches
                }
                .store(in: &cancellables)
            
            // Subscribe to metrics updates
            let metricsPublisher = await matchesStore.metricsPublisher
            metricsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] updatedMetrics in
                    self?.state.metrics = updatedMetrics
                }
                .store(in: &cancellables)
        }
    }
    
    private func loadInitialData() {
        self.state.isLoading = true
        self.state.errorMessage = nil
        
        Task {
            await matchesStore.initializeWithSampleData()
            let initialMatches = await matchesStore.getAllMatchesWithOdds()            
            self.state.matches = initialMatches
            self.state.isLoading = false
            self.state.errorMessage = nil
            print("✅ Initial data loaded: \(initialMatches.count) matches")
        }
    }
    
    private func startMonitoring() {
        // Log performance metrics every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            MetricsLogger.shared.logPerformanceMetrics()
        }
    }
    
    private func stopMonitoring() {
        MetricsLogger.shared.logPerformanceMetrics()
    }
}
