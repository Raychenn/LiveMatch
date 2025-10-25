import Foundation

// MARK: - API Simulator

class APISimulator {
    static let shared = APISimulator()
    
    private init() {}
    
    // MARK: - GET /matches API Simulation
    
    func getMatches() async throws -> [Match] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let matches = generateSampleMatches(count: 100)
        print("🌐 API: GET /matches - Retrieved \(matches.count) matches")
        return matches
    }
    
    // MARK: - GET /odds API Simulation
    
    func getOdds() async throws -> [Odds] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let odds = generateSampleOdds(count: 100)
        print("🌐 API: GET /odds - Retrieved \(odds.count) odds")
        return odds
    }
    
    // MARK: - Sample Data Generation
    
    private func generateSampleMatches(count: Int) -> [Match] {
        let teamNames = [
            "Eagles", "Tigers", "Lions", "Bears", "Wolves", "Hawks", "Falcons", "Panthers",
            "Jaguars", "Leopards", "Cheetahs", "Cougars", "Lynx", "Bobcats", "Wildcats",
            "Sharks", "Dolphins", "Whales", "Orcas", "Seals", "Penguins", "Puffins",
            "Ravens", "Crows", "Owls", "Eagles", "Hawks", "Falcons", "Vultures", "Condors",
            "Dragons", "Phoenix", "Griffins", "Unicorns", "Pegasus", "Centaur", "Minotaur",
            "Thunder", "Lightning", "Storm", "Blizzard", "Hurricane", "Tornado", "Cyclone",
            "Fire", "Ice", "Water", "Earth", "Wind", "Metal", "Wood", "Stone", "Crystal",
            "Stars", "Moon", "Sun", "Comet", "Asteroid", "Meteor", "Galaxy", "Nebula",
            "Warriors", "Knights", "Paladins", "Rangers", "Mages", "Rogues", "Assassins",
            "Titans", "Giants", "Dwarves", "Elves", "Orcs", "Goblins", "Trolls", "Ogres",
            "Vikings", "Spartans", "Samurai", "Ninjas", "Pirates", "Corsairs", "Buccaneers",
            "Rebels", "Alliance", "Empire", "Republic", "Federation", "Union", "League",
            "Crusaders", "Templars", "Inquisitors", "Monks", "Priests", "Bishops", "Cardinals"
        ]
        
        var matches: [Match] = []
        let calendar = Calendar.current
        let now = Date()
        
        for i in 1...count {
            let matchID = 1000 + i
            
            // Random team selection
            let shuffledTeams = teamNames.shuffled()
            let teamA = shuffledTeams[0]
            let teamB = shuffledTeams[1]
            
            // Generate start time (next 7 days)
            let daysFromNow = Int.random(in: 0...7)
            let hoursFromNow = Int.random(in: 0...23)
            let minutesFromNow = Int.random(in: 0...59)
            
            let startTime = calendar.date(byAdding: .day, value: daysFromNow, to: now)
                .flatMap { calendar.date(byAdding: .hour, value: hoursFromNow, to: $0) }
                .flatMap { calendar.date(byAdding: .minute, value: minutesFromNow, to: $0) } ?? now
            
            let match = Match(
                id: matchID,
                teamA: teamA,
                teamB: teamB,
                startTime: startTime
            )
            
            matches.append(match)
        }
        
        // Sort by start time
        matches.sort { $0.startTime < $1.startTime }
        
        return matches
    }
    
    private func generateSampleOdds(count: Int) -> [Odds] {
        var odds: [Odds] = []
        
        for i in 1...count {
            let matchID = 1000 + i
            
            // Generate realistic odds (1.1 to 3.0)
            let teamAOdds = Double.random(in: 1.1...3.0)
            let teamBOdds = Double.random(in: 1.1...3.0)
            
            // Round to 2 decimal places
            let roundedTeamAOdds = round(teamAOdds * 100) / 100.0
            let roundedTeamBOdds = round(teamBOdds * 100) / 100.0
            
            let odd = Odds(
                id: matchID,
                teamAOdds: roundedTeamAOdds,
                teamBOdds: roundedTeamBOdds
            )
            
            odds.append(odd)
        }
        
        return odds
    }
    
    // MARK: - JSON Serialization for Testing
    
    func getMatchesJSON() -> String {
        let matches = generateSampleMatches(count: 5) // Small sample for JSON
        let response = MatchesResponse(matches: matches)
        
        do {
            let data = try JSONEncoder().encode(response)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to encode matches\"}"
        }
    }
    
    func getOddsJSON() -> String {
        let odds = generateSampleOdds(count: 5) // Small sample for JSON
        let response = OddsResponse(odds: odds)
        
        do {
            let data = try JSONEncoder().encode(response)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to encode odds\"}"
        }
    }
}
