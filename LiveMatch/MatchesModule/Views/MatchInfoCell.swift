//
//  MatchInfoCell.swift
//  LiveMatch
//
//  Created by Boray Chen on 2025/10/19.
//

import UIKit

class MatchInfoCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let matchInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        return stackView
    }()
    
    private let oddsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    private let teamALabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let vsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "VS"
        return label
    }()
    
    private let teamBLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let teamAOddsLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()
    
    private let teamBOddsLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.backgroundColor = .systemRed.withAlphaComponent(0.1)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()
    
    // MARK: - Properties
    
    private var currentMatch: MatchWithOdds?
    private var previousOdds: Odds?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Add container view
        contentView.addSubview(containerView)
        
        // Add main stack view to container
        containerView.addSubview(mainStackView)
        
        // Setup match info stack
        matchInfoStackView.addArrangedSubview(teamALabel)
        matchInfoStackView.addArrangedSubview(vsLabel)
        matchInfoStackView.addArrangedSubview(teamBLabel)
        matchInfoStackView.addArrangedSubview(timeLabel)
        
        // Setup odds stack
        oddsStackView.addArrangedSubview(teamAOddsLabel)
        oddsStackView.addArrangedSubview(teamBOddsLabel)
        
        // Add to main stack
        mainStackView.addArrangedSubview(matchInfoStackView)
        mainStackView.addArrangedSubview(oddsStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with matchWithOdds: MatchWithOdds) {
        let match = matchWithOdds.match
        let odds = matchWithOdds.odds
        
        // Update match info
        teamALabel.text = match.teamA
        teamBLabel.text = match.teamB
        timeLabel.text = formatTime(match.startTime)
        
        // Check for odds changes and animate
        let hasOddsChanged = previousOdds?.teamAOdds != odds.teamAOdds || 
                           previousOdds?.teamBOdds != odds.teamBOdds
        
        if hasOddsChanged && previousOdds != nil {
            animateOddsChange()
        }
        
        // Update odds
        teamAOddsLabel.text = String(format: "%.2f", odds.teamAOdds)
        teamBOddsLabel.text = String(format: "%.2f", odds.teamBOdds)
        
        // Store current state
        currentMatch = matchWithOdds
        previousOdds = odds
    }
    
    // MARK: - Animations
    
    private func animateOddsChange() {
        // Flash animation for odds change
        let flashView = UIView()
        flashView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3)
        flashView.layer.cornerRadius = 8
        flashView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(flashView)
        NSLayoutConstraint.activate([
            flashView.topAnchor.constraint(equalTo: containerView.topAnchor),
            flashView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            flashView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            flashView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Animate flash
        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
        }
        
        // Scale animation for odds labels
        UIView.animate(withDuration: 0.2, animations: {
            self.teamAOddsLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.teamBOddsLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.teamAOddsLabel.transform = .identity
                self.teamBOddsLabel.transform = .identity
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentMatch = nil
        previousOdds = nil
        teamALabel.text = nil
        teamBLabel.text = nil
        timeLabel.text = nil
        teamAOddsLabel.text = nil
        teamBOddsLabel.text = nil
    }
}
