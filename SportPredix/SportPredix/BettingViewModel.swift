import SwiftUI

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

    @Published var currentPicks: [BetPick] = []
    @Published var slips: [BetSlip] = []

    @Published var dailyMatches: [String: [Match]] = [:]

    private let slipsKey = "savedSlips"
    private let matchesKey = "savedMatches"

    private let teams = [
        "Napoli","Inter","Milan","Juventus","Roma","Lazio",
        "Liverpool","Chelsea","Arsenal","Man City","Tottenham",
        "Real Madrid","Barcellona","Atletico","Valencia",
        "Bayern","Dortmund","Leipzig","Leverkusen"
    ]

    init() {
        let savedBalance = UserDefaults.standard.double(forKey: "balance")
        self.balance = savedBalance == 0 ? 1000 : savedBalance

        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.slips = loadSlips()
        self.dailyMatches = loadMatches()

        generateTodayIfNeeded()
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
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    func generateMatchesForDate(_ date: Date) -> [Match] {
        var result: [Match] = []

        for _ in 0..<12 {
            let home = teams.randomElement()!
            var away = teams.randomElement()!
            while away == home { away = teams.randomElement()! }

            let hour = Int.random(in: 12...22)
            let minute = ["00","15","30","45"].randomElement()!
            let time = "\(hour):\(minute)"

            let odds = Odds(
                home: Double.random(in: 1.20...2.50),
                draw: Double.random(in: 2.80...4.50),
                away: Double.random(in: 2.50...7.00),
                homeDraw: Double.random(in: 1.10...1.50),
                homeAway: Double.random(in: 1.15...1.30),
                drawAway: Double.random(in: 1.20...1.60),
                over25: Double.random(in: 1.70...2.20),
                under25: Double.random(in: 1.70...2.20)
            )

            let goals = Int.random(in: 0...6)

            let possibleResults: [MatchOutcome] = [.home, .draw, .away]
            let randomResult = possibleResults.randomElement()!

            result.append(Match(
                id: UUID(),
                home: home,
                away: away,
                time: time,
                odds: odds,
                result: randomResult,
                goals: goals
            ))
        }

        return result
    }

    func generateTodayIfNeeded() {
        let todayKey = keyForDate(Date())

        if dailyMatches[todayKey] == nil {
            dailyMatches[todayKey] = generateMatchesForDate(Date())
            saveMatches()
        }
    }

    func matchesForSelectedDay() -> [String: [Match]] {
        let date = dateForIndex(selectedDayIndex)
        let key = keyForDate(date)

        if let existing = dailyMatches[key] {
            return Dictionary(grouping: existing) { $0.time }
        }

        let newMatches = generateMatchesForDate(date)
        dailyMatches[key] = newMatches
        saveMatches()
        return Dictionary(grouping: newMatches) { $0.time }
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
        if let index = currentPicks.firstIndex(where: { $0.match.id == match.id && $0.outcome == outcome }) {
            currentPicks.remove(at: index)
        } else {
            currentPicks.append(BetPick(id: UUID(), match: match, outcome: outcome, odd: odd))
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
            date: Date()
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
            case .over25:
                return (pick.match.goals ?? 0) > 2
            case .under25:
                return (pick.match.goals ?? 0) <= 2
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

    var totalBetsCount: Int { slips.count }
    var totalWins: Int { slips.filter { $0.isWon == true }.count }
    var totalLosses: Int { slips.filter { $0.isWon == false }.count }
}