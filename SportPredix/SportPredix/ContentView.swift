//
//  ContentView.swift
//  SportPredix
//

import SwiftUI
import Combine

// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

enum GemFormatting {
    static func amount(_ value: Double) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(2))
                .locale(Locale(identifier: "it_IT"))
        )
    }

    static func tagged(_ value: Double) -> String {
        "GEM \(amount(value))"
    }
}

struct GemIcon: View {
    var color: Color = .accentCyan
    var lineWidth: CGFloat = 2.0

    var body: some View {
        Image("GemIcon")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.22), radius: max(0.5, lineWidth * 0.2), x: 0, y: 0)
    }
}

struct GemAmountLabel: View {
    let amount: Double
    var color: Color = .accentCyan
    var font: Font = .subheadline
    var weight: Font.Weight = .semibold
    var iconSize: CGFloat = 14
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            GemIcon(color: color, lineWidth: max(1.5, iconSize * 0.16))
                .frame(width: iconSize, height: iconSize)

            Text(GemFormatting.amount(amount))
                .font(font.weight(weight))
                .foregroundColor(color)
                .monospacedDigit()
        }
    }
}

// MARK: - HEADER FLUTTUANTE

struct FloatingHeader: View {
    let title: String
    let balance: Double
    @Binding var showSportPicker: Bool
    var showsBalance: Bool = true
    var trailingSystemImage: String = "gearshape.fill"
    var trailingAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Titolo
                HStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    if title == "Sport" {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentCyan)
                            .rotationEffect(.degrees(showSportPicker ? 180 : 0))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    showSportPicker.toggle()
                                }
                            }
                    }
                }
                
                Spacer()
                
                if showsBalance {
                // Saldo con effetto vetro
                GemAmountLabel(
                    amount: balance,
                    color: .accentCyan,
                    font: .headline,
                    weight: .bold,
                    iconSize: 16
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    // Mini versione dell'effetto vetro
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                                .blur(radius: 0.5)
                        )
                )
                } else if let trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingSystemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentCyan)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Color.black.opacity(0.3)
                    .background(.ultraThinMaterial.opacity(0.7))
                    .edgesIgnoringSafeArea(.top)
            )
            
            // Linea sottile divisoria
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .accentCyan.opacity(0.3),
                            .blue.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .blur(radius: 0.5)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - VIEW MODEL (BettingViewModel)
// Questo Ã¨ un estratto del ViewModel, aggiorna con le modifiche necessarie

enum PromoCodeRedemptionResult {
    case emptyCode
    case authRequired
    case invalidCode
    case limitReached(maxUses: Int)
    case alreadyRedeemed
    case storeUnavailable
    case success(PromoCode)
}

struct PromoCode: Decodable {
    let code: String
    let bonus: Double
    let maxUses: Int
    let description: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case code
        case bonus
        case maxUses
        case max_uses
        case description
        case isActive
        case is_active
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        if let directBonus = try? container.decode(Double.self, forKey: .bonus) {
            bonus = directBonus
        } else if let intBonus = try? container.decode(Int.self, forKey: .bonus) {
            bonus = Double(intBonus)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .bonus, in: container, debugDescription: "bonus mancante o non valido")
        }
        
        if let directMaxUses = try? container.decode(Int.self, forKey: .maxUses) {
            maxUses = directMaxUses
        } else if let snakeMaxUses = try? container.decode(Int.self, forKey: .max_uses) {
            maxUses = snakeMaxUses
        } else if let doubleMaxUses = try? container.decode(Double.self, forKey: .maxUses) {
            maxUses = Int(doubleMaxUses)
        } else if let snakeDoubleMaxUses = try? container.decode(Double.self, forKey: .max_uses) {
            maxUses = Int(snakeDoubleMaxUses)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .maxUses, in: container, debugDescription: "maxUses mancante o non valido")
        }
        
        if let directIsActive = try? container.decode(Bool.self, forKey: .isActive) {
            isActive = directIsActive
        } else if let snakeIsActive = try? container.decode(Bool.self, forKey: .is_active) {
            isActive = snakeIsActive
        } else {
            isActive = true
        }
    }

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}

private struct PromoCodeCatalog: Decodable {
    let codes: [PromoCode]
}

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
        didSet {
            UserDefaults.standard.set(balance, forKey: "balance")
            syncBalanceToCloudIfPossible()
        }
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
    @Published private(set) var promoCodes: [PromoCode] = []
    @Published private(set) var remoteTotalBetsCount = 0
    @Published private(set) var remoteTotalWins = 0
    @Published private(set) var remoteTotalLosses = 0
    
    @Published var dailyMatches: [String: [Match]] = [:]
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    private let slipsKey = "savedSlips"
    private let matchesKey = "savedMatches"
    private let lastFetchKey = "lastBetstackFetch"
    private let lastBundleFetchDayKey = "lastMatchesBundleFetchDay"
    private let matchesSourceVersionKey = "matchesSourceVersion"
    private let matchesSourceVersion = 7
    // Sostituisci con la raw URL del JSON nella tua repository esterna.
    private let promoCodesURLString = "https://raw.githubusercontent.com/SportPredix/Code/refs/heads/main/code.json"
    private var cancellables = Set<AnyCancellable>()
    private var balanceSyncTask: DispatchWorkItem?
    private var betStatsSyncTask: DispatchWorkItem?
    private var isLoadingRemoteBalance = false
    private var isLoadingPromoCodes = false
    private var isFetchingMatchesBundle = false
    
    init() {
        let savedBalance = UserDefaults.standard.double(forKey: "balance")
        self.balance = savedBalance == 0 ? 1000 : savedBalance
        
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.privacyEnabled = UserDefaults.standard.object(forKey: "privacyEnabled") as? Bool ?? false
        
        self.selectedSport = UserDefaults.standard.string(forKey: "selectedSport") ?? "Calcio"
        
        self.slips = loadSlips()
        self.dailyMatches = loadMatches()
        migrateMatchesCacheIfNeeded()
        
        if let savedDate = UserDefaults.standard.object(forKey: lastFetchKey) as? Date {
            self.lastUpdateTime = savedDate
        }
        
        loadMatchesForAllDays()
        setupAuthObserver()
        fetchPromoCodesIfNeeded()
    }

    private func setupAuthObserver() {
        AuthManager.shared.$currentUserID
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userID in
                guard let self = self else { return }
                guard let userID = userID else {
                    self.remoteTotalBetsCount = 0
                    self.remoteTotalWins = 0
                    self.remoteTotalLosses = 0
                    return
                }
                self.loadBalanceFromCloud(userID: userID)
            }
            .store(in: &cancellables)
    }

    private func loadBalanceFromCloud(userID: String) {
        isLoadingRemoteBalance = true
        FirebaseManager.shared.loadUserProfile(userID: userID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    if let remoteBalance = data["balance"] as? Double {
                        self.balance = remoteBalance
                    } else if let remoteBalance = data["balance"] as? NSNumber {
                        self.balance = remoteBalance.doubleValue
                    } else {
                        self.syncBalanceToCloudIfPossible()
                    }

                    self.remoteTotalBetsCount = self.intValue(from: data["totalBetsCount"]) ?? 0
                    self.remoteTotalWins = self.intValue(from: data["totalWins"]) ?? 0
                    self.remoteTotalLosses = self.intValue(from: data["totalLosses"]) ?? 0
                case .failure:
                    break
                }
                
                self.isLoadingRemoteBalance = false
            }
        }
    }

    private func syncBalanceToCloudIfPossible() {
        guard !isLoadingRemoteBalance else { return }
        guard let userID = AuthManager.shared.currentUserID else { return }
        
        balanceSyncTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            FirebaseManager.shared.updateBalance(userID: userID, newBalance: self.balance) { _ in }
        }
        balanceSyncTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    private func syncBetStatsToCloudIfPossible() {
        guard let userID = AuthManager.shared.currentUserID else { return }

        let totalBets = totalBetsCount
        let wins = totalWins
        let losses = totalLosses

        // Keep profile counters in sync immediately while Firestore update is in flight.
        remoteTotalBetsCount = totalBets
        remoteTotalWins = wins
        remoteTotalLosses = losses

        betStatsSyncTask?.cancel()
        let task = DispatchWorkItem {
            FirebaseManager.shared.updateBetStats(
                userID: userID,
                totalBets: totalBets,
                totalWins: wins,
                totalLosses: losses
            ) { _ in }
        }
        betStatsSyncTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
    
    private func loadMatchesForAllDays() {
        let selectedDate = dateForIndex(selectedDayIndex)
        let selectedKey = keyForDate(selectedDate)
        generateMatchesForDate(key: selectedKey)
    }
    
    private func reloadMatchesForAllDays() {
        let selectedDate = dateForIndex(selectedDayIndex)
        let selectedKey = keyForDate(selectedDate)
        generateMatchesForDate(key: selectedKey)
        
        saveMatches()
        objectWillChange.send()
    }
    
    private func generateMatchesForDate(key: String) {
        if selectedSport == "Tennis" {
            dailyMatches[key] = generateTennisMatches()
        } else {
            if let date = dateFromKey(key) {
                checkAndFetchMatches(for: date)
            } else {
                dailyMatches[key] = []
            }
        }
    }
    
    func checkAndFetchMatchesForToday() {
        checkAndFetchMatches(for: Date())
    }

    private func checkAndFetchMatches(for date: Date) {
        guard selectedSport == "Calcio" else { return }

        let dateKey = keyForDate(date)
        let bundleKeys = bundleDateKeys(anchorDate: date)
        let missingBundleData = bundleKeys.contains { dailyMatches[$0] == nil }
        let hasOnlyEmptyBundleData = bundleKeys.allSatisfy { key in
            (dailyMatches[key] ?? []).isEmpty
        }
        let hasLikelySimulatedData = bundleKeys.contains { key in
            guard let matches = dailyMatches[key], let keyDate = dateFromKey(key) else { return false }
            return looksLikeSimulatedMatches(matches, for: keyDate)
        }
        let shouldFetch = !hasFetchedBundle(for: date) || missingBundleData || hasOnlyEmptyBundleData || hasLikelySimulatedData

        if shouldFetch {
            fetchMatchesFromBetstack(for: date)
        } else if dailyMatches[dateKey] == nil {
            dailyMatches[dateKey] = []
            saveMatches()
        }
    }
    
    func fetchMatchesFromBetstack() {
        fetchMatchesFromBetstack(for: Date())
    }

    func fetchMatchesFromBetstack(for anchorDate: Date) {
        guard selectedSport == "Calcio" else { return }
        guard !isFetchingMatchesBundle else { return }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: anchorDate) ?? anchorDate
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: anchorDate) ?? anchorDate

        isFetchingMatchesBundle = true
        isLoading = true

        OddsService.shared.fetchMatchesByDateRangeAcrossAllLeagues(
            from: yesterday,
            to: tomorrow
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingMatchesBundle = false
                self.isLoading = false

                switch result {
                case .success(let groupedMatches):
                    let keys = self.bundleDateKeys(anchorDate: anchorDate)
                    for key in keys where self.dailyMatches[key] == nil {
                        self.dailyMatches[key] = []
                    }
                    for (key, matches) in groupedMatches {
                        self.dailyMatches[key] = matches
                    }

                    self.lastUpdateTime = Date()
                    UserDefaults.standard.set(self.lastUpdateTime, forKey: self.lastFetchKey)
                    self.markBundleFetched(for: anchorDate)

                    self.saveMatches()
                    self.pruneUnavailableCurrentPicks()
                    self.evaluateAllSlips()
                    self.objectWillChange.send()

                case .failure(let error):
                    print("Matches bundle API failed: \(error.localizedDescription)")
                    for key in self.bundleDateKeys(anchorDate: anchorDate) where self.dailyMatches[key] == nil {
                        self.dailyMatches[key] = []
                    }
                    self.saveMatches()
                    self.objectWillChange.send()
                }
            }
        }
    }

    private func looksLikeSimulatedMatches(_ matches: [Match], for date: Date) -> Bool {
        guard !matches.isEmpty else { return false }

        let notYesterday = !Calendar.current.isDateInYesterday(date)
        let allFinishedWithResult = matches.allSatisfy { $0.status == "FINISHED" && $0.actualResult != nil }
        if notYesterday && allFinishedWithResult {
            return true
        }

        return false
    }

    private func bundleDateKeys(anchorDate: Date) -> [String] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: anchorDate) ?? anchorDate
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: anchorDate) ?? anchorDate
        return [yesterday, anchorDate, tomorrow].map { keyForDate($0) }
    }

    private func hasFetchedBundle(for anchorDate: Date) -> Bool {
        UserDefaults.standard.string(forKey: lastBundleFetchDayKey) == keyForDate(anchorDate)
    }

    private func markBundleFetched(for anchorDate: Date) {
        UserDefaults.standard.set(keyForDate(anchorDate), forKey: lastBundleFetchDayKey)
    }

    private func migrateMatchesCacheIfNeeded() {
        let storedVersion = UserDefaults.standard.integer(forKey: matchesSourceVersionKey)
        guard storedVersion < matchesSourceVersion else { return }

        dailyMatches = [:]
        lastUpdateTime = nil
        UserDefaults.standard.removeObject(forKey: matchesKey)
        UserDefaults.standard.removeObject(forKey: lastFetchKey)
        UserDefaults.standard.removeObject(forKey: lastBundleFetchDayKey)
        UserDefaults.standard.set(matchesSourceVersion, forKey: matchesSourceVersionKey)
    }

    private func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
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

    func formattedWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEE"
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

    func isPast(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date) < calendar.startOfDay(for: Date())
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
        let drawProb = 0.0  // â† AGGIUNGI QUESTA LINEA
        let totalProb = homeProb + awayProb
    
        let normHomeProb = homeProb / totalProb
        let normDrawProb = drawProb / totalProb
        let randomValue = Double.random(in: 0..<1)
        
        if randomValue < normHomeProb {
            return (.home, Int.random(in: 2...4))
        } else if randomValue < normHomeProb + normDrawProb {
            return (.draw, 1)
        } else {
            return (.away, Int.random(in: 2...4))
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

    func canBet(on match: Match) -> Bool {
        let latest = latestMatch(for: match)
        return isMatchBettable(latest)
    }

    func isOutcomeSelectable(match: Match, outcome: MatchOutcome) -> Bool {
        let latest = latestMatch(for: match)
        guard isMatchBettable(latest) else { return false }

        let picksForMatch = currentPicks.filter { $0.match.id == latest.id }
        let sameOutcomeAlreadySelected = picksForMatch.contains { $0.outcome == outcome }
        if sameOutcomeAlreadySelected {
            return true
        }

        if isDoubleChanceOutcome(outcome) {
            let hasOneXTwoSelection = picksForMatch.contains { isOneXTwoOutcome($0.outcome) }
            if hasOneXTwoSelection {
                return false
            }
        }

        return true
    }

    func addPick(match: Match, outcome: MatchOutcome, odd: Double) {
        let selectedDate = dateForIndex(selectedDayIndex)
        guard !isPast(selectedDate) else { return }

        pruneUnavailableCurrentPicks()
        let latestMatch = latestMatch(for: match)
        guard isMatchBettable(latestMatch) else { return }
        let picksForMatch = currentPicks.filter { $0.match.id == latestMatch.id }

        let sameOutcomeAlreadySelected = picksForMatch.contains { $0.outcome == outcome }
        if sameOutcomeAlreadySelected {
            currentPicks.removeAll { pick in
                pick.match.id == latestMatch.id && pick.outcome == outcome
            }
            return
        }

        if isDoubleChanceOutcome(outcome) {
            let hasOneXTwoSelection = picksForMatch.contains { isOneXTwoOutcome($0.outcome) }
            if hasOneXTwoSelection {
                return
            }
        }
        
        let selectedOutcomeSection = getSectionForOutcome(outcome)
        
        currentPicks.removeAll { pick in
            pick.match.id == latestMatch.id && getSectionForOutcome(pick.outcome) == selectedOutcomeSection
        }
        
        currentPicks.append(BetPick(id: UUID(), match: latestMatch, outcome: outcome, odd: odd))
    }

    private func isMatchBettable(_ match: Match) -> Bool {
        guard match.status.uppercased() == "SCHEDULED" else { return false }

        if let kickoff = kickoffDate(for: match) {
            return kickoff > Date()
        }

        return true
    }

    private func pruneUnavailableCurrentPicks() {
        guard !currentPicks.isEmpty else { return }
        let refreshedSelection = refreshedPicks(for: currentPicks)
        currentPicks = refreshedSelection.filter { isMatchBettable($0.match) }
    }

    private func kickoffDate(for match: Match) -> Date? {
        guard let dateKey = dailyMatches.first(where: { element in
            element.value.contains { $0.id == match.id }
        })?.key else {
            return nil
        }

        return kickoffDate(dateKey: dateKey, time: match.time)
    }

    private func kickoffDate(dateKey: String, time: String) -> Date? {
        let trimmedTime = time.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTime.contains(":"), trimmedTime.count == 5 else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: "\(dateKey) \(trimmedTime)")
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

    private func isOneXTwoOutcome(_ outcome: MatchOutcome) -> Bool {
        switch outcome {
        case .home, .draw, .away:
            return true
        default:
            return false
        }
    }

    private func isDoubleChanceOutcome(_ outcome: MatchOutcome) -> Bool {
        switch outcome {
        case .homeDraw, .homeAway, .drawAway:
            return true
        default:
            return false
        }
    }
    
    func removePick(_ pick: BetPick) {
        currentPicks.removeAll { $0.id == pick.id }
    }
    
    @discardableResult
    func confirmSlip(stake: Double) -> Bool {
        guard stake > 0, stake <= balance else { return false }

        let refreshedSelection = refreshedPicks(for: currentPicks)
        let openSelection = refreshedSelection.filter { isMatchBettable($0.match) }

        guard !openSelection.isEmpty else {
            currentPicks.removeAll()
            return false
        }

        guard openSelection.count == refreshedSelection.count else {
            currentPicks = openSelection
            return false
        }

        let slipTotalOdd = openSelection.map { $0.odd }.reduce(1, *)
        
        let slip = BetSlip(
            id: UUID(),
            picks: openSelection,
            stake: stake,
            totalOdd: slipTotalOdd,
            potentialWin: stake * slipTotalOdd,
            date: Date(),
            isWon: nil,
            isEvaluated: false
        )
        balance -= stake
        currentPicks.removeAll()
        slips.insert(slip, at: 0)
        saveSlips()
        return true
    }
    
    private func saveSlips() {
        if let data = try? JSONEncoder().encode(slips) {
            UserDefaults.standard.set(data, forKey: slipsKey)
        }
        syncBetStatsToCloudIfPossible()
    }
    
    private func loadSlips() -> [BetSlip] {
        guard let data = UserDefaults.standard.data(forKey: slipsKey),
              let decoded = try? JSONDecoder().decode([BetSlip].self, from: data) else { return [] }
        return decoded
    }

    private enum PickSettlement: Equatable {
        case pending
        case won
        case lost
    }

    private func latestMatch(for baseMatch: Match) -> Match {
        for matches in dailyMatches.values {
            if let updatedMatch = matches.first(where: { $0.id == baseMatch.id }) {
                return updatedMatch
            }
        }
        return baseMatch
    }

    private func refreshedPicks(for picks: [BetPick]) -> [BetPick] {
        picks.map { pick in
            let updatedMatch = latestMatch(for: pick.match)
            return BetPick(
                id: pick.id,
                match: updatedMatch,
                outcome: pick.outcome,
                odd: pick.odd
            )
        }
    }

    private func settlement(for pick: BetPick) -> PickSettlement {
        guard pick.match.status == "FINISHED" else { return .pending }

        switch pick.outcome {
        case .home, .draw, .away:
            guard let result = pick.match.result else { return .pending }
            return result == pick.outcome ? .won : .lost

        case .homeDraw:
            guard let result = pick.match.result else { return .pending }
            return (result == .home || result == .draw) ? .won : .lost

        case .homeAway:
            guard let result = pick.match.result else { return .pending }
            return (result == .home || result == .away) ? .won : .lost

        case .drawAway:
            guard let result = pick.match.result else { return .pending }
            return (result == .draw || result == .away) ? .won : .lost

        case .over05:
            guard let goals = pick.match.goals else { return .pending }
            return goals > 0 ? .won : .lost

        case .under05:
            guard let goals = pick.match.goals else { return .pending }
            return goals == 0 ? .won : .lost

        case .over15:
            guard let goals = pick.match.goals else { return .pending }
            return goals > 1 ? .won : .lost

        case .under15:
            guard let goals = pick.match.goals else { return .pending }
            return goals <= 1 ? .won : .lost

        case .over25:
            guard let goals = pick.match.goals else { return .pending }
            return goals > 2 ? .won : .lost

        case .under25:
            guard let goals = pick.match.goals else { return .pending }
            return goals <= 2 ? .won : .lost

        case .over35:
            guard let goals = pick.match.goals else { return .pending }
            return goals > 3 ? .won : .lost

        case .under35:
            guard let goals = pick.match.goals else { return .pending }
            return goals <= 3 ? .won : .lost

        case .over45:
            guard let goals = pick.match.goals else { return .pending }
            return goals > 4 ? .won : .lost

        case .under45:
            guard let goals = pick.match.goals else { return .pending }
            return goals <= 4 ? .won : .lost
        }
    }
    
    func evaluateSlip(_ slip: BetSlip) -> BetSlip {
        if slip.isEvaluated { return slip }

        let picksWithLatestMatches = refreshedPicks(for: slip.picks)
        var updatedSlip = BetSlip(
            id: slip.id,
            picks: picksWithLatestMatches,
            stake: slip.stake,
            totalOdd: slip.totalOdd,
            potentialWin: slip.potentialWin,
            date: slip.date,
            isWon: slip.isWon,
            isEvaluated: slip.isEvaluated
        )

        let settlements = picksWithLatestMatches.map { settlement(for: $0) }
        if settlements.contains(.pending) {
            updatedSlip.isWon = nil
            updatedSlip.isEvaluated = false
            return updatedSlip
        }

        let allCorrect = settlements.allSatisfy { $0 == .won }
        updatedSlip.isWon = allCorrect
        updatedSlip.isEvaluated = true
        
        if allCorrect {
            balance += updatedSlip.potentialWin
        }
        
        return updatedSlip
    }
    
    func evaluateAllSlips() {
        slips = slips.map { evaluateSlip($0) }
        saveSlips()
    }
    
    var totalBetsCount: Int {
        if slips.isEmpty {
            return remoteTotalBetsCount
        }
        return slips.count
    }
    
    var totalWins: Int {
        if slips.isEmpty {
            return remoteTotalWins
        }
        return slips.filter { $0.isWon == true }.count
    }
    
    var totalLosses: Int {
        if slips.isEmpty {
            return remoteTotalLosses
        }
        return slips.filter { $0.isWon == false }.count
    }

    func redeemPromoCode(_ rawCode: String, completion: @escaping (PromoCodeRedemptionResult) -> Void) {
        let normalizedCode = normalizePromoCode(rawCode)

        guard !normalizedCode.isEmpty else {
            completion(.emptyCode)
            return
        }

        guard let userID = AuthManager.shared.currentUserID else {
            completion(.authRequired)
            return
        }

        fetchPromoCodesIfNeeded { [weak self] in
            guard let self = self else {
                completion(.storeUnavailable)
                return
            }

            guard !self.promoCodes.isEmpty else {
                completion(.storeUnavailable)
                return
            }

            guard let promoCode = self.promoCodes.first(where: { $0.normalizedCode == normalizedCode }) else {
                completion(.invalidCode)
                return
            }

            FirebaseManager.shared.registerPromoCodeUsage(
                userID: userID,
                code: promoCode.normalizedCode,
                bonus: promoCode.bonus,
                maxUses: promoCode.maxUses
            ) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else {
                        completion(.storeUnavailable)
                        return
                    }
                    
                    switch result {
                    case .success(let updatedBalance):
                        self.balance = updatedBalance
                        completion(.success(promoCode))
                    case .failure(let error):
                        switch error {
                        case .limitReached:
                            if promoCode.maxUses == 1 {
                                completion(.alreadyRedeemed)
                            } else {
                                completion(.limitReached(maxUses: promoCode.maxUses))
                            }
                        case .invalidConfiguration:
                            completion(.invalidCode)
                        case .generic:
                            completion(.storeUnavailable)
                        }
                    }
                }
            }
        }
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

    private func fetchPromoCodesIfNeeded(completion: (() -> Void)? = nil) {
        guard promoCodes.isEmpty else {
            completion?()
            return
        }

        fetchPromoCodes(completion: completion)
    }

    private func fetchPromoCodes(completion: (() -> Void)? = nil) {
        guard !isLoadingPromoCodes else {
            if let completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.fetchPromoCodesIfNeeded(completion: completion)
                }
            }
            return
        }

        guard let url = URL(string: promoCodesURLString) else {
            completion?()
            return
        }

        isLoadingPromoCodes = true

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion?()
                    return
                }

                defer {
                    self.isLoadingPromoCodes = false
                    completion?()
                }

                guard let data = data,
                      let decodedCodes = self.decodePromoCodes(from: data) else {
                    return
                }

                self.promoCodes = decodedCodes
            }
        }.resume()
    }

    private func decodePromoCodes(from data: Data) -> [PromoCode]? {
        if let catalog = try? JSONDecoder().decode(PromoCodeCatalog.self, from: data) {
            return catalog.codes.filter { isValidPromoCode($0) }
        }

        if let codes = try? JSONDecoder().decode([PromoCode].self, from: data) {
            return codes.filter { isValidPromoCode($0) }
        }

        return nil
    }

    private func isValidPromoCode(_ promoCode: PromoCode) -> Bool {
        !promoCode.normalizedCode.isEmpty && promoCode.maxUses > 0 && promoCode.isActive
    }

    private func normalizePromoCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func intValue(from raw: Any?) -> Int? {
        switch raw {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as Double:
            return Int(value)
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }
}

// MARK: - MAIN VIEW CON TOOLBAR SOPRA

struct ContentView: View {
    
    @StateObject private var vm = BettingViewModel()
    @State private var refreshID = UUID()
    @State private var showProfileSettings = false
    @AppStorage("profileSelectedTheme") private var selectedTheme = "Sistema"
    private let calendarPastDays = 7
    private let calendarFutureDays = 21
    private let preferredLeagueOrder = OddsService.supportedSoccerLeagues.map(\.displayName)
    
    var body: some View {
        NavigationView {
            #if compiler(>=6.0)
            if #available(iOS 26.0, tvOS 26.0, *) {
                tabContainer
                #if !os(tvOS)
                .tabBarMinimizeBehavior(.onScrollDown)
                #endif
            } else {
                tabContainer
            }
            #else
            tabContainer
            #endif
        }
        .navigationBarHidden(true)
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch selectedTheme {
        case "Chiaro":
            return .light
        case "Scuro":
            return .dark
        default:
            return nil
        }
    }
    
    private var tabContainer: some View {
        TabView(selection: $vm.selectedTab) {
            sportTab
                .tag(0)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Sport")
                }

            casinoTab
                .tag(1)
                .tabItem {
                    Image(systemName: "dice.fill")
                    Text("Casino")
                }

            legaTab
                .tag(2)
                .tabItem {
                    Image(systemName: "list.number")
                    Text("Lega")
                }

            storicoTab
                .tag(3)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Storico")
                }

            profiloTab
                .tag(4)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profilo")
                }
            }
            .tint(.accentCyan)
            .sheet(isPresented: $vm.showSheet) {
                BetSheet(
                    picks: $vm.currentPicks,
                    balance: $vm.balance,
                    totalOdd: vm.totalOdd
                ) { stake in vm.confirmSlip(stake: stake) }
            }
            .sheet(item: $vm.showSlipDetail) { SlipDetailView(slip: $0) }
    }
    
    private var sportTab: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                FloatingHeader(
                    title: "Sport",
                    balance: vm.balance,
                    showSportPicker: $vm.showSportPicker,
                    showsBalance: true
                )

                if vm.selectedSport == "Tennis" {
                    tennisComingSoonView
                } else {
                    calendarBarView
                    myPredictionBarView
                        .animation(.easeInOut(duration: 0.2), value: vm.currentPicks.count)
                    
                    if vm.isLoading {
                        loadingView
                    } else {
                        matchListView
                    }
                }
            }
            .id(refreshID)

            if vm.showSportPicker {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        vm.hideSportPicker()
                    }
                    .transition(.opacity)
                    .zIndex(1)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 66)

                    HStack {
                        sportPickerMenu
                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .zIndex(2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var sportPickerMenu: some View {
        VStack(spacing: 6) {
            sportPickerButton(title: "Calcio", icon: "soccerball")
            sportPickerButton(title: "Tennis", icon: "tennis.racket")
        }
        .padding(8)
        .frame(width: 190, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 8)
    }

    private func sportPickerButton(title: String, icon: String) -> some View {
        let isSelected = vm.selectedSport == title

        return Button {
            vm.selectedSport = title
            vm.hideSportPicker()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .accentCyan)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentCyan : Color.white.opacity(0.08))
                    )

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isSelected ? .black : .white)

                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentCyan : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var tennisComingSoonView: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "tennis.racket")
                .font(.system(size: 58))
                .foregroundColor(.accentCyan)

            Text("Tennis")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("In arrivo col prossimo aggiornamento...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var casinoTab: some View {
        CasinoFullView()
            .environmentObject(vm)
            .edgesIgnoringSafeArea(.bottom)
    }
    
    private var legaTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                FloatingHeader(
                    title: "Lega",
                    balance: vm.balance,
                    showSportPicker: $vm.showSportPicker,
                    showsBalance: true
                )
                
                LeagueLeaderboardView()
            }
            .id(refreshID)
        }
    }
    
    private var storicoTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                FloatingHeader(
                    title: "Storico",
                    balance: vm.balance,
                    showSportPicker: $vm.showSportPicker,
                    showsBalance: true
                )
                
                placedBetsView
            }
            .id(refreshID)
        }
    }
    
    private var profiloTab: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                FloatingHeader(
                    title: "Profilo",
                    balance: vm.balance,
                    showSportPicker: $vm.showSportPicker,
                    showsBalance: false,
                    trailingSystemImage: "gearshape.fill",
                    trailingAction: { showProfileSettings = true }
                )
                
                ProfileView()
                    .environmentObject(vm)

                NavigationLink(destination: ProfileSettingsView(vm: vm), isActive: $showProfileSettings) {
                    EmptyView()
                }
                .hidden()
            }
            .id(refreshID)
        }
    }
    
    // MARK: - CALENDAR BAR
    private var calendarBarView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(calendarDayIndices, id: \.self) { index in
                            let date = vm.dateForIndex(index)
                            let isSelected = vm.selectedDayIndex == index
                            let isToday = vm.isToday(date)

                            VStack(spacing: 3) {
                                Text(vm.formattedWeekday(date))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(isToday ? .accentCyan : .gray)
                                    .lineLimit(1)

                                Text(vm.formattedDay(date))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                Text(vm.formattedMonth(date))
                                    .font(.caption2)
                                    .foregroundColor(isToday ? .accentCyan : .gray)
                                    .lineLimit(1)
                            }
                            .frame(width: 86, height: 72)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                isSelected ? Color.accentCyan : Color.white.opacity(0.24),
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .contentShape(Rectangle())
                            .id(index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    vm.selectedDayIndex = index
                                    proxy.scrollTo(index, anchor: .center)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(vm.selectedDayIndex, anchor: .center)
                }
            }
            .onChange(of: vm.selectedDayIndex) { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var myPredictionBarView: some View {
        Group {
            if !vm.currentPicks.isEmpty {
                Button {
                    vm.showSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checklist")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Il mio pronostico")
                            .font(.subheadline.bold())
                            .foregroundColor(.black)

                        Spacer()

                        Text("\(vm.currentPicks.count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentCyan)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.accentCyan.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
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
            
            Text("Sto recuperando le partite reali")
                .foregroundColor(.gray)
                .font(.caption)
            
            Spacer()
        }
        .padding(.bottom, 100)
    }
    
    // MARK: MATCH LIST
    private var matchListView: some View {
        let groupedMatchesByTime = vm.matchesForSelectedDay()
        let orderedTimes = sortedTimeKeys(groupedMatchesByTime.keys)
        let matches = orderedTimes.flatMap { groupedMatchesByTime[$0] ?? [] }
        let selectedDate = vm.dateForIndex(vm.selectedDayIndex)
        let isPastDay = vm.isPast(selectedDate)
        let preferredMatches = sortMatchesByTime(
            matches.filter { isPreferredCompetition(competitionKey(for: $0)) }
        )
        let otherMatches = sortMatchesByTime(
            matches.filter { !isPreferredCompetition(competitionKey(for: $0)) }
        )
        let preferredGroupedMatches = groupMatchesBySortedTime(preferredMatches)
        let otherGroupedMatches = groupMatchesBySortedTime(otherMatches)
        
        return ScrollView {
            VStack(spacing: 16) {
                if matches.isEmpty && !vm.isLoading {
                    emptyMatchesView
                } else {
                    if !preferredMatches.isEmpty {
                        sectionHeader(title: "Campionati principali")
                    }

                    ForEach(preferredGroupedMatches, id: \.time) { timeGroup in
                        timeHeader(timeGroup.time)

                        ForEach(timeGroup.matches) { match in
                            let isMatchClosed = !vm.canBet(on: match)
                            let isDisabled = isPastDay || isMatchClosed

                            NavigationLink(destination: MatchDetailView(match: match, vm: vm)) {
                                matchCardView(match: match, disabled: isDisabled)
                            }
                            .disabled(isDisabled)
                        }
                    }

                    if !otherMatches.isEmpty {
                        sectionHeader(
                            title: "Altri campionati",
                            topPadding: preferredMatches.isEmpty ? 0 : 6
                        )
                    }

                    ForEach(otherGroupedMatches, id: \.time) { timeGroup in
                        timeHeader(timeGroup.time)

                        ForEach(timeGroup.matches) { match in
                            let isMatchClosed = !vm.canBet(on: match)
                            let isDisabled = isPastDay || isMatchClosed

                            NavigationLink(destination: MatchDetailView(match: match, vm: vm)) {
                                matchCardView(match: match, disabled: isDisabled)
                            }
                            .disabled(isDisabled)
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        .id("\(vm.selectedDayIndex)-\(vm.selectedSport)")
        .transition(.opacity)
    }

    private var calendarDayIndices: [Int] {
        Array((1 - calendarPastDays)...(1 + calendarFutureDays))
    }

    private func competitionKey(for match: Match) -> String {
        let value = match.competition.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Campionato" : value
    }

    private func isPreferredCompetition(_ competition: String) -> Bool {
        let normalized = normalizeCompetitionName(competition)
        return preferredLeagueOrder.contains { normalizeCompetitionName($0) == normalized }
    }

    private func normalizeCompetitionName(_ name: String) -> String {
        name
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "it_IT"))
            .replacingOccurrences(of: " ", with: "")
    }

    private func sortedTimeKeys<S: Sequence>(_ keys: S) -> [String] where S.Element == String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"

        return keys.sorted { lhs, rhs in
            let left = formatter.date(from: lhs)
            let right = formatter.date(from: rhs)

            switch (left, right) {
            case let (leftDate?, rightDate?):
                return leftDate < rightDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs < rhs
            }
        }
    }

    private func sortMatchesByTime(_ matches: [Match]) -> [Match] {
        matches.sorted { left, right in
            let leftTime = timeSortValue(left.time)
            let rightTime = timeSortValue(right.time)
            if leftTime != rightTime {
                return leftTime < rightTime
            }

            if left.competition != right.competition {
                return left.competition < right.competition
            }

            if left.home != right.home {
                return left.home < right.home
            }

            return left.away < right.away
        }
    }

    private func groupMatchesBySortedTime(_ matches: [Match]) -> [(time: String, matches: [Match])] {
        let grouped = Dictionary(grouping: matches) { $0.time }
        let orderedTimes = sortedTimeKeys(grouped.keys)
        return orderedTimes.map { time in
            let values = grouped[time] ?? []
            return (time: time, matches: sortMatchesByTime(values))
        }
    }

    private func timeSortValue(_ rawTime: String) -> Int {
        let pieces = rawTime.split(separator: ":")
        guard pieces.count == 2,
              let hour = Int(pieces[0]),
              let minute = Int(pieces[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return Int.max
        }

        return hour * 60 + minute
    }

    private func sectionHeader(title: String, topPadding: CGFloat = 0) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.top, topPadding)
        .padding(.horizontal, 4)
    }

    private func timeHeader(_ value: String) -> some View {
        HStack {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.accentCyan)
            Spacer()
        }
        .padding(.top, 2)
        .padding(.horizontal, 4)
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
            
            Text("Torna piÃ¹ tardi per vedere nuove partite")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func matchCardView(match: Match, disabled: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
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
                    
                    if match.status == "FINISHED", let actualResult = match.actualResult {
                        Text(actualResult)
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else if match.status.uppercased() != "SCHEDULED" {
                        Text(match.status)
                            .font(.caption2)
                            .foregroundColor(match.status == "FINISHED" ? .green : 
                                           match.status == "LIVE" ? .red : .orange)
                    } else {
                        Text(" ")
                            .font(.caption2)
                            .hidden()
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
                    emptyBetsView
                } else {
                    ForEach(vm.slips) { slip in
                        Button { vm.showSlipDetail = slip } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quota \(slip.totalOdd, specifier: "%.2f")")
                                    .foregroundColor(.accentCyan)
                                HStack(spacing: 6) {
                                    Text("Puntata")
                                        .foregroundColor(.white)
                                    GemAmountLabel(amount: slip.stake, color: .white, font: .body, iconSize: 12)
                                }
                                HStack(spacing: 6) {
                                    Text("Vincita potenziale")
                                        .foregroundColor(.gray)
                                    GemAmountLabel(amount: slip.potentialWin, color: .gray, font: .caption, iconSize: 11)
                                }
                                .font(.caption)
                                
                                if let won = slip.isWon {
                                    Text(won ? "ESITO: VINTA" : "ESITO: PERSA")
                                        .foregroundColor(won ? .green : .red)
                                        .font(.headline)
                                } else {
                                    Text("ESITO: IN SOSPESO")
                                        .foregroundColor(.orange)
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
            .padding(.bottom, 100)
        }
        .onAppear { vm.evaluateAllSlips() }
    }
    
    private var emptyBetsView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 50)
            
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.accentCyan)
            
            Text("Nessuna scommessa piazzata")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Torna alla sezione scommesse per iniziare")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
}

// MARK: - CASINO FULL VIEW (FIXATO)

struct CasinoFullView: View {
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        ZStack {
            // Sfondo che parte DALL'ALTO e copre TUTTO
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) // MODIFICATO: .all invece che .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header DEDICATO per Casino
                VStack(spacing: 0) {
                    HStack {
                        Text("Casino")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Saldo utente
                        GemAmountLabel(amount: vm.balance, color: .accentCyan, font: .headline, weight: .bold, iconSize: 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // Linea sottile divisoria
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .accentCyan.opacity(0.3),
                                    .blue.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .blur(radius: 0.5)
                        .padding(.horizontal, 20)
                }
                .background(Color.black.opacity(0.3))
                
                // Contenuto del Casino - FIXATO con safe area
                GamesContentView()
                    .environmentObject(vm)
                    .padding(.bottom, 60) // PADDING AGGIUNTO PER LA TOOLBAR
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 40) // SPAZIO PER LA TOOLBAR
            }
        }
    }
}

// MARK: - GAMES CONTENT VIEW

struct GamesContentView: View {
    let games = [
        ("Gratta e Vinci", "sparkles", Color.accentCyan),
        ("Slot Machine", "dice.fill", Color.pink),
        ("Crazy Time", "timer", Color.orange),
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
                        // Usa GameButton dal file GameView.swift
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
                        
                        Text("Gioco responsabile â€¢ Maggiorenni â€¢ Vietato ai minori")
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
            .padding(.bottom, 100) // PADDING PER LA TOOLBAR
        }
        .background(Color.clear)
    }
}





