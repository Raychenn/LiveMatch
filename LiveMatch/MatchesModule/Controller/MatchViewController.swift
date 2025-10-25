//
//  ViewController.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import UIKit
import Combine

class MatchViewController: UITableViewController {
    
    // MARK: - Properties
    
    private let viewModel: MatchesViewModel
    private var cancellables = Set<AnyCancellable>()
    private let event = PassthroughSubject<MatchesViewModel.Input, Never>()
    private lazy var dataSource: UITableViewDiffableDataSource<Int, MatchWithOdds> = {
        let dataSource = UITableViewDiffableDataSource<Int, MatchWithOdds>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, matchWithOdds in
            guard let self else {
                return UITableViewCell()
            }
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: MatchInfoCell.self),
                for: indexPath
            ) as? MatchInfoCell else {
                return UITableViewCell()
            }
            
            cell.configure(with: matchWithOdds)
            return cell
        }
        return dataSource
    }()
    
    // MARK: - UI Components
    
    private let customRefreshControl = UIRefreshControl()
    private let metricsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        return view
    }()
    
    // MARK: - Lifecycle
    
    init(viewModel: MatchesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        event.send(.lifeCycele(.viewDidLoad))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        event.send(.lifeCycele(.viewDidLoad))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        event.send(.lifeCycele(.viewDidDisappear))
    }
    
    deinit {
        print("deinit called")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Live Match Odds"
        view.backgroundColor = .systemGroupedBackground
        
        // Setup table view
        tableView.register(MatchInfoCell.self, forCellReuseIdentifier: String(describing: MatchInfoCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self.dataSource
        customRefreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = customRefreshControl
        
        setupHeaderView()
    }
    
    private func setupHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)
        headerView.addSubview(metricsLabel)
        
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metricsLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            metricsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            metricsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            metricsLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        tableView.tableHeaderView = headerView
    }
    
    private func setupBindings() {
        
        let output = viewModel.transform(input: event.eraseToAnyPublisher())
        
        output.$matches
            .receive(on: DispatchQueue.main)
            .sink { matches in
                self.updateTableView(with: matches)
            }
            .store(in: &cancellables)
        
        output.$metrics
            .receive(on: DispatchQueue.main)
            .sink { metrics in
                self.updateMetricsLabel(with: metrics)
            }
            .store(in: &cancellables)
        
        output.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { isLoading in
                isLoading ? self.customRefreshControl.beginRefreshing() : self.customRefreshControl.endRefreshing()
            }
            .store(in: &cancellables)
        
        output.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { errorMessage in
                if let errorMessage = errorMessage {
                    self.showErrorAlert(message: errorMessage)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func refreshData() {
        event.send(.reloadData)
    }
    
    // MARK: - UI Updates
    
    private func updateTableView(with matches: [MatchWithOdds]) {
        let startTime = Date()
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, MatchWithOdds>()
        snapshot.appendSections([0])
        snapshot.appendItems(matches, toSection: 0)
        
        dataSource.apply(snapshot, animatingDifferences: true) { 
            let updateLatency = Date().timeIntervalSince(startTime)
            self.event.send(.didFinishUpdateSource)
            print("📊 Table view updated with \(matches.count) matches (latency: \(String(format: "%.3f", updateLatency))s)")
        }
    }
    
    private func updateMetricsLabel(with metrics: UpdateMetrics) {
        let metricsText = """
        📊 Updates: \(metrics.receivedUpdates) | 
        🖥️ UI Updates: \(metrics.uiUpdates) | 
        ⏱️ Avg Latency: \(String(format: "%.3f", metrics.averageLatency))s
        """
        metricsLabel.text = metricsText
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
