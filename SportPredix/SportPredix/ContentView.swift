//
//  ContentView.swift
//  SportPredix
//
//  Created by Francesco on 12/01/26.
//


import SwiftUI

// MARK: - MODELS

enum MatchOutcome: String, CaseIterable, Identifiable {
    case homeWin = "Home"
    case draw = "Draw"
    case awayWin = "Away"

    var id: String { rawValue }

    var index: Int {
        switch self {
        case .homeWin: return 0
        case .draw: return 1
        case .awayWin: return 2
        }
    }
}

struct Match: Identifiable {
    let id = UUID()
    let homeTeam: String
    let awayTeam: String
    let odds: [Double]
}

struct Bet: Identifiable {
    let id = UUID()
    let match: Match
    let outcome: MatchOutcome
    let amount: Double
}

// MARK: - VIEW

struct ContentView: View {

    @State private var balance: Double = 1000.0
    @State private var matches: [Match] = [
        Match(homeTeam: "Team A", awayTeam: "Team B", odds: [2.0, 3.5, 4.0]),
        Match(homeTeam: "Team C", awayTeam: "Team D", odds: [1.8, 3.2, 5.0]),
        Match(homeTeam: "Team E", awayTeam: "Team F", odds: [2.5, 3.0, 3.5])
    ]
    @State private var placedBets: [Bet] = []

    var body: some View {
        TabView {

            // MARK: - OGGI
            NavigationView {
                VStack {
                    List(matches) { match in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(match.homeTeam) vs \(match.awayTeam)")
                                .font(.headline)

                            HStack {
                                Button("Home (\(match.odds[0], specifier: "%.1f"))") {
                                    placeBet(match: match, outcome: .homeWin)
                                }
                                Button("Draw (\(match.odds[1], specifier: "%.1f"))") {
                                    placeBet(match: match, outcome: .draw)
                                }
                                Button("Away (\(match.odds[2], specifier: "%.1f"))") {
                                    placeBet(match: match, outcome: .awayWin)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Button("Simulate Results") {
                        simulateResults()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .toolbar {
                    toolbarContent
                }
            }
            .tabItem {
                Label("Oggi", systemImage: "calendar")
            }

            // MARK: - PIAZZATE
            NavigationView {
                VStack {
                    if placedBets.isEmpty {
                        Text("Nessuna scommessa piazzata")
                            .font(.headline)
                            .padding()
                    } else {
                        List(placedBets) { bet in
                            Text(
                                "\(bet.match.homeTeam) vs \(bet.match.awayTeam) – \(bet.outcome.rawValue) – $\(bet.amount)"
                            )
                        }
                    }
                }
                .toolbar {
                    toolbarContent
                }
            }
            .tabItem {
                Label("Piazzate", systemImage: "list.bullet")
            }

            // MARK: - LEGHE
            NavigationView {
                VStack {
                    Text("Leghe")
                        .font(.largeTitle)
                        .padding()

                    Text("Funzionalità in arrivo…")
                        .foregroundColor(.gray)
                }
                .toolbar {
                    toolbarContent
                }
            }
            .tabItem {
                Label("Leghe", systemImage: "trophy")
            }

            // MARK: - PROFILO
            NavigationView {
                VStack {
                    Text("Profilo")
                        .font(.largeTitle)
                        .padding()

                    Text("Scommesse piazzate: \(placedBets.count)")
                        .font(.title2)
                }
                .toolbar {
                    toolbarContent
                }
            }
            .tabItem {
                Label("Profilo", systemImage: "person")
            }
        }
    }

    // MARK: - TOOLBAR (FIXED PER IPA BUILD)

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("SportPredix")
                .font(.headline)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Text("$\(balance, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(.green)
        }
    }

    // MARK: - LOGIC

    private func placeBet(match: Match, outcome: MatchOutcome) {
        let betAmount = 10.0
        guard balance >= betAmount else { return }

        balance -= betAmount
        placedBets.append(
            Bet(match: match, outcome: outcome, amount: betAmount)
        )
    }

    private func simulateResults() {
        for bet in placedBets {
            let result = MatchOutcome.allCases.randomElement()!
            if result == bet.outcome {
                let winnings = bet.amount * bet.match.odds[bet.outcome.index]
                balance += winnings
            }
        }
        placedBets.removeAll()
    }
}

// MARK: - PREVIEW (XCODE VECCHIO OK)

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
