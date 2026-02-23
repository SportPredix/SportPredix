//
//  Models.swift
//  SportPredix
//

import Foundation

// MARK: - MODELLI BETSTACK API (rimossi i duplicati)

struct BetstackAPIResponse: Decodable {
    let success: Bool
    let data: [BetstackMatch]
    let meta: BetstackMeta?
}

struct BetstackMatch: Decodable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let startTime: String
    let league: String
    let status: String
    let odds: [BetstackOddsData]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case startTime = "start_time"
        case league, status, odds
    }
}

struct BetstackOddsData: Decodable {
    let market: String
    let outcome: String
    let price: Double
    let line: Double?
    let provider: String?
}

struct BetstackMeta: Decodable {
    let total: Int
    let page: Int
    let perPage: Int
}

// MARK: - MODELLI APP PRINCIPALI

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
    let apiProvider: String?
    let apiMainTotalLine: Double?
    let apiMainOver: Double?
    let apiMainUnder: Double?
    let handicapHome: Double?
    let handicapAway: Double?
    let handicapHomeLine: Double?
    let handicapAwayLine: Double?
    
    enum CodingKeys: String, CodingKey {
        case home, draw, away
        case homeDraw = "home_draw"
        case homeAway = "home_away"
        case drawAway = "draw_away"
        case over05 = "over_05"
        case under05 = "under_05"
        case over15 = "over_15"
        case under15 = "under_15"
        case over25 = "over_25"
        case under25 = "under_25"
        case over35 = "over_35"
        case under35 = "under_35"
        case over45 = "over_45"
        case under45 = "under_45"
        case apiProvider = "api_provider"
        case apiMainTotalLine = "api_main_total_line"
        case apiMainOver = "api_main_over"
        case apiMainUnder = "api_main_under"
        case handicapHome = "handicap_home"
        case handicapAway = "handicap_away"
        case handicapHomeLine = "handicap_home_line"
        case handicapAwayLine = "handicap_away_line"
    }

    init(
        home: Double,
        draw: Double,
        away: Double,
        homeDraw: Double,
        homeAway: Double,
        drawAway: Double,
        over05: Double,
        under05: Double,
        over15: Double,
        under15: Double,
        over25: Double,
        under25: Double,
        over35: Double,
        under35: Double,
        over45: Double,
        under45: Double,
        apiProvider: String? = nil,
        apiMainTotalLine: Double? = nil,
        apiMainOver: Double? = nil,
        apiMainUnder: Double? = nil,
        handicapHome: Double? = nil,
        handicapAway: Double? = nil,
        handicapHomeLine: Double? = nil,
        handicapAwayLine: Double? = nil
    ) {
        self.home = home
        self.draw = draw
        self.away = away
        self.homeDraw = homeDraw
        self.homeAway = homeAway
        self.drawAway = drawAway
        self.over05 = over05
        self.under05 = under05
        self.over15 = over15
        self.under15 = under15
        self.over25 = over25
        self.under25 = under25
        self.over35 = over35
        self.under35 = under35
        self.over45 = over45
        self.under45 = under45
        self.apiProvider = apiProvider
        self.apiMainTotalLine = apiMainTotalLine
        self.apiMainOver = apiMainOver
        self.apiMainUnder = apiMainUnder
        self.handicapHome = handicapHome
        self.handicapAway = handicapAway
        self.handicapHomeLine = handicapHomeLine
        self.handicapAwayLine = handicapAwayLine
    }
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
    var actualResult: String?
    
    init(id: UUID, home: String, away: String, time: String, odds: Odds, 
         result: MatchOutcome? = nil, goals: Int? = nil, competition: String, 
         status: String, actualResult: String? = nil) {
        self.id = id
        self.home = home
        self.away = away
        self.time = time
        self.odds = odds
        self.result = result
        self.goals = goals
        self.competition = competition
        self.status = status
        self.actualResult = actualResult
    }
}

struct BetPick: Identifiable, Codable {
    let id: UUID
    let match: Match
    let outcome: MatchOutcome
    let odd: Double
    
    init(id: UUID = UUID(), match: Match, outcome: MatchOutcome, odd: Double) {
        self.id = id
        self.match = match
        self.outcome = outcome
        self.odd = odd
    }
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
    
    var impliedProbability: Double { 
        guard totalOdd > 0 else { return 0 }
        return 1 / totalOdd 
    }
    
    var expectedValue: Double { 
        potentialWin * impliedProbability - stake 
    }
    
    init(id: UUID = UUID(), picks: [BetPick], stake: Double, totalOdd: Double, 
         potentialWin: Double, date: Date = Date(), isWon: Bool? = nil, isEvaluated: Bool = false) {
        self.id = id
        self.picks = picks
        self.stake = stake
        self.totalOdd = totalOdd
        self.potentialWin = potentialWin
        self.date = date
        self.isWon = isWon
        self.isEvaluated = isEvaluated
    }
}
