//
//  MatchDetailsView.swift
//  SportPredix
//
//  Created by Francesco on 16/01/26.
//

import SwiftUI

struct MatchDetailView: View {
    let match: Match
    @ObservedObject var vm: BettingViewModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedTab = 0

    private let tabOptions = ["Tutte", "1X2", "Doppia", "Over/Under", "Handicap", "API"]

    var body: some View {
        ZStack {
            background

            VStack(spacing: 12) {
                headerCard
                tabBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if selectedTab == 0 {
                            odds1X2Section
                            oddsDoubleChanceSection
                            oddsOverUnderSection
                            apiSnapshotSection
                            handicapSection
                        } else if selectedTab == 1 {
                            odds1X2Section
                        } else if selectedTab == 2 {
                            oddsDoubleChanceSection
                        } else if selectedTab == 3 {
                            oddsOverUnderSection
                        } else if selectedTab == 4 {
                            handicapSection
                        } else {
                            apiSnapshotSection
                            handicapSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 6)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.11), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [Color.accentCyan.opacity(0.18), Color.clear]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentCyan)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(match.time)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentCyan)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }

            Text("\(match.home) - \(match.away)")
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                badge(text: match.competition.uppercased(), color: .accentCyan, textColor: .black)
                badge(text: match.status, color: statusColor, textColor: .white)

                if let provider = match.odds.apiProvider {
                    badge(text: provider, color: .white.opacity(0.12), textColor: .white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .padding(.horizontal, 16)
        )
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabOptions.indices, id: \.self) { index in
                    let selected = selectedTab == index
                    Text(tabOptions[index])
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selected ? .black : .white)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(selected ? Color.accentCyan : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var odds1X2Section: some View {
        marketCard(title: "1X2") {
            HStack(spacing: 10) {
                oddButton("1", .home, match.odds.home)
                oddButton("X", .draw, match.odds.draw)
                oddButton("2", .away, match.odds.away)
            }
        }
    }

    private var oddsDoubleChanceSection: some View {
        marketCard(title: "Doppia Chance", subtitle: "Quote calcolate dal mercato 1X2") {
            HStack(spacing: 10) {
                oddButton("1X", .homeDraw, match.odds.homeDraw)
                oddButton("X2", .drawAway, match.odds.drawAway)
                oddButton("12", .homeAway, match.odds.homeAway)
            }
        }
    }

    private var oddsOverUnderSection: some View {
        let subtitle = match.odds.apiMainTotalLine.map {
            "Linea API principale: \($0.formatted(.number.precision(.fractionLength(1))))"
        }

        return marketCard(title: "Over / Under", subtitle: subtitle) {
            VStack(spacing: 10) {
                overUnderRow(line: "0.5", underOdd: match.odds.under05, overOdd: match.odds.over05, underOutcome: .under05, overOutcome: .over05)
                overUnderRow(line: "1.5", underOdd: match.odds.under15, overOdd: match.odds.over15, underOutcome: .under15, overOutcome: .over15)
                overUnderRow(line: "2.5", underOdd: match.odds.under25, overOdd: match.odds.over25, underOutcome: .under25, overOutcome: .over25)
                overUnderRow(line: "3.5", underOdd: match.odds.under35, overOdd: match.odds.over35, underOutcome: .under35, overOutcome: .over35)
                overUnderRow(line: "4.5", underOdd: match.odds.under45, overOdd: match.odds.over45, underOutcome: .under45, overOutcome: .over45)
            }
        }
    }

    private var apiSnapshotSection: some View {
        marketCard(
            title: "Mercati API Diretti",
            subtitle: "Quote originali del feed bookmaker"
        ) {
            VStack(spacing: 10) {
                if let line = match.odds.apiMainTotalLine,
                   let overOdd = match.odds.apiMainOver,
                   let underOdd = match.odds.apiMainUnder {
                    if let underOutcome = underOutcome(for: line),
                       let overOutcome = overOutcome(for: line) {
                        HStack(spacing: 10) {
                            oddButton("U \(formattedGoalLine(line))", underOutcome, underOdd)
                            oddButton("O \(formattedGoalLine(line))", overOutcome, overOdd)
                        }
                    } else {
                        HStack(spacing: 10) {
                            infoOddCard(label: "U \(formattedGoalLine(line))", odd: underOdd)
                            infoOddCard(label: "O \(formattedGoalLine(line))", odd: overOdd)
                        }
                    }
                } else {
                    Text("Nessun mercato totale diretto disponibile per questa partita.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let provider = match.odds.apiProvider {
                    HStack {
                        Text("Bookmaker")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(provider)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var handicapSection: some View {
        marketCard(
            title: "Handicap (API)",
            subtitle: "Quote dal mercato point spread"
        ) {
            if let homeOdd = match.odds.handicapHome, let awayOdd = match.odds.handicapAway {
                HStack(spacing: 10) {
                    infoOddCard(
                        label: "1 \(formattedSignedLine(match.odds.handicapHomeLine))",
                        odd: homeOdd
                    )
                    infoOddCard(
                        label: "2 \(formattedSignedLine(match.odds.handicapAwayLine))",
                        odd: awayOdd
                    )
                }
            } else {
                Text("Mercato handicap non disponibile per questa partita.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func marketCard<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func overUnderRow(
        line: String,
        underOdd: Double,
        overOdd: Double,
        underOutcome: MatchOutcome,
        overOutcome: MatchOutcome
    ) -> some View {
        HStack(spacing: 10) {
            oddButton("U \(line)", underOutcome, underOdd)
            oddButton("O \(line)", overOutcome, overOdd)
        }
    }

    private func oddButton(_ label: String, _ outcome: MatchOutcome, _ odd: Double) -> some View {
        let isSelected = vm.currentPicks.contains { $0.match.id == match.id && $0.outcome == outcome }

        return Button {
            vm.addPick(match: match, outcome: outcome, odd: odd)
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                Text(odd.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentCyan : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentCyan : Color.white.opacity(0.16), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    private func infoOddCard(label: String, odd: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(odd.formatted(.number.precision(.fractionLength(2))))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.accentCyan)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1.5)
                )
        )
    }

    private func badge(text: String, color: Color, textColor: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch match.status {
        case "FINISHED":
            return .green.opacity(0.85)
        case "LIVE":
            return .red.opacity(0.85)
        default:
            return .orange.opacity(0.85)
        }
    }

    private func formattedSignedLine(_ line: Double?) -> String {
        guard let line else { return "" }
        return line >= 0
            ? "+\(line.formatted(.number.precision(.fractionLength(1))))"
            : line.formatted(.number.precision(.fractionLength(1)))
    }

    private func formattedGoalLine(_ line: Double) -> String {
        line.formatted(.number.precision(.fractionLength(1)))
    }

    private func underOutcome(for line: Double) -> MatchOutcome? {
        switch normalizedLine(line) {
        case 0.5: return .under05
        case 1.5: return .under15
        case 2.5: return .under25
        case 3.5: return .under35
        case 4.5: return .under45
        default: return nil
        }
    }

    private func overOutcome(for line: Double) -> MatchOutcome? {
        switch normalizedLine(line) {
        case 0.5: return .over05
        case 1.5: return .over15
        case 2.5: return .over25
        case 3.5: return .over35
        case 4.5: return .over45
        default: return nil
        }
    }

    private func normalizedLine(_ line: Double) -> Double {
        (line * 10).rounded() / 10
    }
}
