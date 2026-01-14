//
//  ContentView.swift
//  SportPredix
//
//  Created by Formatiks Team on 12/01/26.
//


import SwiftUI

// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

// MARK: - MODELS

enum MatchOutcome: String, CaseIterable {
    case home = "1"
    case draw = "X"
    case away = "2"
}

struct Match: Identifiable {
    let id = UUID()
    let home: String
    let away: String
    let time: String
    let odds: [Double]
}

struct Bet: Identifiable {
    let id = UUID()
    let match: Match
    let outcome: MatchOutcome
    let amount: Double
}

// MARK: - MAIN VIEW

struct ContentView: View {

    // MARK: STATE

    @State private var selectedDay = 2
    @State private var selectedTab = 0
    @State private var balance: Double = UserDefaults.standard.double(forKey: "balance") == 0 ? 1000 : UserDefaults.standard.double(forKey: "balance")
    @State private var bets: [Bet] = []

    // MARK: DATA

    private let days = ["LIVE", "MAR\n13", "OGGI\n14", "GIO\n15", "VEN\n16"]

    private let matchesByDay: [[Match]] = [
        [],
        [],
        [
            Match(home: "Napoli", away: "Parma", time: "18:30", odds: [1.60, 3.90, 5.50]),
            Match(home: "Inter", away: "Lecce", time: "20:45", odds: [1.40, 4.20, 7.00]),
            Match(home: "Roma", away: "Udinese", time: "21:00", odds: [1.90, 3.60, 4.00])
        ],
        [],
        []
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                calendar
                content
                bottomBar
            }
        }
        .onChange(of: balance) {
            UserDefaults.standard.set($0, forKey: "balance")
        }
    }

    // MARK: - HEADER

    private var header: some View {
        HStack {
            Text("Calendario")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Spacer()

            Text("$\(balance, specifier: "%.2f")")
                .fontWeight(.bold)
                .foregroundColor(.accentCyan)
        }
        .padding()
    }

    // MARK: - CALENDAR

    private var calendar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days.indices, id: \.self) { index in
                    Text(days[index])
                        .multilineTextAlignment(.center)
                        .fontWeight(.bold)
                        .foregroundColor(selectedDay == index ? .black : .white)
                        .frame(width: 70, height: 60)
                        .background(
                            selectedDay == index
                            ? Color.accentCyan
                            : Color.white.opacity(0.1)
                        )
                        .cornerRadius(14)
                        .onTapGesture {
                            selectedDay = index
                        }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - CONTENT

    private var content: some View {
        ScrollView {
            if selectedTab == 0 {
                serieASection
            } else {
                betsSection
            }
        }
    }

    // MARK: - SERIE A

    private var serieASection: some View {
        VStack(spacing: 16) {
            DisclosureGroup {
                VStack(spacing: 12) {
                    ForEach(matchesByDay[selectedDay]) { match in
                        matchCard(match)
                    }

                    if matchesByDay[selectedDay].isEmpty {
                        Text("Nessuna partita")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            } label: {
                HStack {
                    Text("Serie A")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Text("Italia")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
        .padding()
    }

    private func matchCard(_ match: Match) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(match.home)
                Spacer()
                Text(match.time).bold()
                Spacer()
                Text(match.away)
            }
            .foregroundColor(.white)

            HStack(spacing: 12) {
                oddsButton("1", match.odds[0]) {
                    placeBet(match, .home)
                }
                oddsButton("X", match.odds[1]) {
                    placeBet(match, .draw)
                }
                oddsButton("2", match.odds[2]) {
                    placeBet(match, .away)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }

    private func oddsButton(_ title: String, _ odd: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Text(title).bold()
                Text(String(format: "%.2f", odd))
                    .font(.caption)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.accentCyan)
            .cornerRadius(10)
        }
    }

    // MARK: - BETS

    private var betsSection: some View {
        VStack(spacing: 12) {
            if bets.isEmpty {
                Text("Nessuna schedina")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(bets) { bet in
                    Text("\(bet.match.home) vs \(bet.match.away) – \(bet.outcome.rawValue) – $\(bet.amount)")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(14)
                }
            }
        }
        .padding()
    }

    // MARK: - BOTTOM BAR

    private var bottomBar: some View {
        HStack {
            bottomItem("calendar", "Calendario", 0)
            Spacer()
            bottomItem("list.bullet", "Piazzate", 1)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(26)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func bottomItem(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack {
                Image(systemName: icon)
                Text(title).font(.caption)
            }
            .foregroundColor(selectedTab == index ? .accentCyan : .white)
        }
    }

    // MARK: - LOGIC

    private func placeBet(_ match: Match, _ outcome: MatchOutcome) {
        let amount = 10.0
        guard balance >= amount else { return }

        balance -= amount
        bets.append(Bet(match: match, outcome: outcome, amount: amount))
    }
}

// MARK: - PREVIEW

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
