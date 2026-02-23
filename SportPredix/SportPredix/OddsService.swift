//
//  OddsService.swift
//  SportPredix
//

import Foundation

final class OddsService {
    static let shared = OddsService()
    private init() {}

    private let baseURL = "https://site.api.espn.com/apis/site/v2/sports/soccer/ita.1/scoreboard"

    func fetchSerieAOdths(for date: Date = Date(), completion: @escaping (Result<[Match], Error>) -> Void) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            let error = NSError(
                domain: "Matches API",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "URL non valida"]
            )
            completion(.failure(error))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "dates", value: scoreboardDateString(from: date))
        ]

        guard let url = urlComponents.url else {
            let error = NSError(
                domain: "Matches API",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Impossibile creare URL"]
            )
            completion(.failure(error))
            return
        }

        print("Fetching real matches from API: \(url.absoluteString)")

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
                let decoder = JSONDecoder()
                let response = try decoder.decode(ESPNScoreboardResponse.self, from: data)
                let competitionName = response.leagues.first?.name ?? "Serie A"

                let matches = response.events
                    .compactMap { self.convertESPNEvent($0, competitionName: competitionName) }
                    .sorted { $0.kickoff < $1.kickoff }
                    .map(\.match)

                DispatchQueue.main.async {
                    completion(.success(matches))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
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
        let odds = estimatedOdds(homeTeam: home.team.displayName, awayTeam: away.team.displayName)
        let status = normalizedStatus(from: event.status.type)

        let homeScore = Int(home.score ?? "")
        let awayScore = Int(away.score ?? "")
        let goals: Int?
        let actualResult: String?
        if let homeScore = homeScore, let awayScore = awayScore {
            goals = homeScore + awayScore
            actualResult = "\(homeScore)-\(awayScore)"
        } else {
            goals = nil
            actualResult = nil
        }

        var result: MatchOutcome?
        if status == "FINISHED", let homeScore = homeScore, let awayScore = awayScore {
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

    private func estimatedOdds(homeTeam: String, awayTeam: String) -> Odds {
        let (homeOdd, drawOdd, awayOdd) = estimated1x2Odds(homeTeam: homeTeam, awayTeam: awayTeam)

        return Odds(
            home: homeOdd,
            draw: drawOdd,
            away: awayOdd,
            homeDraw: 1.0 / ((1.0 / homeOdd) + (1.0 / drawOdd)),
            homeAway: 1.0 / ((1.0 / homeOdd) + (1.0 / awayOdd)),
            drawAway: 1.0 / ((1.0 / drawOdd) + (1.0 / awayOdd)),
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
        return fallback.date(from: value)
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
}

private struct ESPNCompetitor: Decodable {
    let homeAway: String
    let score: String?
    let team: ESPNTeam
}

private struct ESPNTeam: Decodable {
    let displayName: String
}
