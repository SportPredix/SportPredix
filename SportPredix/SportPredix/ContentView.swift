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

// MARK: - MAIN VIEW

struct ContentView: View {

    @State private var selectedDay = 2
    @State private var showSheet = false

    @State private var balance: Double =
        UserDefaults.standard.double(forKey: "balance") == 0 ? 1000 :
        UserDefaults.standard.double(forKey: "balance")

    @State private var picks: [BetPick] = []

    private let days = ["LIVE", "MAR\n13", "OGGI\n14", "GIO\n15", "VEN\n16"]

    private let matches: [Match] = [
        Match(home: "Napoli", away: "Parma", time: "18:30", odds: [1.33, 4.20, 7.00]),
        Match(home: "Inter", away: "Lecce", time: "20:45", odds: [1.19, 5.00, 10.0]),
        Match(home: "Colonia", away: "Bayern Monaco", time: "20:30", odds: [6.50, 4.80, 1.24]),
        Match(home: "Albacete", away: "Real Madrid", time: "21:00", odds: [9.00, 6.20, 1.24])
    ]

    var totalOdd: Double {
        picks.map { $0.odd }.reduce(1, *)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                calendar
                matchList
            }

            if !picks.isEmpty {
                floatingBetButton
            }
        }
        .sheet(isPresented: $showSheet) {
            BetSheet(
                picks: $picks,
                balance: $balance,
                totalOdd: totalOdd
            )
        }
        .onChange(of: balance) {
            UserDefaults.standard.set($0, forKey: "balance")
        }
    }

    // MARK: HEADER

    private var header: some View {
        HStack {
            Text("Calendario")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Spacer()

            Text("€\(balance, specifier: "%.2f")")
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

    // MARK: MATCH LIST

    private var matchList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(matches) { match in
                    VStack(spacing: 10) {
                        HStack {
                            Text(match.home)
                            Spacer()
                            Text(match.time).bold()
                            Spacer()
                            Text(match.away)
                        }
                        .foregroundColor(.white)

                        HStack(spacing: 10) {
                            oddButton("1", match, .home, match.odds[0])
                            oddButton("X", match, .draw, match.odds[1])
                            oddButton("2", match, .away, match.odds[2])
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
    }

    private func oddButton(_ label: String, _ match: Match, _ outcome: MatchOutcome, _ odd: Double) -> some View {
        Button {
            if !picks.contains(where: { $0.match.id == match.id }) {
                picks.append(BetPick(match: match, outcome: outcome, odd: odd))
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
            .cornerRadius(12)
        }
    }

    // MARK: FLOATING BUTTON

    private var floatingBetButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showSheet = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet.rectangle")
                        Text("\(picks.count)")
                            .font(.caption.bold())
                        Text("\(totalOdd, specifier: "%.2f")x")
                            .font(.caption2)
                    }
                    .foregroundColor(.black)
                    .padding(14)
                    .background(Color.accentCyan)
                    .clipShape(Circle())
                    .shadow(radius: 10)
                }
                .padding()
            }
        }
    }
}

// MARK: - BET SHEET

struct BetSheet: View {

    @Binding var picks: [BetPick]
    @Binding var balance: Double
    let totalOdd: Double

    @State private var stake: Double = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.gray)
                    .frame(width: 40, height: 5)

                HStack {
                    Text("La tua selezione")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Text("Quota totale: \(totalOdd, specifier: "%.2f")")
                        .foregroundColor(.accentCyan)
                        .font(.caption)
                }

                ForEach(picks) { pick in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(pick.match.home) - \(pick.match.away)")
                                .foregroundColor(.white)
                            Text("1x2 - \(pick.outcome.rawValue)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        Spacer()
                        Text(String(format: "%.2f", pick.odd))
                            .foregroundColor(.white)
                        Button {
                            picks.removeAll { $0.id == pick.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                }

                Button("Rimuovi tutto") {
                    picks.removeAll()
                }
                .foregroundColor(.red)

                VStack(spacing: 8) {
                    Text("Importo €\(stake, specifier: "%.2f")")
                        .foregroundColor(.white)

                    Slider(value: $stake, in: 1...min(balance, 500), step: 1)
                        .accentColor(.accentCyan)

                    Text("Vincita potenziale €\(stake * totalOdd, specifier: "%.2f")")
                        .foregroundColor(.accentCyan)
                }

                Button("Conferma selezione") {
                    guard balance >= stake else { return }
                    balance -= stake
                    picks.removeAll()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(16)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: PREVIEW

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
