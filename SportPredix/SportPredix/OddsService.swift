//
//  OddsService.swift
//  SportPredix
//

import Foundation

final class OddsService {
    static let shared = OddsService()
    private init() {}

    // SOSTITUISCI CON LA TUA CHIAVE API DI BETSTACK
    private let apiKey = "0a153bf2e76766c911e68212b6b02844c6c3c289f4f545b4481f2a4350deadf1"
    private let baseURL = "https://betstack.dev/api/v1"

    func fetchSerieAOdds(completion: @escaping (Result<[Match], Error>) -> Void) {
        // Endpoint per le partite di Serie A da Betstack
        // Questo è un endpoint di esempio, verifica la documentazione ufficiale
        let urlString = "\(baseURL)/matches?league=serie_a&status=scheduled"
        
        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL non valida"])))
            return
        }
        
        // Aggiungi parametri API
        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "include", value: "odds"),
            URLQueryItem(name: "limit", value: "20") // Limita a 20 partite per la demo
        ]
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Impossibile creare URL"])))
            return
        }

        print("📡 Fetching from Betstack API: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        // Se Betstack usa Bearer token:
        // request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Gestione errori di rete
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { 
                    completion(.failure(error))
                }
                return
            }
            
            // Controlla status code HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "HTTP Error", code: httpResponse.statusCode, 
                                      userInfo: [NSLocalizedDescriptionKey: "HTTP Status: \(httpResponse.statusCode)"])
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }
            }

            guard let data = data else {
                let error = NSError(domain: "No Data", code: 404, 
                                  userInfo: [NSLocalizedDescriptionKey: "Nessun dato ricevuto"])
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            // DEBUG: Stampa la risposta JSON per debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Betstack RAW Response (primi 500 caratteri):")
                print(String(jsonString.prefix(500)))
            }

            do {
                // Prova a decodificare la risposta Betstack
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // Struttura attesa dalla documentazione Betstack
                let betstackResponse = try decoder.decode(BetstackAPIResponse.self, from: data)
                
                // Converti le partite Betstack nel formato dell'app
                let matches = betstackResponse.data.compactMap { betstackMatch -> Match? in
                    return self.convertBetstackMatch(betstackMatch)
                }
                
                print("✅ Successfully converted \(matches.count) matches from Betstack")
                
                DispatchQueue.main.async {
                    completion(.success(matches))
                }
                
            } catch let decodingError as DecodingError {
                print("❌ JSON Decoding Error: \(decodingError)")
                
                // Fallback: Genera partite simulate
                print("🔄 Using simulated matches as fallback")
                DispatchQueue.main.async {
                    let simulatedMatches = self.generateFallbackMatches()
                    completion(.success(simulatedMatches))
                }
                
            } catch {
                print("❌ Unknown error: \(error)")
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
    
    private func convertBetstackMatch(_ betstackMatch: BetstackMatch) -> Match {
        // Estrai gli odds dalla risposta Betstack
        let homeOdds = betstackMatch.odds?.first { $0.market == "1x2" && $0.outcome == "home" }?.price ?? 2.0
        let drawOdds = betstackMatch.odds?.first { $0.market == "1x2" && $0.outcome == "draw" }?.price ?? 3.5
        let awayOdds = betstackMatch.odds?.first { $0.market == "1x2" && $0.outcome == "away" }?.price ?? 3.0
        
        // Crea odds per altri mercati (usa calcoli realistici come fallback)
        let odds = Odds(
            home: homeOdds,
            draw: drawOdds,
            away: awayOdds,
            homeDraw: 1.0 / ((1.0/homeOdds) + (1.0/drawOdds)),
            homeAway: 1.0 / ((1.0/homeOdds) + (1.0/awayOdds)),
            drawAway: 1.0 / ((1.0/drawOdds) + (1.0/awayOdds)),
            over05: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "over" && $0.line == 0.5 }?.price ?? 1.12,
            under05: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "under" && $0.line == 0.5 }?.price ?? 6.50,
            over15: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "over" && $0.line == 1.5 }?.price ?? 1.45,
            under15: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "under" && $0.line == 1.5 }?.price ?? 2.65,
            over25: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "over" && $0.line == 2.5 }?.price ?? 1.95,
            under25: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "under" && $0.line == 2.5 }?.price ?? 1.85,
            over35: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "over" && $0.line == 3.5 }?.price ?? 2.80,
            under35: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "under" && $0.line == 3.5 }?.price ?? 1.40,
            over45: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "over" && $0.line == 4.5 }?.price ?? 4.50,
            under45: betstackMatch.odds?.first { $0.market == "total_goals" && $0.outcome == "under" && $0.line == 4.5 }?.price ?? 1.18
        )
        
        // Formatta l'ora di inizio
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        
        var displayTime = "TBD"
        if let date = dateFormatter.date(from: betstackMatch.startTime) {
            displayTime = displayFormatter.string(from: date)
        }
        
        return Match(
            id: UUID(uuidString: betstackMatch.id) ?? UUID(),
            home: betstackMatch.homeTeam,
            away: betstackMatch.awayTeam,
            time: displayTime,
            odds: odds,
            result: nil,
            goals: nil,
            competition: betstackMatch.league,
            status: betstackMatch.status.capitalized,
            actualResult: nil
        )
    }
    
    private func generateFallbackMatches() -> [Match] {
        // Partite simulate di Serie A italiane
        let serieATeams = [
            ("Inter", "Milano"),
            ("Juventus", "Torino"),
            ("Milan", "Milano"),
            ("Napoli", "Napoli"),
            ("Roma", "Roma"),
            ("Lazio", "Roma"),
            ("Atalanta", "Bergamo"),
            ("Fiorentina", "Firenze"),
            ("Bologna", "Bologna"),
            ("Torino", "Torino")
        ]
        
        var matches: [Match] = []
        let now = Date()
        let calendar = Calendar.current
        
        for i in 0..<8 {
            let homeIndex = Int.random(in: 0..<serieATeams.count)
            var awayIndex = Int.random(in: 0..<serieATeams.count)
            while awayIndex == homeIndex { awayIndex = Int.random(in: 0..<serieATeams.count) }
            
            let matchDate = calendar.date(byAdding: .hour, value: i * 3, to: now) ?? now
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let matchTime = timeFormatter.string(from: matchDate)
            
            let (homeOdd, drawOdd, awayOdd) = generateRealisticOdds(
                homeTeam: serieATeams[homeIndex].0,
                awayTeam: serieATeams[awayIndex].0
            )
            
            let odds = Odds(
                home: homeOdd,
                draw: drawOdd,
                away: awayOdd,
                homeDraw: 1.0 / ((1.0/homeOdd) + (1.0/drawOdd)),
                homeAway: 1.0 / ((1.0/homeOdd) + (1.0/awayOdd)),
                drawAway: 1.0 / ((1.0/drawOdd) + (1.0/awayOdd)),
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
            
            let match = Match(
                id: UUID(),
                home: serieATeams[homeIndex].0,
                away: serieATeams[awayIndex].0,
                time: matchTime,
                odds: odds,
                result: nil,
                goals: nil,
                competition: "Serie A",
                status: "SCHEDULED",
                actualResult: nil
            )
            
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateRealisticOdds(homeTeam: String, awayTeam: String) -> (Double, Double, Double) {
        // Simula odds realistiche basate su forza squadre
        let homeStrength = Double(homeTeam.hash % 100) / 100.0
        let awayStrength = Double(awayTeam.hash % 100) / 100.0
        let diff = homeStrength - awayStrength
        
        if diff > 0.3 {
            return (1.45, 4.50, 7.00) // Forte favorito casa
        } else if diff > 0.15 {
            return (1.85, 3.60, 4.20) // Leggero favorito casa
        } else if diff > -0.15 {
            return (2.40, 3.30, 2.90) // Partita equilibrata
        } else if diff > -0.3 {
            return (3.10, 3.40, 2.25) // Leggero favorito fuori
        } else {
            return (5.50, 4.00, 1.55) // Forte favorito fuori
        }
    }
}

// MARK: - Modelli per Betstack API
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