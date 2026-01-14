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

enum MatchOutcome: String {
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

struct BetPick: Identifiable {
    let id = UUID()
    let match: Match
    let outcome: MatchOutcome
    let odd: Double
}

struct BetSlip: Identifiable {
    let id = UUID()
    let picks: [BetPick]
    let stake: Double
    let totalOdd: Double
    let potentialWin: Double
}

// MARK: - MAIN VIEW

struct ContentView: View {

    // STATE
    @State private var selectedDay = 2
    @State private var selectedTab = 0
    @State private var showBetSheet = false

    @State private var balance: Double =
        UserDefaults.standard.double(forKey: "balance") == 0 ? 1000 :
        UserDefaults.standard.double(forKey: "balance")

    @State private var currentSlip: [BetPick] = []
    @State private var history: [BetSlip] = []

    // DATA
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
        .sheet(isPresented: $showBetSheet) {
            BetSheet(
                picks: currentSlip,
                balance: balance
            ) { stake, totalOdd in
                confirmBet(stake: stake, totalOdd: totalOdd)
            }
        }
    }

    // MARK: HEADER

    private var header: some View {
        HStack {
            Text("Calendario")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Spacer()

            Text("$\(balance, specifier: "%.2f")")
                .foregroundColor(.accentCyan)
                .bold()
        }
        .padding()
    }

    // MARK: CALENDAR

    private var calendar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days.indices, id: \.self) { i in
                    Text(days[i])
                        .multilineTextAlignment(.center)
                        .foregroundColor(selectedDay == i ? .black : .white)
                        .frame(width: 70, height: 60)
                        .background(selectedDay == i ? Color.accentCyan : Color.white.opacity(0.1))
                        .cornerRadius(14)
                        .onTapGesture { selectedDay = i }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: CONTENT

    private var content: some View {
        ScrollView {
            if selectedTab == 0 {
                serieASection
                if !currentSlip.isEmpty {
                    continueButton
                }
            } else {
                historySection
            }
        }
    }

    // MARK: SERIE A

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
                    Text("Serie A").foregroundColor(.white).bold()
                    Spacer()
                    Text("Italia").foregroundColor(.gray)
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

            HStack(spacing: 10) {
                pickButton("1", match, .home, match.odds[0])
                pickButton("X", match, .draw, match.odds[1])
                pickButton("2", match, .away, match.odds[2])
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }

    private func pickButton(_ label: String, _ match: Match, _ outcome: MatchOutcome, _ odd: Double) -> some View {
        Button {
            if !currentSlip.contains(where: { $0.match.id == match.id }) {
                currentSlip.append(BetPick(match: match, outcome: outcome, odd: odd))
            }
        } label: {
            VStack {
                Text(label).bold()
                Text(String(format: "%.2f", odd)).font(.caption)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.accentCyan)
            .cornerRadius(10)
        }
    }

    // MARK: CONTINUE BUTTON

    private var continueButton: some View {
        Button {
            showBetSheet = true
        } label: {
            Text("Continua")
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentCyan)
                .cornerRadius(16)
                .padding()
        }
    }

    // MARK: HISTORY

    private var historySection: some View {
        VStack(spacing: 12) {
            if history.isEmpty {
                Text("Nessuna schedina")
                    .foregroundColor(.gray)
            } else {
                ForEach(history) { slip in
                    VStack(alignment: .leading) {
                        Text("Puntata $\(slip.stake)")
                            .foregroundColor(.white)
                        Text("Quota \(String(format: "%.2f", slip.totalOdd))")
                            .foregroundColor(.accentCyan)
                        Text("Possibile vincita $\(String(format: "%.2f", slip.potentialWin))")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                }
            }
        }
        .padding()
    }

    // MARK: BOTTOM BAR

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

    // MARK: LOGIC

    private func confirmBet(stake: Double, totalOdd: Double) {
        guard balance >= stake else { return }

        balance -= stake
        history.append(
            BetSlip(
                picks: currentSlip,
                stake: stake,
                totalOdd: totalOdd,
                potentialWin: stake * totalOdd
            )
        )
        currentSlip.removeAll()
    }
}

// MARK: - BET SHEET

struct BetSheet: View {

    let picks: [BetPick]
    let balance: Double
    let onConfirm: (Double, Double) -> Void

    @State private var stake: Double = 10

    private var totalOdd: Double {
        picks.map { $0.odd }.reduce(1, *)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.gray)
                    .frame(width: 40, height: 5)

                Text("Schedina")
                    .foregroundColor(.white)
                    .font(.headline)

                ForEach(picks) { pick in
                    Text("\(pick.match.home) - \(pick.match.away) | \(pick.outcome.rawValue)")
                        .foregroundColor(.white)
                        .font(.caption)
                }

                VStack(spacing: 8) {
                    Text("Quota totale: \(String(format: "%.2f", totalOdd))")
                        .foregroundColor(.accentCyan)

                    Text("Puntata: $\(stake, specifier: "%.0f")")
                        .foregroundColor(.white)

                    Slider(value: $stake, in: 1...min(balance, 500), step: 1)
                        .accentColor(.accentCyan)

                    Text("Possibile vincita $\(stake * totalOdd, specifier: "%.2f")")
                        .foregroundColor(.gray)
                }

                Button("Conferma puntata") {
                    onConfirm(stake, totalOdd)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentCyan)
                .foregroundColor(.black)
                .cornerRadius(16)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - PREVIEW

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
