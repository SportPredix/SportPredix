//
//  OddsService.swift
//  SportPredix
//

import Foundation

final class OddsService {
    enum SoccerLeague: String, CaseIterable {
        case serieA = "ita.1"
        case premierLeague = "eng.1"
        case laLiga = "esp.1"
        case bundesliga = "ger.1"
        case ligue1 = "fra.1"
        case championsLeague = "uefa.champions"
        case europaLeague = "uefa.europa"

        var displayName: String {
            switch self {
            case .serieA:
                return "Serie A"
            case .premierLeague:
                return "Premier League"
            case .laLiga:
                return "La Liga"
            case .bundesliga:
                return "Bundesliga"
            case .ligue1:
                return "Ligue 1"
            case .championsLeague:
                return "UEFA Champions League"
            case .europaLeague:
                return "UEFA Europa League"
            }
        }
    }

    static let shared = OddsService()
    static let supportedSoccerLeagues: [SoccerLeague] = [
        .serieA,
        .premierLeague,
        .laLiga,
        .bundesliga,
        .ligue1,
        .championsLeague,
        .europaLeague
    ]
    private init() {}

    private typealias GoalLineOdds = (over: Double, under: Double)

    private struct PartialGoalLineOdds {
        var over: Double?
        var under: Double?
    }

    private struct FairProbabilities {
        let over: Double
        let overround: Double
    }

    private let espnSoccerBaseURL = "https://site.api.espn.com/apis/site/v2/sports/soccer"
    private let trackedGoalLines: [Double] = [0.5, 1.5, 2.5, 3.5, 4.5]

    func fetchSerieAOdths(for date: Date = Date(), completion: @escaping (Result<[Match], Error>) -> Void) {
        fetchOdds(for: date, league: .serieA, completion: completion)
    }

    func fetchSerieAMatchesByDateRange(
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[String: [Match]], Error>) -> Void
    ) {
        fetchMatchesByDateRange(from: startDate, to: endDate, league: .serieA, completion: completion)
    }

    func fetchOdds(
        for date: Date = Date(),
        league: SoccerLeague = .serieA,
        completion: @escaping (Result<[Match], Error>) -> Void
    ) {
        fetchMatchesByDateRange(from: date, to: date, league: league) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let grouped):
                let key = self.dayKey(from: date)
                let sameDayMatches = grouped[key] ?? grouped.values.flatMap { $0 }
                completion(.success(sameDayMatches))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchMatchesByDateRange(
        from startDate: Date,
        to endDate: Date,
        league: SoccerLeague = .serieA,
        completion: @escaping (Result<[String: [Match]], Error>) -> Void
    ) {
        fetchMatchesByDateRange(from: startDate, to: endDate, leagues: [league], completion: completion)
    }

    func fetchMatchesByDateRange(
        from startDate: Date,
        to endDate: Date,
        leagues: [SoccerLeague],
        completion: @escaping (Result<[String: [Match]], Error>) -> Void
    ) {
        let uniqueLeagues = leagues.reduce(into: [SoccerLeague]()) { partialResult, league in
            if !partialResult.contains(league) {
                partialResult.append(league)
            }
        }

        guard !uniqueLeagues.isEmpty else {
            completion(.success([:]))
            return
        }

        let start = min(startDate, endDate)
        let end = max(startDate, endDate)
        let startString = scoreboardDateString(from: start)
        let endString = scoreboardDateString(from: end)
        let datesQuery = startString == endString ? startString : "\(startString)-\(endString)"

        let aggregateQueue = DispatchQueue(label: "OddsService.aggregateQueue")
        let group = DispatchGroup()
        var mergedPairs: [(kickoff: Date, match: Match)] = []
        var failures: [Error] = []

        for league in uniqueLeagues {
            group.enter()
            fetchScoreboard(league: league, datesQuery: datesQuery) { result in
                aggregateQueue.async {
                    switch result {
                    case .success(let parsed):
                        mergedPairs.append(contentsOf: parsed)
                    case .failure(let error):
                        failures.append(error)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: aggregateQueue) { [weak self] in
            guard let self else { return }

            let grouped = self.groupMatchesByDay(mergedPairs)
            DispatchQueue.main.async {
                if !grouped.isEmpty {
                    completion(.success(grouped))
                } else if let firstError = failures.first {
                    completion(.failure(firstError))
                } else {
                    completion(.success([:]))
                }
            }
        }
    }

    private func groupMatchesByDay(_ parsed: [(kickoff: Date, match: Match)]) -> [String: [Match]] {
        let groupedPairs = Dictionary(grouping: parsed) { pair in
            dayKey(from: pair.kickoff)
        }

        return groupedPairs.mapValues { pairs in
            pairs
                .sorted { $0.kickoff < $1.kickoff }
                .map { $0.match }
        }
    }

    private func fetchScoreboard(
        league: SoccerLeague,
        datesQuery: String,
        completion: @escaping (Result<[(kickoff: Date, match: Match)], Error>) -> Void
    ) {
        guard let url = scoreboardURL(for: league, datesQuery: datesQuery) else {
            let error = NSError(
                domain: "Matches API",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "URL API non valida"]
            )
            completion(.failure(error))
            return
        }

        print("Fetching \(league.displayName) matches: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(
                    domain: "Matches API",
                    code: 502,
                    userInfo: [NSLocalizedDescriptionKey: "Risposta HTTP non valida"]
                )
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let error = NSError(
                    domain: "Matches API",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP Status: \(httpResponse.statusCode)"]
                )
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data else {
                let error = NSError(
                    domain: "Matches API",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Nessun dato ricevuto"]
                )
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            do {
                let response = try self.decodeScoreboardResponse(from: data)
                let competitionName = response.leagues.first?.name ?? league.displayName

                let parsedMatches = response.events
                    .compactMap { self.convertESPNEvent($0, competitionName: competitionName) }
                let filteredMatches = self.filterParsedMatches(parsedMatches, datesQuery: datesQuery)
                print("\(league.displayName) parsed events=\(response.events.count), matchesAfterFilter=\(filteredMatches.count), datesQuery=\(datesQuery)")

                DispatchQueue.main.async {
                    completion(.success(filteredMatches))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    private func scoreboardURL(for league: SoccerLeague, datesQuery: String) -> URL? {
        var components = URLComponents(string: "\(espnSoccerBaseURL)/\(league.rawValue)/scoreboard")
        components?.queryItems = [
            URLQueryItem(name: "dates", value: datesQuery)
        ]
        return components?.url
    }

    private func decodeScoreboardResponse(from data: Data) throws -> ESPNScoreboardResponse {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ESPNScoreboardResponse.self, from: data)
        } catch {
            let fallbackEncodings: [String.Encoding] = [.isoLatin1, .windowsCP1252]

            for encoding in fallbackEncodings {
                guard let text = String(data: data, encoding: encoding),
                      let normalizedData = text.data(using: .utf8) else {
                    continue
                }

                if let decoded = try? decoder.decode(ESPNScoreboardResponse.self, from: normalizedData) {
                    print("Scoreboard decoded with fallback encoding: \(encoding.rawValue)")
                    return decoded
                }
            }

            throw error
        }
    }

    private func convertESPNEvent(
        _ event: ESPNEvent,
        competitionName: String
    ) -> (kickoff: Date, match: Match)? {
        guard let competition = event.competitions.first else { return nil }

        guard
            let home = competition.competitors.first(where: { $0.homeAway.lowercased() == "home" }),
            let away = competition.competitors.first(where: { $0.homeAway.lowercased() == "away" })
        else {
            return nil
        }

        let parsedKickoffDate = parseAPIDate(event.date)
        let kickoffDate = parsedKickoffDate ?? Date.distantFuture
        let kickoffTime = parsedKickoffDate.map { displayTimeString(from: $0) } ?? "TBD"
        let odds = resolvedOdds(
            from: competition,
            homeTeam: home.team.displayName,
            awayTeam: away.team.displayName
        )
        let status = normalizedStatus(from: event.status.type)

        let homeScore = Int(home.score ?? "")
        let awayScore = Int(away.score ?? "")
        let isFinished = status == "FINISHED"
        let goals: Int?
        let actualResult: String?
        if isFinished, let homeScore = homeScore, let awayScore = awayScore {
            goals = homeScore + awayScore
            actualResult = "\(homeScore)-\(awayScore)"
        } else {
            goals = nil
            actualResult = nil
        }

        var result: MatchOutcome?
        if isFinished, let homeScore = homeScore, let awayScore = awayScore {
            if homeScore > awayScore {
                result = .home
            } else if awayScore > homeScore {
                result = .away
            } else {
                result = .draw
            }
        }

        let match = Match(
            id: stableUUID(from: event.id),
            home: home.team.displayName,
            away: away.team.displayName,
            time: kickoffTime,
            odds: odds,
            result: result,
            goals: goals,
            competition: competitionName,
            status: status,
            actualResult: actualResult
        )

        return (kickoffDate, match)
    }

    private func normalizedStatus(from type: ESPNStatusType) -> String {
        if type.completed == true || type.state == "post" {
            return "FINISHED"
        }

        if type.state == "in" {
            return "LIVE"
        }

        return "SCHEDULED"
    }

    private func resolvedOdds(from competition: ESPNCompetition, homeTeam: String, awayTeam: String) -> Odds {
        let fallback = estimatedOdds(homeTeam: homeTeam, awayTeam: awayTeam)
        let entries = preferredOddsEntries(from: competition.odds)
        guard !entries.isEmpty else {
            return fallback
        }

        let moneyline = extractMoneylineOdds(from: entries)
        let homeOdd = moneyline.home ?? fallback.home
        let drawOdd = moneyline.draw ?? fallback.draw
        let awayOdd = moneyline.away ?? fallback.away

        let totals = buildGoalLines(from: entries, fallback: fallback)
        let line05 = goalLineOdds(for: 0.5, in: totals, fallback: (over: fallback.over05, under: fallback.under05))
        let line15 = goalLineOdds(for: 1.5, in: totals, fallback: (over: fallback.over15, under: fallback.under15))
        let line25 = goalLineOdds(for: 2.5, in: totals, fallback: (over: fallback.over25, under: fallback.under25))
        let line35 = goalLineOdds(for: 3.5, in: totals, fallback: (over: fallback.over35, under: fallback.under35))
        let line45 = goalLineOdds(for: 4.5, in: totals, fallback: (over: fallback.over45, under: fallback.under45))
        let pointSpread = extractPointSpread(from: entries)
        let mainTotal = extractMainTotal(from: entries)
        let providerName = normalizedProviderName(entries.first?.provider?.name)

        return Odds(
            home: roundToTwoDecimals(homeOdd),
            draw: roundToTwoDecimals(drawOdd),
            away: roundToTwoDecimals(awayOdd),
            homeDraw: combinedOdd(homeOdd, drawOdd),
            homeAway: combinedOdd(homeOdd, awayOdd),
            drawAway: combinedOdd(drawOdd, awayOdd),
            over05: line05.over,
            under05: line05.under,
            over15: line15.over,
            under15: line15.under,
            over25: line25.over,
            under25: line25.under,
            over35: line35.over,
            under35: line35.under,
            over45: line45.over,
            under45: line45.under,
            apiProvider: providerName,
            apiMainTotalLine: mainTotal.line,
            apiMainOver: mainTotal.overOdd,
            apiMainUnder: mainTotal.underOdd,
            handicapHome: pointSpread.homeOdd,
            handicapAway: pointSpread.awayOdd,
            handicapHomeLine: pointSpread.homeLine,
            handicapAwayLine: pointSpread.awayLine
        )
    }

    private func normalizedProviderName(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        return value
    }

    private func preferredOddsEntries(from entries: [ESPNCompetitionOdds?]?) -> [ESPNCompetitionOdds] {
        (entries ?? [])
            .compactMap { $0 }
            .sorted { lhs, rhs in
                let lhsPriority = lhs.provider?.priority ?? Int.max
                let rhsPriority = rhs.provider?.priority ?? Int.max
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }

                let lhsName = lhs.provider?.name ?? ""
                let rhsName = rhs.provider?.name ?? ""
                return lhsName < rhsName
            }
    }

    private func extractMoneylineOdds(from entries: [ESPNCompetitionOdds]) -> (home: Double?, draw: Double?, away: Double?) {
        var home: Double?
        var draw: Double?
        var away: Double?

        for entry in entries {
            if home == nil {
                home = decimalOdd(from: entry.moneyline?.home)
            }

            if draw == nil {
                draw = decimalOdd(from: entry.moneyline?.draw)
                if draw == nil, let drawMoneyLine = entry.drawOdds?.moneyLine {
                    draw = decimalOdd(fromAmericanValue: drawMoneyLine)
                }
            }

            if away == nil {
                away = decimalOdd(from: entry.moneyline?.away)
            }

            if home != nil, draw != nil, away != nil {
                break
            }
        }

        return (
            home: sanitizeOdd(home),
            draw: sanitizeOdd(draw),
            away: sanitizeOdd(away)
        )
    }

    private func extractPointSpread(
        from entries: [ESPNCompetitionOdds]
    ) -> (homeOdd: Double?, awayOdd: Double?, homeLine: Double?, awayLine: Double?) {
        var homeOdd: Double?
        var awayOdd: Double?
        var homeLine: Double?
        var awayLine: Double?

        for entry in entries {
            if homeOdd == nil {
                homeOdd = sanitizeOdd(decimalOdd(from: entry.pointSpread?.home))
            }

            if awayOdd == nil {
                awayOdd = sanitizeOdd(decimalOdd(from: entry.pointSpread?.away))
            }

            if homeLine == nil {
                homeLine = parseGoalLine(from: entry.pointSpread?.home?.close?.line)
                    ?? parseGoalLine(from: entry.pointSpread?.home?.open?.line)
            }

            if awayLine == nil {
                awayLine = parseGoalLine(from: entry.pointSpread?.away?.close?.line)
                    ?? parseGoalLine(from: entry.pointSpread?.away?.open?.line)
            }

            if homeOdd != nil, awayOdd != nil, homeLine != nil, awayLine != nil {
                break
            }
        }

        return (
            homeOdd: homeOdd,
            awayOdd: awayOdd,
            homeLine: homeLine,
            awayLine: awayLine
        )
    }

    private func extractMainTotal(
        from entries: [ESPNCompetitionOdds]
    ) -> (line: Double?, overOdd: Double?, underOdd: Double?) {
        var line: Double?
        var overOdd: Double?
        var underOdd: Double?

        for entry in entries {
            if line == nil {
                line = parseGoalLine(from: entry.total?.over?.close?.line)
                    ?? parseGoalLine(from: entry.total?.over?.open?.line)
                    ?? parseGoalLine(from: entry.total?.under?.close?.line)
                    ?? parseGoalLine(from: entry.total?.under?.open?.line)
                    ?? entry.overUnder.map { normalizeGoalLine($0) }
            }

            if overOdd == nil {
                overOdd = sanitizeOdd(decimalOdd(from: entry.total?.over))
            }

            if underOdd == nil {
                underOdd = sanitizeOdd(decimalOdd(from: entry.total?.under))
            }

            if line != nil, overOdd != nil, underOdd != nil {
                break
            }
        }

        return (
            line: line,
            overOdd: overOdd,
            underOdd: underOdd
        )
    }

    private func buildGoalLines(from entries: [ESPNCompetitionOdds], fallback: Odds) -> [Double: GoalLineOdds] {
        var collected: [Double: PartialGoalLineOdds] = [:]

        for entry in entries {
            guard let extracted = extractGoalLine(from: entry) else { continue }

            var current = collected[extracted.line] ?? PartialGoalLineOdds()
            if current.over == nil {
                current.over = extracted.over
            }
            if current.under == nil {
                current.under = extracted.under
            }
            collected[extracted.line] = current
        }

        var resolved: [Double: GoalLineOdds] = [:]
        for line in trackedGoalLines {
            let key = normalizeGoalLine(line)
            if let market = collected[key], let over = market.over, let under = market.under {
                resolved[key] = (over: over, under: under)
            }
        }

        if let anchor = pickAnchorGoalLine(from: collected),
           let fair = fairProbabilities(overOdd: anchor.over, underOdd: anchor.under),
           let lambda = fitPoissonLambda(
               targetOverProbability: fair.over,
               minimumGoals: minimumGoals(for: anchor.line)
           ) {
            for line in trackedGoalLines {
                let key = normalizeGoalLine(line)
                guard resolved[key] == nil else { continue }

                let overProbability = poissonTailProbability(
                    lambda: lambda,
                    minimumGoals: minimumGoals(for: key)
                )
                let underProbability = max(0.0001, 1.0 - overProbability)

                guard
                    let over = decimalOdd(fromProbability: overProbability, overround: fair.overround),
                    let under = decimalOdd(fromProbability: underProbability, overround: fair.overround)
                else {
                    continue
                }

                resolved[key] = (
                    over: roundToTwoDecimals(over),
                    under: roundToTwoDecimals(under)
                )
            }
        }

        let fallbackLines = fallbackGoalLineOdds(from: fallback)
        for line in trackedGoalLines {
            let key = normalizeGoalLine(line)
            if resolved[key] == nil, let fallbackLine = fallbackLines[key] {
                resolved[key] = fallbackLine
            }
        }

        return resolved
    }

    private func extractGoalLine(from entry: ESPNCompetitionOdds) -> (line: Double, over: Double?, under: Double?)? {
        guard let total = entry.total else { return nil }

        let overLine = parseGoalLine(from: total.over?.close?.line)
            ?? parseGoalLine(from: total.over?.open?.line)
        let underLine = parseGoalLine(from: total.under?.close?.line)
            ?? parseGoalLine(from: total.under?.open?.line)
        let line = overLine ?? underLine ?? entry.overUnder

        guard let line else { return nil }

        let over = sanitizeOdd(decimalOdd(from: total.over))
        let under = sanitizeOdd(decimalOdd(from: total.under))

        return (line: normalizeGoalLine(line), over: over, under: under)
    }

    private func pickAnchorGoalLine(
        from lines: [Double: PartialGoalLineOdds]
    ) -> (line: Double, over: Double, under: Double)? {
        let candidates = lines.compactMap { pair -> (line: Double, over: Double, under: Double)? in
            guard let over = pair.value.over, let under = pair.value.under else { return nil }
            return (line: pair.key, over: over, under: under)
        }

        return candidates.min { lhs, rhs in
            let lhsDistance = abs(lhs.line - 2.5)
            let rhsDistance = abs(rhs.line - 2.5)
            if lhsDistance == rhsDistance {
                return lhs.line < rhs.line
            }
            return lhsDistance < rhsDistance
        }
    }

    private func fairProbabilities(overOdd: Double, underOdd: Double) -> FairProbabilities? {
        guard overOdd > 1.01, underOdd > 1.01 else { return nil }

        let overRaw = 1.0 / overOdd
        let underRaw = 1.0 / underOdd
        let overround = overRaw + underRaw
        guard overround > 0 else { return nil }

        return FairProbabilities(
            over: overRaw / overround,
            overround: max(1.01, min(overround, 1.20))
        )
    }

    private func fitPoissonLambda(targetOverProbability: Double, minimumGoals: Int) -> Double? {
        guard minimumGoals > 0 else { return nil }

        let target = min(max(targetOverProbability, 0.01), 0.99)
        var lower = 0.05
        var upper = 7.0

        while poissonTailProbability(lambda: upper, minimumGoals: minimumGoals) < target, upper < 20 {
            upper *= 1.5
        }

        for _ in 0..<60 {
            let mid = (lower + upper) / 2.0
            let current = poissonTailProbability(lambda: mid, minimumGoals: minimumGoals)
            if current < target {
                lower = mid
            } else {
                upper = mid
            }
        }

        return (lower + upper) / 2.0
    }

    private func poissonTailProbability(lambda: Double, minimumGoals: Int) -> Double {
        guard minimumGoals > 0 else { return 1.0 }
        guard lambda > 0 else { return 0.0 }

        var term = exp(-lambda)
        var cumulative = term

        if minimumGoals == 1 {
            return min(max(1.0 - cumulative, 0.0001), 0.9999)
        }

        for k in 1..<minimumGoals {
            term *= lambda / Double(k)
            cumulative += term
        }

        return min(max(1.0 - cumulative, 0.0001), 0.9999)
    }

    private func decimalOdd(fromProbability probability: Double, overround: Double) -> Double? {
        guard probability > 0, probability < 1 else { return nil }

        let adjustedOverround = max(1.01, min(overround, 1.20))
        let odd = 1.0 / (probability * adjustedOverround)
        guard odd.isFinite else { return nil }

        return max(1.01, min(odd, 100.0))
    }

    private func minimumGoals(for line: Double) -> Int {
        max(1, Int(floor(line + 0.0001)) + 1)
    }

    private func goalLineOdds(
        for line: Double,
        in lines: [Double: GoalLineOdds],
        fallback: GoalLineOdds
    ) -> GoalLineOdds {
        lines[normalizeGoalLine(line)] ?? fallback
    }

    private func fallbackGoalLineOdds(from odds: Odds) -> [Double: GoalLineOdds] {
        [
            normalizeGoalLine(0.5): (over: odds.over05, under: odds.under05),
            normalizeGoalLine(1.5): (over: odds.over15, under: odds.under15),
            normalizeGoalLine(2.5): (over: odds.over25, under: odds.under25),
            normalizeGoalLine(3.5): (over: odds.over35, under: odds.under35),
            normalizeGoalLine(4.5): (over: odds.over45, under: odds.under45)
        ]
    }

    private func decimalOdd(from marketSide: ESPNBetMarketSide?) -> Double? {
        decimalOdd(fromAmericanString: marketSide?.close?.odds)
            ?? decimalOdd(fromAmericanString: marketSide?.open?.odds)
    }

    private func decimalOdd(fromAmericanString value: String?) -> Double? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        let normalized = value.uppercased()
        if normalized == "EVEN" || normalized == "EV" || normalized == "PK" || normalized == "PICK" || normalized == "PICKEM" {
            return 2.0
        }

        if let americanValue = Int(normalized) {
            return decimalOdd(fromAmericanValue: americanValue)
        }

        if let decimalValue = Double(normalized), decimalValue >= 1.01 {
            return decimalValue
        }

        return nil
    }

    private func decimalOdd(fromAmericanValue value: Int) -> Double {
        if value > 0 {
            return 1.0 + (Double(value) / 100.0)
        }

        if value < 0 {
            return 1.0 + (100.0 / Double(abs(value)))
        }

        return 2.0
    }

    private func parseGoalLine(from value: String?) -> Double? {
        guard let value else { return nil }

        let cleaned = value
            .lowercased()
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.-".contains($0) }

        guard !cleaned.isEmpty, let parsed = Double(cleaned), parsed.isFinite else {
            return nil
        }

        return normalizeGoalLine(parsed)
    }

    private func sanitizeOdd(_ odd: Double?) -> Double? {
        guard let odd, odd.isFinite else { return nil }
        guard odd > 1.0 else { return nil }

        return roundToTwoDecimals(min(max(odd, 1.01), 100.0))
    }

    private func combinedOdd(_ first: Double, _ second: Double) -> Double {
        let denominator = (1.0 / first) + (1.0 / second)
        guard denominator > 0 else { return 1.01 }

        return roundToTwoDecimals(max(1.01, 1.0 / denominator))
    }

    private func normalizeGoalLine(_ value: Double) -> Double {
        round(value * 10) / 10
    }

    private func roundToTwoDecimals(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private func estimatedOdds(homeTeam: String, awayTeam: String) -> Odds {
        let (homeOdd, drawOdd, awayOdd) = estimated1x2Odds(homeTeam: homeTeam, awayTeam: awayTeam)

        return Odds(
            home: homeOdd,
            draw: drawOdd,
            away: awayOdd,
            homeDraw: combinedOdd(homeOdd, drawOdd),
            homeAway: combinedOdd(homeOdd, awayOdd),
            drawAway: combinedOdd(drawOdd, awayOdd),
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

    private func estimated1x2Odds(homeTeam: String, awayTeam: String) -> (Double, Double, Double) {
        let homeStrength = teamStrength(homeTeam)
        let awayStrength = teamStrength(awayTeam)
        let diff = homeStrength - awayStrength

        if diff > 0.30 {
            return (1.45, 4.50, 7.00)
        }

        if diff > 0.15 {
            return (1.85, 3.60, 4.20)
        }

        if diff > -0.15 {
            return (2.40, 3.30, 2.90)
        }

        if diff > -0.30 {
            return (3.10, 3.40, 2.25)
        }

        return (5.50, 4.00, 1.55)
    }

    private func teamStrength(_ team: String) -> Double {
        let hash = fnv1a64(team.lowercased())
        return Double(hash % 100) / 100.0
    }

    private func stableUUID(from rawValue: String) -> UUID {
        let hash = fnv1a64(rawValue)
        let p1 = UInt32((hash >> 32) & 0xFFFF_FFFF)
        let p2 = UInt16((hash >> 16) & 0xFFFF)
        let p3 = UInt16(hash & 0xFFFF)
        let p4 = UInt16((hash >> 48) & 0xFFFF)
        let p5 = (hash ^ 0xA5A5_A5A5_A5A5_A5A5) & 0x0000_FFFF_FFFF_FFFF
        let uuidString = String(format: "%08X-%04X-%04X-%04X-%012llX", p1, p2, p3, p4, p5)
        return UUID(uuidString: uuidString) ?? UUID()
    }

    private func fnv1a64(_ value: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    private func parseAPIDate(_ value: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        isoFormatter.formatOptions.insert(.withFractionalSeconds)
        if let date = isoFormatter.date(from: value) {
            return date
        }

        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.timeZone = TimeZone(secondsFromGMT: 0)
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = fallback.date(from: value) {
            return date
        }

        let minutePrecisionFormatter = DateFormatter()
        minutePrecisionFormatter.locale = Locale(identifier: "en_US_POSIX")
        minutePrecisionFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        minutePrecisionFormatter.dateFormat = "yyyy-MM-dd'T'HH:mmZ"
        if let date = minutePrecisionFormatter.date(from: value) {
            return date
        }

        let offsetFormatter = DateFormatter()
        offsetFormatter.locale = Locale(identifier: "en_US_POSIX")
        offsetFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        offsetFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        if let date = offsetFormatter.date(from: value) {
            return date
        }

        offsetFormatter.dateFormat = "yyyy-MM-dd'T'HH:mmXXXXX"
        return offsetFormatter.date(from: value)
    }

    private func scoreboardDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private func displayTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func filterParsedMatches(
        _ parsedMatches: [(kickoff: Date, match: Match)],
        datesQuery: String
    ) -> [(kickoff: Date, match: Match)] {
        guard let range = parseDatesQuery(datesQuery) else {
            return parsedMatches
        }

        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: range.start)
        let startOfEndDate = calendar.startOfDay(for: range.end)
        guard let endExclusive = calendar.date(byAdding: .day, value: 1, to: startOfEndDate) else {
            return parsedMatches
        }

        return parsedMatches.filter { pair in
            pair.kickoff >= startOfStartDate && pair.kickoff < endExclusive
        }
    }

    private func parseDatesQuery(_ datesQuery: String) -> (start: Date, end: Date)? {
        let chunks = datesQuery.split(separator: "-").map(String.init)
        if chunks.isEmpty {
            return nil
        }

        if chunks.count == 1, let date = scoreboardDate(from: chunks[0]) {
            return (date, date)
        }

        if chunks.count == 2,
           let start = scoreboardDate(from: chunks[0]),
           let end = scoreboardDate(from: chunks[1]) {
            return (min(start, end), max(start, end))
        }

        return nil
    }

    private func scoreboardDate(from value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: value)
    }

    private func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct ESPNScoreboardResponse: Decodable {
    let leagues: [ESPNLeague]
    let events: [ESPNEvent]
}

private struct ESPNLeague: Decodable {
    let name: String
}

private struct ESPNEvent: Decodable {
    let id: String
    let date: String
    let status: ESPNStatus
    let competitions: [ESPNCompetition]
}

private struct ESPNStatus: Decodable {
    let type: ESPNStatusType
}

private struct ESPNStatusType: Decodable {
    let state: String?
    let completed: Bool?
}

private struct ESPNCompetition: Decodable {
    let competitors: [ESPNCompetitor]
    let odds: [ESPNCompetitionOdds?]?
}

private struct ESPNCompetitionOdds: Decodable {
    let provider: ESPNOddsProvider?
    let overUnder: Double?
    let drawOdds: ESPNDrawOdds?
    let total: ESPNTotalOddsMarket?
    let moneyline: ESPNMoneylineOddsMarket?
    let pointSpread: ESPNPointSpreadMarket?

    enum CodingKeys: String, CodingKey {
        case provider
        case overUnder
        case drawOdds
        case total
        case moneyline
        case pointSpread
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provider = try container.decodeIfPresent(ESPNOddsProvider.self, forKey: .provider)
        drawOdds = try container.decodeIfPresent(ESPNDrawOdds.self, forKey: .drawOdds)
        total = try container.decodeIfPresent(ESPNTotalOddsMarket.self, forKey: .total)
        moneyline = try container.decodeIfPresent(ESPNMoneylineOddsMarket.self, forKey: .moneyline)
        pointSpread = try container.decodeIfPresent(ESPNPointSpreadMarket.self, forKey: .pointSpread)

        if let value = try? container.decode(Double.self, forKey: .overUnder) {
            overUnder = value
        } else if let value = try? container.decode(Int.self, forKey: .overUnder) {
            overUnder = Double(value)
        } else if let value = try? container.decode(String.self, forKey: .overUnder) {
            overUnder = Double(value.replacingOccurrences(of: ",", with: "."))
        } else {
            overUnder = nil
        }
    }
}

private struct ESPNOddsProvider: Decodable {
    let name: String?
    let priority: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        if let value = try? container.decode(Int.self, forKey: .priority) {
            priority = value
        } else if let value = try? container.decode(String.self, forKey: .priority) {
            priority = Int(value)
        } else {
            priority = nil
        }
    }
}

private struct ESPNDrawOdds: Decodable {
    let moneyLine: Int?

    enum CodingKeys: String, CodingKey {
        case moneyLine
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(Int.self, forKey: .moneyLine) {
            moneyLine = value
        } else if let value = try? container.decode(String.self, forKey: .moneyLine) {
            moneyLine = Int(value)
        } else {
            moneyLine = nil
        }
    }
}

private struct ESPNTotalOddsMarket: Decodable {
    let over: ESPNBetMarketSide?
    let under: ESPNBetMarketSide?
}

private struct ESPNMoneylineOddsMarket: Decodable {
    let home: ESPNBetMarketSide?
    let draw: ESPNBetMarketSide?
    let away: ESPNBetMarketSide?
}

private struct ESPNPointSpreadMarket: Decodable {
    let home: ESPNBetMarketSide?
    let away: ESPNBetMarketSide?
}

private struct ESPNBetMarketSide: Decodable {
    let open: ESPNOddsSnapshot?
    let close: ESPNOddsSnapshot?
}

private struct ESPNOddsSnapshot: Decodable {
    let line: String?
    let odds: String?

    enum CodingKeys: String, CodingKey {
        case line
        case odds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(String.self, forKey: .line) {
            line = value
        } else if let value = try? container.decode(Double.self, forKey: .line) {
            line = String(value)
        } else if let value = try? container.decode(Int.self, forKey: .line) {
            line = String(value)
        } else {
            line = nil
        }

        if let value = try? container.decode(String.self, forKey: .odds) {
            odds = value
        } else if let value = try? container.decode(Double.self, forKey: .odds) {
            odds = String(value)
        } else if let value = try? container.decode(Int.self, forKey: .odds) {
            odds = String(value)
        } else {
            odds = nil
        }
    }
}

private struct ESPNCompetitor: Decodable {
    let homeAway: String
    let score: String?
    let team: ESPNTeam
}

private struct ESPNTeam: Decodable {
    let displayName: String
}
