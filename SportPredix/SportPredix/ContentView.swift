//
//  ContentView.swift
//  SportPredix
//

import SwiftUI

// MARK: - SPORTDB DEV MODELS (Aggiungi in cima)

struct SportDBMatch: Codable, Identifiable {
    let id: Int
    let date: String
    let time: String?
    let homeTeam: SportDBTeam
    let awayTeam: SportDBTeam
    let competition: SportDBCompetition
    let status: String
    let score: SportDBScore?
    let odds: SportDBOdds?
    
    enum CodingKeys: String, CodingKey {
        case id, date, time, status, score, odds
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case competition
    }
}

struct SportDBTeam: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let logo: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, country
        case shortName = "short_name"
        case logo
    }
}

struct SportDBCompetition: Codable {
    let id: Int
    let name: String
    let country: String
    let logo: String?
}

struct SportDBScore: Codable {
    let home: Int?
    let away: Int?
    let halftime: SportDBTimeScore?
    let fulltime: SportDBTimeScore?
    
    enum CodingKeys: String, CodingKey {
        case home, away
        case halftime = "ht"
        case fulltime = "ft"
    }
}

struct SportDBTimeScore: Codable {
    let home: Int?
    let away: Int?
}

struct SportDBOdds: Codable {
    let homeWin: Double?
    let draw: Double?
    let awayWin: Double?
    let over05: Double?
    let under05: Double?
    let over15: Double?
    let under15: Double?
    let over25: Double?
    let under25: Double?
    let over35: Double?
    let under35: Double?
    
    enum CodingKeys: String, CodingKey {
        case homeWin = "home_win"
        case draw
        case awayWin = "away_win"
        case over05 = "over_0_5"
        case under05 = "under_0_5"
        case over15 = "over_1_5"
        case under15 = "under_1_5"
        case over25 = "over_2_5"
        case under25 = "under_2_5"
        case over35 = "over_3_5"
        case under35 = "under_3_5"
    }
}

struct SportDBResponse: Codable {
    let data: [SportDBMatch]
    let meta: SportDBMeta?
}

struct SportDBMeta: Codable {
    let total: Int
    let page: Int
    let perPage: Int
    
    enum CodingKeys: String, CodingKey {
        case total, page
        case perPage = "per_page"
    }
}

// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

// MARK: - MODELS ESISTENTI

enum MatchOutcome: String, Codable {
    case home = "1"
    case draw = "X"
    case away = "2"
    case homeDraw = "1X"
    case homeAway = "12"
    case drawAway = "X2"
    case over05 = "O 0.5"
    case under05 = "U 0.5"
    case over15 = "O 1.5"
    case under15 = "U 1.5"
    case over25 = "O 2.5"
    case under25 = "U 2.5"
    case over35 = "O 3.5"
    case under35 = "U 3.5"
    case over45 = "O 4.5"
    case under45 = "U 4.5"
}

struct Odds: Codable {
    let home: Double
    let draw: Double
    let away: Double
    let homeDraw: Double
    let homeAway: Double
    let drawAway: Double
    let over05: Double
    let under05: Double
    let over15: Double
    let under15: Double
    let over25: Double
    let under25: Double
    let over35: Double
    let under35: Double
    let over45: Double
    let under45: Double
}

struct Match: Identifiable, Codable {
    let id: UUID
    let home: String
    let away: String
    let time: String
    let odds: Odds
    var result: MatchOutcome?
    var goals: Int?
    var competition: String
    var status: String
    var isReal: Bool
    var homeLogo: String?
    var awayLogo: String?
    var actualResult: String?
}

struct BetPick: Identifiable, Codable {
    let id: UUID
    let match: Match
    let outcome: MatchOutcome
    let odd: Double
}

struct BetSlip: Identifiable, Codable {
    let id: UUID
    let picks: [BetPick]
    let stake: Double
    let totalOdd: Double
    let potentialWin: Double
    let date: Date
    
    var isWon: Bool? = nil
    var isEvaluated: Bool = false
    
    var impliedProbability: Double { 1 / totalOdd }
    var expectedValue: Double { potentialWin * impliedProbability - stake }
}

// MARK: - VIEW MODEL

final class BettingViewModel: ObservableObject {
    
    @Published var selectedTab = 0
    @Published var selectedDayIndex = 1
    
    @Published var showSheet = false
    @Published var showSlipDetail: BetSlip?
    
    @Published var balance: Double {
        didSet { UserDefaults.standard.set(balance, forKey: "balance") }
    }
    
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    
    @Published var privacyEnabled: Bool {
        didSet { UserDefaults.standard.set(privacyEnabled, forKey: "privacyEnabled") }
    }
    
    @Published var currentPicks: [BetPick] = []
    @Published var slips: [BetSlip] = []
    
    @Published var dailyMatches: [String: [Match]] = [:]
    
    // API Properties - SPORTDB.DEV
    @Published var isLoading = false
    @Published var apiError: String?
    @Published var useRealMatches = false
    @Published var lastUpdateTime: Date?
    
    private let slipsKey = "savedSlips"
    private let matchesKey = "savedMatches"
    private let useRealMatchesKey = "useRealMatches"
    
    // LA TUA API KEY DI SPORTDB.DEV
    private let apiKey = "3lrwpGshX3JxiXzRTwrnK2DcADKKnz4Uv5lYmVg0"
    private let baseURL = "https://sportdb.dev/api"
    
    var hasAPIKey: Bool {
        return !apiKey.isEmpty && apiKey != "LA_TUA_API_KEY_AQUI"
    }
    
    init() {
        let savedBalance = UserDefaults.standard.double(forKey: "balance")
        self.balance = savedBalance == 0 ? 1000 : savedBalance
        
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.privacyEnabled = UserDefaults.standard.object(forKey: "privacyEnabled") as? Bool ?? false
        
        self.useRealMatches = UserDefaults.standard.object(forKey: useRealMatchesKey) as? Bool ?? false
        
        self.slips = loadSlips()
        self.dailyMatches = loadMatches()
        
        generateTodayIfNeeded()
        
        if useRealMatches && hasAPIKey {
            fetchRealMatchesFromSportDB()
        }
    }
    
    // MARK: - SPORTDB.DEV API FUNCTIONS
    
    func toggleRealMatches() {
        useRealMatches.toggle()
        UserDefaults.standard.set(useRealMatches, forKey: useRealMatchesKey)
        
        if useRealMatches && hasAPIKey {
            fetchRealMatchesFromSportDB()
        } else if !useRealMatches {
            generateTodayIfNeeded()
        } else if useRealMatches && !hasAPIKey {
            apiError = "API key mancante. Usa la chiave di SportDB.dev"
        }
    }
    
    func fetchRealMatchesFromSportDB() {
        guard hasAPIKey else {
            apiError = "API key di SportDB.dev non configurata"
            return
        }
        
        isLoading = true
        apiError = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrow = dateFormatter.string(from: tomorrowDate)
        
        // Endpoint fixtures
        let urlString = "\(baseURL)/football/fixtures?date_from=\(today)&date_to=\(tomorrow)&api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            apiError = "URL non valido per SportDB.dev"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.apiError = "Errore di rete: \(error.localizedDescription)"
                    self?.loadFallbackMatches()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.apiError = "Risposta non valida da SportDB.dev"
                    self?.loadFallbackMatches()
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        self?.apiError = "API key non valida per SportDB.dev"
                    } else if httpResponse.statusCode == 429 {
                        self?.apiError = "Limite richieste raggiunto su SportDB.dev"
                    } else {
                        self?.apiError = "Errore SportDB.dev: \(httpResponse.statusCode)"
                    }
                    self?.loadFallbackMatches()
                    return
                }
                
                guard let data = data else {
                    self?.apiError = "Nessun dato ricevuto da SportDB.dev"
                    self?.loadFallbackMatches()
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(SportDBResponse.self, from: data)
                    
                    if response.data.isEmpty {
                        self?.apiError = "Nessuna partita programmata"
                        self?.loadFallbackMatches()
                    } else {
                        self?.processSportDBMatches(response.data)
                    }
                } catch {
                    self?.apiError = "Errore formato dati SportDB.dev"
                    self?.loadFallbackMatches()
                }
            }
        }
        
        task.resume()
    }
    
    private func processSportDBMatches(_ apiMatches: [SportDBMatch]) {
        var allConvertedMatches: [Match] = []
        
        for apiMatch in apiMatches {
            let timeString: String
            if let time = apiMatch.time {
                timeString = time
            } else {
                let fullDateFormatter = DateFormatter()
                fullDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                fullDateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                if let date = fullDateFormatter.date(from: "\(apiMatch.date) \(apiMatch.time ?? "12:00:00")") {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    timeString = timeFormatter.string(from: date)
                } else {
                    timeString = "TBD"
                }
            }
            
            var result: MatchOutcome?
            var goals: Int?
            var actualResult: String?
            var matchStatus = apiMatch.status.lowercased()
            
            if matchStatus.contains("finished") || matchStatus.contains("ft") {
                if let score = apiMatch.score {
                    let homeGoals = score.fulltime?.home ?? score.home ?? 0
                    let awayGoals = score.fulltime?.away ?? score.away ?? 0
                    goals = homeGoals + awayGoals
                    actualResult = "\(homeGoals)-\(awayGoals)"
                    
                    if homeGoals > awayGoals {
                        result = .home
                    } else if awayGoals > homeGoals {
                        result = .away
                    } else {
                        result = .draw
                    }
                }
            }
            
            let odds = createRealOddsFromSportDB(apiMatch.odds)
            
            let match = Match(
                id: UUID(),
                home: apiMatch.homeTeam.name,
                away: apiMatch.awayTeam.name,
                time: timeString,
                odds: odds,
                result: result,
                goals: goals,
                competition: apiMatch.competition.name,
                status: apiMatch.status,
                isReal: true,
                homeLogo: apiMatch.homeTeam.logo,
                awayLogo: apiMatch.awayTeam.logo,
                actualResult: actualResult
            )
            
            allConvertedMatches.append(match)
        }
        
        let todayKey = keyForDate(Date())
        if dailyMatches[todayKey] == nil {
            dailyMatches[todayKey] = []
        }
        dailyMatches[todayKey]?.append(contentsOf: allConvertedMatches)
        
        saveMatches()
        lastUpdateTime = Date()
    }
    
    private func createRealOddsFromSportDB(_ sportDBOdds: SportDBOdds?) -> Odds {
        if let realOdds = sportDBOdds {
            return Odds(
                home: realOdds.homeWin ?? 2.00,
                draw: realOdds.draw ?? 3.40,
                away: realOdds.awayWin ?? 3.60,
                homeDraw: 1.0 / ((1.0/(realOdds.homeWin ?? 2.00)) + (1.0/(realOdds.draw ?? 3.40))),
                homeAway: 1.0 / ((1.0/(realOdds.homeWin ?? 2.00)) + (1.0/(realOdds.awayWin ?? 3.60))),
                drawAway: 1.0 / ((1.0/(realOdds.draw ?? 3.40)) + (1.0/(realOdds.awayWin ?? 3.60))),
                over05: realOdds.over05 ?? 1.12,
                under05: realOdds.under05 ?? 6.50,
                over15: realOdds.over15 ?? 1.45,
                under15: realOdds.under15 ?? 2.65,
                over25: realOdds.over25 ?? 1.95,
                under25: realOdds.under25 ?? 1.85,
                over35: realOdds.over35 ?? 2.80,
                under35: realOdds.under35 ?? 1.40,
                over45: realOdds.over45 ?? 4.50,
                under45: realOdds.under45 ?? 1.18
            )
        }
        
        return createRealisticOdds(home: 2.00, draw: 3.40, away: 3.60)
    }
    
    private func loadFallbackMatches() {
        let realisticMatches = generateRealisticMatches()
        let todayKey = keyForDate(Date())
        dailyMatches[todayKey] = realisticMatches
        saveMatches()
        lastUpdateTime = Date()
    }
    
    private func createRealisticOdds(home: Double, draw: Double, away: Double) -> Odds {
        let homeDraw = 1.0 / ((1.0/home) + (1.0/draw))
        let homeAway = 1.0 / ((1.0/home) + (1.0/away))
        let drawAway = 1.0 / ((1.0/draw) + (1.0/away))
        
        return Odds(
            home: home,
            draw: draw,
            away: away,
            homeDraw: homeDraw,
            homeAway: homeAway,
            drawAway: drawAway,
            over05: 1.12,
            under05: 6.50,
            over15: 1.45,
            under15: 2.65,
            over25: 1.95,
            under25: 1.85,
            over35: 2.80,
            under35: 1.40,
            over45: 4.50,
            under45: 1.18
        )
    }
    
    // MARK: - DATE HELPERS
    
    func dateForIndex(_ index: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: index - 1, to: Date())!
    }
    
    func keyForDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    
    func formattedDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    func formattedMonth(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }
    
    // MARK: - MATCH GENERATION FUNCTIONS
    
    func generateTodayIfNeeded() {
        let todayKey = keyForDate(Date())
        
        if dailyMatches[todayKey] == nil {
            dailyMatches[todayKey] = generateSimulatedMatches()
            saveMatches()
        }
    }
    
    func generateSimulatedMatches() -> [Match] {
        generateRealisticMatches()
    }
    
    private func generateRealisticMatches() -> [Match] {
        let competitions = [
            ("Premier League", ["Arsenal", "Chelsea", "Liverpool", "Man City", "Man United", "Tottenham"]),
            ("Serie A", ["Milan", "Inter", "Juventus", "Napoli", "Roma", "Lazio"]),
            ("La Liga", ["Barcelona", "Real Madrid", "Atletico", "Sevilla", "Valencia", "Villarreal"]),
            ("Bundesliga", ["Bayern", "Dortmund", "Leipzig", "Leverkusen", "Frankfurt", "Wolfsburg"]),
            ("Ligue 1", ["PSG", "Marseille", "Lyon", "Monaco", "Lille", "Nice"])
        ]
        
        var matches: [Match] = []
        
        for (competition, teams) in competitions {
            for _ in 0..<3 {
                let home = teams.randomElement()!
                var away = teams.randomElement()!
                while away == home { away = teams.randomElement()! }
                
                let hour = Int.random(in: 15...21)
                let minute = ["00", "15", "30", "45"].randomElement()!
                let time = "\(hour):\(minute)"
                
                let (homeOdd, drawOdd, awayOdd) = generateRealisticOdds(home: home, away: away)
                let odds = createRealisticOdds(home: homeOdd, draw: drawOdd, away: awayOdd)
                
                let (result, goals) = generateRealisticResult(homeOdd: homeOdd, drawOdd: drawOdd, awayOdd: awayOdd)
                
                let match = Match(
                    id: UUID(),
                    home: home,
                    away: away,
                    time: time,
                    odds: odds,
                    result: result,
                    goals: goals,
                    competition: competition,
                    status: "FINISHED",
                    isReal: false,
                    homeLogo: nil,
                    awayLogo: nil,
                    actualResult: result == .home ? "2-1" : result == .away ? "0-2" : "1-1"
                )
                
                matches.append(match)
            }
        }
        
        return matches.shuffled()
    }
    
    private func generateRealisticOdds(home: String, away: String) -> (Double, Double, Double) {
        let diff = Double(home.hash % 100 - away.hash % 100) / 100.0
        
        if diff > 0.3 {
            return (1.45, 4.50, 7.00)
        } else if diff > 0.1 {
            return (1.85, 3.60, 4.20)
        } else if diff > -0.1 {
            return (2.40, 3.30, 2.90)
        } else if diff > -0.3 {
            return (3.10, 3.40, 2.25)
        } else {
            return (5.50, 4.00, 1.55)
        }
    }
    
    private func generateRealisticResult(homeOdd: Double, drawOdd: Double, awayOdd: Double) -> (MatchOutcome?, Int?) {
        let homeProb = 1 / homeOdd
        let drawProb = 1 / drawOdd
        let awayProb = 1 / awayOdd
        let totalProb = homeProb + drawProb + awayProb
        
        let normHomeProb = homeProb / totalProb
        let normDrawProb = drawProb / totalProb
        
        let random = Double.random(in: 0...1)
        
        if random < normHomeProb {
            let goals = Int.random(in: 1...4)
            let awayGoals = Int.random(in: 0...goals-1)
            return (.home, goals + awayGoals)
        } else if random < normHomeProb + normDrawProb {
            let goals = Int.random(in: 0...3)
            return (.draw, goals * 2)
        } else {
            let goals = Int.random(in: 1...4)
            let homeGoals = Int.random(in: 0...goals-1)
            return (.away, goals + homeGoals)
        }
    }
    
    func matchesForSelectedDay() -> [String: [Match]] {
        let date = dateForIndex(selectedDayIndex)
        let key = keyForDate(date)
        
        if let existing = dailyMatches[key] {
            let grouped = Dictionary(grouping: existing) { $0.time }
            return grouped
        }
        
        let newMatches = generateSimulatedMatches()
        dailyMatches[key] = newMatches
        saveMatches()
        let grouped = Dictionary(grouping: newMatches) { $0.time }
        return grouped
    }
    
    // MARK: - SAVE / LOAD
    
    func saveMatches() {
        if let data = try? JSONEncoder().encode(dailyMatches) {
            UserDefaults.standard.set(data, forKey: matchesKey)
        }
    }
    
    func loadMatches() -> [String: [Match]] {
        guard let data = UserDefaults.standard.data(forKey: matchesKey),
              let decoded = try? JSONDecoder().decode([String: [Match]].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    // MARK: - BETTING
    
    var totalOdd: Double { currentPicks.map { $0.odd }.reduce(1, *) }
    
    func addPick(match: Match, outcome: MatchOutcome, odd: Double) {
        let selectedOutcomeSection = getSectionForOutcome(outcome)
        
        currentPicks.removeAll { pick in
            pick.match.id == match.id && getSectionForOutcome(pick.outcome) == selectedOutcomeSection
        }
        
        currentPicks.append(BetPick(id: UUID(), match: match, outcome: outcome, odd: odd))
    }
    
    private func getSectionForOutcome(_ outcome: MatchOutcome) -> String {
        switch outcome {
        case .home, .draw, .away:
            return "1X2"
        case .homeDraw, .homeAway, .drawAway:
            return "DoppiaChance"
        case .over05, .under05, .over15, .under15, .over25, .under25, .over35, .under35, .over45, .under45:
            return "OverUnder"
        }
    }
    
    func removePick(_ pick: BetPick) {
        currentPicks.removeAll { $0.id == pick.id }
    }
    
    func confirmSlip(stake: Double) {
        let slip = BetSlip(
            id: UUID(),
            picks: currentPicks,
            stake: stake,
            totalOdd: totalOdd,
            potentialWin: stake * totalOdd,
            date: Date(),
            isWon: nil,
            isEvaluated: false
        )
        balance -= stake
        currentPicks.removeAll()
        slips.insert(slip, at: 0)
        saveSlips()
    }
    
    private func saveSlips() {
        if let data = try? JSONEncoder().encode(slips) {
            UserDefaults.standard.set(data, forKey: slipsKey)
        }
    }
    
    private func loadSlips() -> [BetSlip] {
        guard let data = UserDefaults.standard.data(forKey: slipsKey),
              let decoded = try? JSONDecoder().decode([BetSlip].self, from: data) else { return [] }
        return decoded
    }
    
    // MARK: - VALUTAZIONE SCHEDINE
    
    func evaluateSlip(_ slip: BetSlip) -> BetSlip {
        var updatedSlip = slip
        
        if slip.isEvaluated { return slip }
        
        let allCorrect = slip.picks.allSatisfy { pick in
            switch pick.outcome {
            case .home, .draw, .away:
                return pick.match.result == pick.outcome
            case .homeDraw:
                return pick.match.result == .home || pick.match.result == .draw
            case .homeAway:
                return pick.match.result == .home || pick.match.result == .away
            case .drawAway:
                return pick.match.result == .draw || pick.match.result == .away
            case .over05:
                return (pick.match.goals ?? 0) > 0
            case .under05:
                return (pick.match.goals ?? 0) == 0
            case .over15:
                return (pick.match.goals ?? 0) > 1
            case .under15:
                return (pick.match.goals ?? 0) <= 1
            case .over25:
                return (pick.match.goals ?? 0) > 2
            case .under25:
                return (pick.match.goals ?? 0) <= 2
            case .over35:
                return (pick.match.goals ?? 0) > 3
            case .under35:
                return (pick.match.goals ?? 0) <= 3
            case .over45:
                return (pick.match.goals ?? 0) > 4
            case .under45:
                return (pick.match.goals ?? 0) <= 4
            }
        }
        
        updatedSlip.isWon = allCorrect
        updatedSlip.isEvaluated = true
        
        if allCorrect {
            balance += slip.potentialWin
        }
        
        return updatedSlip
    }
    
    func evaluateAllSlips() {
        slips = slips.map { evaluateSlip($0) }
        saveSlips()
    }
    
    // MARK: - STATISTICHE
    
    var totalBetsCount: Int {
        slips.count
    }
    
    var totalWins: Int {
        slips.filter { $0.isWon == true }.count
    }
    
    var totalLosses: Int {
        slips.filter { $0.isWon == false }.count
    }
    
    // MARK: - FUNZIONI PROFILO
    
    func resetAccount() {
        balance = 1000
        slips.removeAll()
        currentPicks.removeAll()
        saveSlips()
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
    }
    
    func togglePrivacy() {
        privacyEnabled.toggle()
    }
}

// MARK: - MAIN VIEW

struct ContentView: View {
    
    @StateObject private var vm = BettingViewModel()
    @Namespace private var animationNamespace
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    headerView
                    
                    if vm.selectedTab == 0 {
                        calendarBarView
                        
                        if vm.isLoading {
                            loadingView
                        } else if let error = vm.apiError {
                            errorView(error: error)
                        } else {
                            matchListView
                        }
                    } else if vm.selectedTab == 1 {
                        GamesView()
                    } else if vm.selectedTab == 2 {
                        placedBetsView
                    } else {
                        ProfileView()
                            .environmentObject(vm)
                    }
                    
                    bottomBarView
                }
                
                floatingButtonView
            }
            .sheet(isPresented: $vm.showSheet) {
                BetSheet(
                    picks: $vm.currentPicks,
                    balance: $vm.balance,
                    totalOdd: vm.totalOdd
                ) { stake in vm.confirmSlip(stake: stake) }
            }
            .sheet(item: $vm.showSlipDetail) { SlipDetailView(slip: $0) }
        }
    }
    
    // MARK: - HEADER
    
    private var headerView: some View {
        HStack {
            Text(vm.selectedTab == 0 ? "Calendario" :
                    vm.selectedTab == 1 ? "Giochi" :
                    vm.selectedTab == 2 ? "Piazzate" : "Profilo")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("€\(vm.balance, specifier: "%.2f")")
                    .foregroundColor(.accentCyan)
                    .bold()
                
                if vm.selectedTab == 0 {
                    Button {
                        vm.toggleRealMatches()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: vm.useRealMatches ? "antenna.radiowaves.left.and.right" : "gamecontroller.fill")
                                .font(.caption)
                            
                            Text(vm.useRealMatches ? "SPORTDB.LIVE" : "SIMULATE")
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(vm.useRealMatches ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(vm.useRealMatches ? Color.green : Color.gray, lineWidth: 1)
                                )
                        )
                        .foregroundColor(vm.useRealMatches ? .green : .gray)
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - LOADING VIEW
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentCyan)
            
            Text("Caricando partite da SportDB.dev...")
                .foregroundColor(.white)
            
            Text("API Key: \(vm.hasAPIKey ? "✅ Configurata" : "❌ Mancante")")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - ERROR VIEW
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("SportDB.dev API")
                .font(.title2)
                .foregroundColor(.white)
            
            Text(error)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Riprova") {
                if vm.useRealMatches {
                    vm.fetchRealMatchesFromSportDB()
                } else {
                    vm.generateTodayIfNeeded()
                }
            }
            .padding()
            .background(Color.accentCyan)
            .foregroundColor(.black)
            .cornerRadius(12)
            
            Button("Usa partite simulate") {
                vm.useRealMatches = false
                vm.generateTodayIfNeeded()
            }
            .padding()
            .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: CALENDAR BAR
    
    private var calendarBarView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    let date = vm.dateForIndex(index)
                    
                    VStack(spacing: 4) {
                        Text(vm.formattedDay(date))
                            .font(.title2.bold())
                        Text(vm.formattedMonth(date))
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 90, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(vm.selectedDayIndex == index ? Color.accentCyan : Color.white.opacity(0.2), lineWidth: 3)
                    )
                    .onTapGesture { vm.selectedDayIndex = index }
                    .animation(.easeInOut, value: vm.selectedDayIndex)
                }
            }
            .padding(.horizontal)
            
            if vm.useRealMatches {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("SPORTDB.DEV • API LIVE")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if let lastUpdate = vm.lastUpdateTime {
                        Text("•")
                            .foregroundColor(.gray)
                        Text("Agg: \(lastUpdate, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text("PARTITE SIMULATE • DEMO")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: MATCH LIST
    
    private var matchListView: some View {
        let groupedMatches = vm.matchesForSelectedDay()
        let isYesterday = vm.selectedDayIndex == 0
        
        return ScrollView {
            VStack(spacing: 16) {
                if groupedMatches.isEmpty {
                    emptyMatchesView
                } else {
                    ForEach(groupedMatches.keys.sorted(), id: \.self) { time in
                        VStack(spacing: 10) {
                            HStack {
                                Text(time)
                                    .font(.headline)
                                    .foregroundColor(.accentCyan)
                                Spacer()
                                
                                if vm.useRealMatches {
                                    Image(systemName: "livephoto")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            ForEach(groupedMatches[time]!) { match in
                                matchCardView(match: match, disabled: isYesterday)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .id(vm.selectedDayIndex)
        .transition(.opacity)
        .refreshable {
            if vm.useRealMatches {
                vm.fetchRealMatchesFromSportDB()
            }
        }
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 50)
            
            Image(systemName: vm.useRealMatches ? "wifi.slash" : "soccerball")
                .font(.system(size: 60))
                .foregroundColor(.accentCyan)
            
            Text(vm.useRealMatches ? "Nessuna partita disponibile" : "Partite simulate")
                .font(.title2)
                .foregroundColor(.white)
            
            Text(vm.useRealMatches ? 
                 "SportDB.dev non ha partite per oggi o API limit raggiunto" :
                 "Attiva le partite reali per dati autentici")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(vm.useRealMatches ? "Ricarica" : "Attiva partite reali") {
                if vm.useRealMatches {
                    vm.fetchRealMatchesFromSportDB()
                } else {
                    vm.useRealMatches = true
                }
            }
            .padding()
            .background(Color.accentCyan)
            .foregroundColor(.black)
            .cornerRadius(12)
            
            Spacer()
        }
    }
    
    private func matchCardView(match: Match, disabled: Bool) -> some View {
        Button(action: {
            // Navigation gestito altrove
        }) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            if match.isReal {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Text(match.home)
                                .font(.headline)
                                .foregroundColor(disabled ? .gray : .white)
                                .lineLimit(1)
                        }
                        
                        Text(match.competition)
                            .font(.caption2)
                            .foregroundColor(.accentCyan)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(match.away)
                                .font(.headline)
                                .foregroundColor(disabled ? .gray : .white)
                                .lineLimit(1)
                            
                            if match.isReal {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        if let actualResult = match.actualResult {
                            Text(actualResult)
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text(match.status)
                                .font(.caption2)
                                .foregroundColor(match.status == "FINISHED" ? .green : .orange)
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(match.odds.home, specifier: "%.2f")")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(match.isReal ? .green : .white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text("X")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(match.odds.draw, specifier: "%.2f")")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(match.isReal ? .green : .white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text("2")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(match.odds.away, specifier: "%.2f")")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(match.isReal ? .green : .white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 10)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(disabled ? Color.gray.opacity(0.1) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                disabled ? Color.gray.opacity(0.2) : 
                                (match.isReal ? Color.green.opacity(0.4) : Color.white.opacity(0.1)),
                                lineWidth: match.isReal ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: PLACED BETS
    
    private var placedBetsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                if vm.slips.isEmpty {
                    Text("Nessuna scommessa piazzata")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(vm.slips) { slip in
                        Button { vm.showSlipDetail = slip } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quota \(slip.totalOdd, specifier: "%.2f")")
                                    .foregroundColor(.accentCyan)
                                Text("Puntata €\(slip.stake, specifier: "%.2f")")
                                    .foregroundColor(.white)
                                Text("Vincita potenziale €\(slip.potentialWin, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                if let won = slip.isWon {
                                    Text(won ? "ESITO: VINTA" : "ESITO: PERSA")
                                        .foregroundColor(won ? .green : .red)
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear { vm.evaluateAllSlips() }
    }
    
    // MARK: - FLOATING BUTTON
    
    private var floatingButtonView: some View {
        Group {
            if !vm.currentPicks.isEmpty && vm.selectedTab != 3 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack(alignment: .topTrailing) {
                            Button { vm.showSheet = true } label: {
                                Image(systemName: "rectangle.stack.fill")
                                    .foregroundColor(.black)
                                    .padding(16)
                                    .background(Color.accentCyan)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                            }
                            
                            Text("\(vm.currentPicks.count)")
                                .font(.caption2.bold())
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                                .offset(x: 8, y: -8)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - BOTTOM BAR
    
    private var bottomBarView: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 70)
                .cornerRadius(26)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.25), radius: 10, y: -2)
            
            HStack(spacing: 50) {
                ForEach(0..<4) { index in
                    bottomItemView(index: index)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private func bottomItemView(index: Int) -> some View {
        let icon: String
        switch index {
        case 0: icon = "calendar"
        case 1: icon = "dice.fill"
        case 2: icon = "list.bullet"
        case 3: icon = "person.crop.circle"
        default: icon = "circle"
        }
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                vm.selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if vm.selectedTab == index {
                        Circle()
                            .fill(Color.accentCyan.opacity(0.25))
                            .frame(width: 44, height: 44)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(vm.selectedTab == index ? .accentCyan : .white.opacity(0.7))
                }
                
                if vm.selectedTab == index {
                    Capsule()
                        .fill(Color.accentCyan)
                        .frame(width: 22, height: 4)
                        .matchedGeometryEffect(id: "tab", in: animationNamespace)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 22, height: 4)
                }
            }
        }
    }
}

