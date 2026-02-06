//
//  ContentView.swift
//  SportPredix
//

import SwiftUI
import AuthenticationServices

// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

// MARK: - VIEW MODEL

final class BettingViewModel: ObservableObject {
    
    @Published var selectedTab = 0
    @Published var selectedDayIndex = 1
    @Published var selectedSport: String {
        didSet {
            UserDefaults.standard.set(selectedSport, forKey: "selectedSport")
            reloadMatchesForAllDays()
        }
    }
    
    @Published var showSportPicker = false
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
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    // ⭐⭐⭐ NUOVO: Proprietà per Apple Sign In
    var isSignedInWithApple: Bool {
        UserDefaults.standard.string(forKey: "appleUserID") != nil
    }
    
    private let slipsKey = "savedSlips"
    private let matchesKey = "savedMatches"
    private let lastFetchKey = "lastBetstackFetch"
    
    init() {
        let savedBalance = UserDefaults.standard.double(forKey: "balance")
        self.balance = savedBalance == 0 ? 1000 : savedBalance
        
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.privacyEnabled = UserDefaults.standard.object(forKey: "privacyEnabled") as? Bool ?? false
        
        self.selectedSport = UserDefaults.standard.string(forKey: "selectedSport") ?? "Calcio"
        
        self.slips = loadSlips()
        self.dailyMatches = loadMatches()
        
        if let savedDate = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            self.lastUpdateTime = savedDate
        }
        
        loadMatchesForAllDays()
        
        // ⭐⭐⭐ AGGIUNGI: Ascolta le notifiche per Sign In/Sign Out
        setupAuthNotifications()
    }
    
    // ⭐⭐⭐ NUOVO: Configura notifiche per autenticazione
    private func setupAuthNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleSignInCompleted"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 ViewModel ricevuta notifica AppleSignInCompleted")
            self?.objectWillChange.send()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleSignOutCompleted"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 ViewModel ricevuta notifica AppleSignOutCompleted")
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // ⭐⭐⭐ NUOVO: Verifica stato Apple Sign In
    func checkAppleAuthOnLaunch() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserID") else {
            print("ℹ️ Nessun Apple User ID trovato")
            return
        }
        
        print("🔍 Verificando stato Apple ID per: \(userID)")
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { state, error in
            if let error = error {
                print("❌ Errore verifica Apple ID: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: "appleUserID")
                    self.objectWillChange.send()
                }
                return
            }
            
            switch state {
            case .authorized:
                print("✅ Apple ID autorizzato")
            case .revoked:
                print("❌ Apple ID revocato")
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: "appleUserID")
                    self.objectWillChange.send()
                }
            case .notFound:
                print("❌ Apple ID non trovato")
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: "appleUserID")
                    self.objectWillChange.send()
                }
            case .transferred:
                print("ℹ️ Apple ID trasferito")
            @unknown default:
                print("❓ Stato Apple ID sconosciuto")
            }
        }
    }
    
    private func loadMatchesForAllDays() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let dates = [yesterday, today, tomorrow]
        let dateKeys = dates.map { keyForDate($0) }
        
        for dateKey in dateKeys {
            if dailyMatches[dateKey] == nil {
                generateMatchesForDate(key: dateKey)
            }
        }
    }
    
    private func reloadMatchesForAllDays() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let dates = [yesterday, today, tomorrow]
        let dateKeys = dates.map { keyForDate($0) }
        
        for dateKey in dateKeys {
            generateMatchesForDate(key: dateKey)
        }
        
        saveMatches()
        objectWillChange.send()
    }
    
    private func generateMatchesForDate(key: String) {
        if selectedSport == "Tennis" {
            dailyMatches[key] = generateTennisMatches()
        } else {
            if key == keyForDate(Date()) {
                checkAndFetchMatchesForToday()
            } else {
                dailyMatches[key] = generateFootballMatches()
            }
        }
    }
    
    func checkAndFetchMatchesForToday() {
        guard selectedSport == "Calcio" else { return }
        
        let todayKey = keyForDate(Date())
        
        let shouldFetch = dailyMatches[todayKey] == nil ||
                         lastUpdateTime == nil ||
                         Date().timeIntervalSince(lastUpdateTime!) > 3600
        
        if shouldFetch {
            fetchMatchesFromBetstack()
        } else if dailyMatches[todayKey] == nil {
            dailyMatches[todayKey] = generateFootballMatches()
            saveMatches()
        }
    }
    
    func fetchMatchesFromBetstack() {
        guard !isLoading, selectedSport == "Calcio" else { return }
        
        isLoading = true
        
        OddsService.shared.fetchSerieAOdths { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let matches):
                    print("✅ Betstack matches fetched successfully: \(matches.count) matches")
                    
                    let todayKey = self?.keyForDate(Date()) ?? ""
                    self?.dailyMatches[todayKey] = matches
                    self?.lastUpdateTime = Date()
                    
                    self?.saveMatches()
                    UserDefaults.standard.set(self?.lastUpdateTime, forKey: self?.lastFetchKey ?? "lastBetstackFetch")
                    
                    self?.objectWillChange.send()
                    
                case .failure(let error):
                    print("❌ Betstack fetch failed: \(error.localizedDescription)")
                    let todayKey = self?.keyForDate(Date()) ?? ""
                    self?.dailyMatches[todayKey] = self?.generateFootballMatches()
                    self?.saveMatches()
                    self?.objectWillChange.send()
                }
            }
        }
    }
    
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
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "MMM"
        return f.string(from: date).capitalized
    }
    
    func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func isTomorrow(_ date: Date) -> Bool {
        Calendar.current.isDateInTomorrow(date)
    }
    
    func generateFootballMatches() -> [Match] {
        let competitions = [
            ("Serie A", ["Milan", "Inter", "Juventus", "Napoli", "Roma", "Lazio", "Atalanta", "Fiorentina"]),
            ("Premier League", ["Arsenal", "Chelsea", "Liverpool", "Man City", "Man United", "Tottenham"]),
            ("La Liga", ["Barcelona", "Real Madrid", "Atletico", "Sevilla", "Valencia", "Villarreal"]),
            ("Bundesliga", ["Bayern", "Dortmund", "Leipzig", "Leverkusen", "Frankfurt", "Wolfsburg"]),
            ("Ligue 1", ["PSG", "Marseille", "Lyon", "Monaco", "Lille", "Nice"])
        ]
        
        var matches: [Match] = []
        
        for (competition, teams) in competitions {
            for _ in 0..<2 {
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
                    actualResult: result == .home ? "2-1" : result == .away ? "0-2" : "1-1"
                )
                
                matches.append(match)
            }
        }
        
        return matches.shuffled()
    }
    
    func generateTennisMatches() -> [Match] {
        let tournaments = [
            ("ATP Australian Open", ["Djokovic", "Alcaraz", "Sinner", "Medvedev", "Zverev", "Rublev"]),
            ("ATP French Open", ["Nadal", "Djokovic", "Alcaraz", "Tsitsipas", "Ruud", "Rune"]),
            ("Wimbledon", ["Djokovic", "Alcaraz", "Murray", "Berrettini", "Kyrgios", "Federer"]),
            ("US Open", ["Djokovic", "Alcaraz", "Medvedev", "Sinner", "Fritz", "Tiafoe"]),
            ("ATP Masters 1000", ["Djokovic", "Alcaraz", "Sinner", "Medvedev", "Zverev", "Tsitsipas"])
        ]
        
        var matches: [Match] = []
        
        for (tournament, players) in tournaments {
            for _ in 0..<3 {
                let player1 = players.randomElement()!
                var player2 = players.randomElement()!
                while player2 == player1 { player2 = players.randomElement()! }
                
                let hour = Int.random(in: 10...22)
                let minute = ["00", "15", "30", "45"].randomElement()!
                let time = "\(hour):\(minute)"
                
                let (homeOdd, _, awayOdd) = generateRealisticTennisOdds(player1: player1, player2: player2)
                let odds = createTennisOdds(home: homeOdd, away: awayOdd)
                
                let (result, sets) = generateTennisResult(homeOdd: homeOdd, awayOdd: awayOdd)
                
                let match = Match(
                    id: UUID(),
                    home: player1,
                    away: player2,
                    time: time,
                    odds: odds,
                    result: result,
                    goals: sets,
                    competition: tournament,
                    status: "FINISHED",
                    actualResult: result == .home ? "3-1" : result == .away ? "2-3" : "N/A"
                )
                
                matches.append(match)
            }
        }
        
        return matches.shuffled()
    }
    
    private func generateRealisticTennisOdds(player1: String, player2: String) -> (Double, Double, Double) {
        let diff = Double(player1.hash % 100 - player2.hash % 100) / 100.0
        
        if diff > 0.3 {
            return (1.30, 0.0, 3.50)
        } else if diff > 0.1 {
            return (1.60, 0.0, 2.40)
        } else if diff > -0.1 {
            return (1.90, 0.0, 1.90)
        } else if diff > -0.3 {
            return (2.40, 0.0, 1.60)
        } else {
            return (3.50, 0.0, 1.30)
        }
    }
    
    private func createTennisOdds(home: Double, away: Double) -> Odds {
        return Odds(
            home: home,
            draw: 1.0,
            away: away,
            homeDraw: 1.0 / ((1.0/home) + (1.0/1.0)),
            homeAway: 1.0 / ((1.0/home) + (1.0/away)),
            drawAway: 1.0 / ((1.0/1.0) + (1.0/away)),
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
    
    private func generateTennisResult(homeOdd: Double, awayOdd: Double) -> (MatchOutcome?, Int?) {
        let homeProb = 1 / homeOdd
        let awayProb = 1 / awayOdd
        let totalProb = homeProb + awayProb
        
        let normHomeProb = homeProb / totalProb
        
        let random = Double.random(in: 0...1)
        
        if random < normHomeProb {
            let sets = Int.random(in: 3...5)
            return (.home, sets)
        } else {
            let sets = Int.random(in: 3...5)
            return (.away, sets)
        }
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
        
        if dailyMatches[key] == nil {
            generateMatchesForDate(key: key)
            saveMatches()
        }
        
        if let existing = dailyMatches[key] {
            let grouped = Dictionary(grouping: existing) { $0.time }
            return grouped
        }
        
        return [:]
    }
    
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
    
    var totalOdd: Double { currentPicks.map { $0.odd }.reduce(1, *) }
    
    func addPick(match: Match, outcome: MatchOutcome, odd: Double) {
        let matchDate = Calendar.current.date(byAdding: .day, value: -(selectedDayIndex - 1), to: Date())!
        if isYesterday(matchDate) {
            return
        }
        
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
        guard stake > 0, stake <= balance else { return }
        
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
    
    var totalBetsCount: Int {
        slips.count
    }
    
    var totalWins: Int {
        slips.filter { $0.isWon == true }.count
    }
    
    var totalLosses: Int {
        slips.filter { $0.isWon == false }.count
    }
    
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
    
    func hideSportPicker() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            showSportPicker = false
        }
    }
}

// MARK: - MAIN VIEW

struct ContentView: View {
    
    @StateObject private var vm = BettingViewModel()
    @Namespace private var animationNamespace
    
    // ⭐⭐⭐ AGGIUNGI: Stato per forzare il refresh
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // ⭐⭐⭐ MODIFICATO: Usa refreshID per forzare aggiornamento
                if vm.isSignedInWithApple {
                    // Utente autenticato - mostra app normale
                    VStack(spacing: 0) {
                        // HEADER MODIFICATO: Mostra solo per Sport (tab 0)
                        if vm.selectedTab == 0 {
                            headerView
                            calendarBarView
                            
                            if vm.isLoading {
                                loadingView
                            } else {
                                matchListView
                            }
                        } else if vm.selectedTab == 1 {
                            // ⭐⭐⭐ MODIFICATO: Casino - schermata speciale senza header generico
                            CasinoMainView()
                                .environmentObject(vm)
                        } else if vm.selectedTab == 2 {
                            placedBetsView
                        } else if vm.selectedTab == 3 {
                            ProfileView()
                                .environmentObject(vm)
                        }
                        
                        bottomBarView
                    }
                    .id(refreshID) // ⭐⭐⭐ Questo forza il refresh quando cambia
                } else {
                    // ⭐⭐⭐ NUOVO: Utente NON autenticato - mostra schermata Apple Sign In
                    AppleSignInRequiredView()
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
        .navigationBarHidden(true)
        .onAppear {
            vm.checkAppleAuthOnLaunch()
        }
        // ⭐⭐⭐ AGGIUNGI: Ascolta le notifiche di autenticazione
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppleSignInCompleted"))) { _ in
            print("🔄 ContentView: Ricevuta notifica AppleSignInCompleted")
            refreshID = UUID() // Forza refresh dell'interfaccia
            
            // Ricarica anche il view model
            vm.objectWillChange.send()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppleSignOutCompleted"))) { _ in
            print("🔄 ContentView: Ricevuta notifica AppleSignOutCompleted")
            refreshID = UUID() // Forza refresh dell'interfaccia
            
            // Ricarica anche il view model
            vm.objectWillChange.send()
        }
    }
    
    // MARK: - HEADER NUOVO STILE
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Logo/Titolo con freccia sport
                HStack(spacing: 4) {
                    Text("Sport")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    if vm.selectedTab == 0 {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(vm.showSportPicker ? 180 : 0))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    vm.showSportPicker.toggle()
                                }
                            }
                    }
                }
                
                Spacer()
                
                // Saldo utente
                Text("€\(vm.balance, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
                    .bold()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Linea sottile divisoria
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
        }
        .background(Color.black.opacity(0.95))
        .overlay(
            sportDropdownMenu
                .offset(y: 60),
            alignment: .top
        )
    }
    
    private var sportDropdownMenu: some View {
        Group {
            if vm.showSportPicker && vm.selectedTab == 0 {
                // Overlay scuro che blocca la vista sotto
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            vm.showSportPicker = false
                        }
                    }
                    .overlay(
                        // Menu dropdown
                        VStack(spacing: 0) {
                            VStack(spacing: 0) {
                                // Calcio
                                Button(action: {
                                    withAnimation {
                                        vm.selectedSport = "Calcio"
                                        vm.showSportPicker = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "soccerball")
                                            .font(.system(size: 16))
                                            .foregroundColor(vm.selectedSport == "Calcio" ? .accentCyan : .white)
                                            .frame(width: 30)
                                        
                                        Text("Calcio")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if vm.selectedSport == "Calcio" {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.accentCyan)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                }
                                .background(vm.selectedSport == "Calcio" ? Color.accentCyan.opacity(0.1) : Color.clear)
                                
                                // Divisore
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 8)
                                
                                // Tennis
                                Button(action: {
                                    withAnimation {
                                        vm.selectedSport = "Tennis"
                                        vm.showSportPicker = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "tennis.racket")
                                            .font(.system(size: 16))
                                            .foregroundColor(vm.selectedSport == "Tennis" ? .accentCyan : .white)
                                            .frame(width: 30)
                                        
                                        Text("Tennis")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if vm.selectedSport == "Tennis" {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.accentCyan)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                }
                                .background(vm.selectedSport == "Tennis" ? Color.accentCyan.opacity(0.1) : Color.clear)
                            }
                            .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.7), radius: 20, x: 0, y: 5)
                        }
                        .frame(maxWidth: 160)
                        .padding(.horizontal, 16)
                        .offset(x: -100, y: 8)
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.showSportPicker)
    }
    
    // MARK: - CALENDAR BAR
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
        }
        .padding(.vertical, 12)
    }
    
    // MARK: LOADING VIEW
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentCyan))
                .scaleEffect(1.5)
            
            Text("Caricamento partite...")
                .foregroundColor(.accentCyan)
                .font(.headline)
            
            Text("Sto recuperando le quote più recenti")
                .foregroundColor(.gray)
                .font(.caption)
            
            Spacer()
        }
    }
    
    // MARK: MATCH LIST
    private var matchListView: some View {
        let groupedMatches = vm.matchesForSelectedDay()
        let isYesterday = vm.selectedDayIndex == 0
        
        return ScrollView {
            VStack(spacing: 16) {
                if groupedMatches.isEmpty && !vm.isLoading {
                    emptyMatchesView
                } else {
                    ForEach(groupedMatches.keys.sorted(), id: \.self) { time in
                        VStack(spacing: 10) {
                            HStack {
                                Text(time)
                                    .font(.headline)
                                    .foregroundColor(.accentCyan)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            
                            ForEach(groupedMatches[time]!) { match in
                                NavigationLink(destination: MatchDetailView(match: match, vm: vm)) {
                                    matchCardView(match: match, disabled: isYesterday)
                                }
                                .disabled(isYesterday)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .id("\(vm.selectedDayIndex)-\(vm.selectedSport)")
        .transition(.opacity)
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 50)
            
            Image(systemName: vm.selectedSport == "Calcio" ? "soccerball" : "tennis.racket")
                .font(.system(size: 60))
                .foregroundColor(.accentCyan)
            
            Text("Nessuna partita disponibile")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Torna più tardi per vedere nuove partite")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func matchCardView(match: Match, disabled: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.home)
                        .font(.headline)
                        .foregroundColor(disabled ? .gray : .white)
                        .lineLimit(1)
                    
                    Text(match.competition)
                        .font(.caption2)
                        .foregroundColor(.accentCyan)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.away)
                        .font(.headline)
                        .foregroundColor(disabled ? .gray : .white)
                        .lineLimit(1)
                    
                    if let actualResult = match.actualResult {
                        Text(actualResult)
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text(match.status)
                            .font(.caption2)
                            .foregroundColor(match.status == "FINISHED" ? .green : 
                                           match.status == "LIVE" ? .red : .orange)
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
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                
                if vm.selectedSport == "Calcio" {
                    Divider()
                        .frame(height: 30)
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text("X")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(match.odds.draw, specifier: "%.2f")")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                    .frame(height: 30)
                    .background(Color.gray.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("2")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(match.odds.away, specifier: "%.2f")")
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.white)
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
                        .stroke(disabled ? Color.gray.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(disabled ? 0.6 : 1.0)
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
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
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
                if index != 0 {
                    vm.showSportPicker = false
                }
            }
        } label: {
            VStack(spacing: 4) {
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

// ⭐⭐⭐ NUOVO: Schermata Apple Sign In Required
struct AppleSignInRequiredView: View {
    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icona Apple con animazione
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentCyan.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "apple.logo")
                    .font(.system(size: 50))
                    .foregroundColor(.accentCyan)
            }
            
            VStack(spacing: 12) {
                Text("Benvenuto in SportPredix")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Accedi con il tuo Apple ID per iniziare a scommettere\nÈ l'unico metodo di accesso disponibile per garantire la massima sicurezza.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            // Benefici Apple Sign In
            VStack(alignment: .leading, spacing: 16) {
                benefitRow(
                    icon: "lock.shield.fill",
                    title: "Privacy Garantita",
                    description: "Apple non traccia la tua attività nelle scommesse"
                )
                
                benefitRow(
                    icon: "envelope.badge.fill",
                    title: "Email Protetta",
                    description: "La tua email personale rimane sempre privata"
                )
                
                benefitRow(
                    icon: "checkmark.seal.fill",
                    title: "Sicurezza Apple",
                    description: "Face ID / Touch ID integrati"
                )
                
                benefitRow(
                    icon: "person.badge.key.fill",
                    title: "Accesso Esclusivo",
                    description: "Solo utenti Apple possono utilizzare l'app"
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Bottone Sign In
            if isSigningIn {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.accentCyan)
                    
                    Text("Accesso in corso...")
                        .foregroundColor(.accentCyan)
                        .font(.caption)
                }
                .padding(.bottom, 40)
            } else {
                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        isSigningIn = true
                        
                        // Debug
                        print("📱 Apple Sign In iniziato...")
                    } onCompletion: { result in
                        handleSignInCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    
                    // ⭐⭐⭐ TEMPORANEO: Bottone debug per test senza Apple Sign In
                    Button(action: {
                        // Simula login per testing
                        print("🔧 Debug Login attivato")
                        let debugUserID = "debug_user_\(UUID().uuidString)"
                        UserDefaults.standard.set(debugUserID, forKey: "appleUserID")
                        UserDefaults.standard.set("Debug User", forKey: "userName")
                        UserDefaults.standard.synchronize()
                        
                        // Debug
                        print("✅ Debug UserID salvato: \(debugUserID)")
                        print("✅ Nome salvato: Debug User")
                        
                        // Forza il salvataggio
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("AppleSignInCompleted"),
                                object: nil
                            )
                        }
                    }) {
                        Text("Debug Login (testing)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                    
                    Text("Nessun altro metodo di accesso disponibile")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .padding()
        .alert("Errore Accesso", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            print("🔄 AppleSignInRequiredView caricato")
        }
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentCyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    private func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        DispatchQueue.main.async {
            isSigningIn = false
            
            switch result {
            case .success(let authorization):
                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    // Salva l'userID di Apple
                    let userID = credential.user
                    UserDefaults.standard.set(userID, forKey: "appleUserID")
                    
                    // Salva il nome se disponibile
                    if let fullName = credential.fullName {
                        let nameComponents = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                        
                        if !nameComponents.isEmpty {
                            let fullNameString = nameComponents.joined(separator: " ")
                            UserDefaults.standard.set(fullNameString, forKey: "userName")
                            print("✅ Nome Apple salvato: \(fullNameString)")
                        } else if let currentName = UserDefaults.standard.string(forKey: "userName") {
                            // Mantieni il nome esistente se non c'è nuovo nome
                            UserDefaults.standard.set(currentName, forKey: "userName")
                            print("✅ Mantenuto nome esistente: \(currentName)")
                        }
                    }
                    
                    // Forza il salvataggio immediato
                    UserDefaults.standard.synchronize()
                    
                    // Debug: verifica che l'ID sia salvato
                    print("✅ Apple Sign In completato - UserID salvato: \(userID)")
                    let isAuthenticated = UserDefaults.standard.string(forKey: "appleUserID") != nil
                    print("✅ Stato autenticazione: \(isAuthenticated ? "Autenticato" : "Non autenticato")")
                    
                    // Posta la notifica
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AppleSignInCompleted"),
                        object: nil,
                        userInfo: ["userID": userID]
                    )
                    
                    // Aggiungi un piccolo delay per assicurarsi che tutto sia salvato
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Forza un aggiornamento dell'interfaccia
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AppleSignInCompleted"),
                            object: nil
                        )
                    }
                } else {
                    print("❌ Credenziale Apple non valida")
                    errorMessage = "Credenziale di autenticazione non valida"
                    showError = true
                }
                
            case .failure(let error):
                print("❌ Errore Apple Sign In: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                
                // Controlla se l'utente ha annullato
                if let authError = error as? ASAuthorizationError {
                    switch authError.code {
                    case .canceled:
                        errorMessage = "Accesso annullato"
                        print("ℹ️ Utente ha annullato l'accesso")
                    case .failed:
                        errorMessage = "Accesso fallito"
                    case .invalidResponse:
                        errorMessage = "Risposta non valida"
                    case .notHandled:
                        errorMessage = "Richiesta non gestita"
                    case .unknown:
                        errorMessage = "Errore sconosciuto"
                    @unknown default:
                        errorMessage = "Errore sconosciuto"
                    }
                }
                
                showError = true
            }
        }
    }
}

// ⭐⭐⭐ NUOVO: Schermata Casino Main con header dedicato
struct CasinoMainView: View {
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        ZStack {
            // Sfondo che copre TUTTO
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header DEDICATO per Casino
                VStack(spacing: 0) {
                    HStack {
                        Text("Casino")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Saldo utente (versione compatta)
                        Text("€\(vm.balance, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.accentCyan)
                            .bold()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Linea sottile divisoria
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 0.5)
                }
                .background(Color.black.opacity(0.95))
                
                // Contenuto del Casino
                GamesContentView()
                    .environmentObject(vm)
            }
        }
    }
}

// ⭐⭐⭐ MODIFICATO: GamesContentView senza header proprio
struct GamesContentView: View {
    let games = [
        ("Gratta e Vinci", "sparkles", Color.accentCyan),
        ("Slot Machine", "slot.machine", Color.pink),
        ("Crazy Time", "clock.badge", Color.orange),
        ("Roulette", "circle.grid.cross", Color.green),
        ("Blackjack", "suit.club", Color.purple),
        ("Poker", "suit.spade", Color.yellow)
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Grid giochi
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(games, id: \.0) { game in
                        GameButton(
                            title: game.0,
                            icon: game.1,
                            color: game.2
                        )
                        .environmentObject(vm)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Info footer
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentCyan)
                            .font(.caption)
                        
                        Text("Gioco responsabile • Maggiorenni • Vietato ai minori")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Text("Le vincite sono virtuali")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.bottom, 30)
            }
            .padding(.bottom, 80) // Spazio per la bottom bar
        }
    }
}