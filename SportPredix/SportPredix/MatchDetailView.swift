import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @ObservedObject var vm: BettingViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("\(match.home) vs \(match.away)")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Orario: \(match.time)")
                    .foregroundColor(.accentCyan)

                ScrollView {
                    VStack(spacing: 16) {
                        oddsSection(title: "1X2", odds: [
                            ("1", .home, match.odds.home),
                            ("X", .draw, match.odds.draw),
                            ("2", .away, match.odds.away)
                        ])

                        oddsSection(title: "Doppie Chance", odds: [
                            ("1X", .homeDraw, match.odds.homeDraw),
                            ("12", .homeAway, match.odds.homeAway),
                            ("X2", .drawAway, match.odds.drawAway)
                        ])

                        oddsSection(title: "Over/Under 2.5", odds: [
                            ("Over 2.5", .over25, match.odds.over25),
                            ("Under 2.5", .under25, match.odds.under25)
                        ])
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func oddsSection(title: String, odds: [(String, MatchOutcome, Double)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(odds, id: \.0) { item in
                    Button {
                        vm.addPick(match: match, outcome: item.1, odd: item.2)
                    } label: {
                        VStack {
                            Text(item.0).bold()
                            Text(String(format: "%.2f", item.2))
                                .font(.caption)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.accentCyan)
                        .cornerRadius(14)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }
}