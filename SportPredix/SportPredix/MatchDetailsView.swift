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

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    private let tabOptions = ["Panoramica", "1X2", "Doppia", "O/U", "Handicap", "API"]

    private var selectedPicksCount: Int {
        vm.currentPicks.filter { $0.match.id == match.id }.count
    }

    private var isBettingOpen: Bool {
        vm.canBet(on: match)
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 12) {
                headerCard
                tabBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        visibleMarkets
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 8)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 110 {
                        dismiss()
                    }
                }
        )
    }

    @ViewBuilder
    private var visibleMarkets: some View {
        switch selectedTab {
        case 0:
            overviewSection
            odds1X2Section
            oddsOverUnderSection
        case 1:
            odds1X2Section
        case 2:
            oddsDoubleChanceSection
        case 3:
            oddsOverUnderSection
        case 4:
            handicapSection
        default:
            apiSnapshotSection
            handicapSection
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.04, green: 0.07, blue: 0.10),
                    Color(red: 0.02, green: 0.04, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [Color.accentCyan.opacity(0.22), Color.clear]),
                center: .topTrailing,
                startRadius: 30,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentCyan)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                statusPill(text: match.status)
            }

            HStack(alignment: .center, spacing: 12) {
                teamBlock(name: match.home, side: "Casa", isLeading: true)

                Text("VS")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                teamBlock(name: match.away, side: "Trasferta", isLeading: false)
            }

            if let actualResult = match.actualResult {
                Text("Risultato: \(actualResult)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.14))
                    .clipShape(Capsule())
            }

            if !isBettingOpen {
                Text("Scommesse chiuse: partita iniziata")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                infoBadge(text: match.competition.uppercased(), foreground: .black, background: .accentCyan)
                infoBadge(text: match.time, foreground: .white, background: Color.white.opacity(0.10))

                if let provider = match.odds.apiProvider {
                    infoBadge(text: provider, foreground: .white, background: Color.white.opacity(0.10))
                }

                if selectedPicksCount > 0 {
                    infoBadge(
                        text: "\(selectedPicksCount) selezioni",
                        foreground: .white,
                        background: Color.accentCyan.opacity(0.22)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(panelBackground(stroke: Color.accentCyan.opacity(0.36)))
        .padding(.horizontal, 16)
    }

    private func teamBlock(name: String, side: String, isLeading: Bool) -> some View {
        VStack(alignment: isLeading ? .leading : .trailing, spacing: 3) {
            Text(name)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(isLeading ? .leading : .trailing)

            Text(side)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
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
                        .background(
                            Capsule()
                                .fill(selected ? Color.accentCyan : Color.white.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(selected ? Color.accentCyan : Color.white.opacity(0.18), lineWidth: 1.4)
                                )
                        )
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

    private var overviewSection: some View {
        marketPanel(
            title: "Quote principali",
            subtitle: "Selezione rapida sui mercati principali",
            icon: "sparkles"
        ) {
            HStack(spacing: 10) {
                oddSelectionCard(label: "1", outcome: .home, odd: match.odds.home)
                oddSelectionCard(label: "X", outcome: .draw, odd: match.odds.draw)
                oddSelectionCard(label: "2", outcome: .away, odd: match.odds.away)
            }

            HStack(spacing: 10) {
                oddSelectionCard(label: "1X", outcome: .homeDraw, odd: match.odds.homeDraw)
                oddSelectionCard(label: "X2", outcome: .drawAway, odd: match.odds.drawAway)
            }
        }
    }

    private var odds1X2Section: some View {
        marketPanel(
            title: "1X2",
            subtitle: "Esito finale della partita",
            icon: "soccerball"
        ) {
            HStack(spacing: 10) {
                oddSelectionCard(label: "1", outcome: .home, odd: match.odds.home)
                oddSelectionCard(label: "X", outcome: .draw, odd: match.odds.draw)
                oddSelectionCard(label: "2", outcome: .away, odd: match.odds.away)
            }
        }
    }

    private var oddsDoubleChanceSection: some View {
        marketPanel(
            title: "Doppia chance",
            subtitle: "Quote derivate dal mercato 1X2",
            icon: "square.grid.2x2"
        ) {
            HStack(spacing: 10) {
                oddSelectionCard(label: "1X", outcome: .homeDraw, odd: match.odds.homeDraw)
                oddSelectionCard(label: "X2", outcome: .drawAway, odd: match.odds.drawAway)
                oddSelectionCard(label: "12", outcome: .homeAway, odd: match.odds.homeAway)
            }
        }
    }

    private var oddsOverUnderSection: some View {
        let subtitle = match.odds.apiMainTotalLine.map {
            "Linea API principale: \($0.formatted(.number.precision(.fractionLength(1))))"
        }

        return marketPanel(
            title: "Over / Under",
            subtitle: subtitle ?? "Linee gol complete",
            icon: "chart.line.uptrend.xyaxis"
        ) {
            VStack(spacing: 10) {
                overUnderLinePanel(
                    line: "0.5",
                    underOdd: match.odds.under05,
                    overOdd: match.odds.over05,
                    underOutcome: .under05,
                    overOutcome: .over05
                )
                overUnderLinePanel(
                    line: "1.5",
                    underOdd: match.odds.under15,
                    overOdd: match.odds.over15,
                    underOutcome: .under15,
                    overOutcome: .over15
                )
                overUnderLinePanel(
                    line: "2.5",
                    underOdd: match.odds.under25,
                    overOdd: match.odds.over25,
                    underOutcome: .under25,
                    overOutcome: .over25
                )
                overUnderLinePanel(
                    line: "3.5",
                    underOdd: match.odds.under35,
                    overOdd: match.odds.over35,
                    underOutcome: .under35,
                    overOutcome: .over35
                )
                overUnderLinePanel(
                    line: "4.5",
                    underOdd: match.odds.under45,
                    overOdd: match.odds.over45,
                    underOutcome: .under45,
                    overOutcome: .over45
                )
            }
        }
    }

    private var apiSnapshotSection: some View {
        marketPanel(
            title: "Mercati API",
            subtitle: "Snapshot diretto dal feed bookmaker",
            icon: "network"
        ) {
            if let line = match.odds.apiMainTotalLine,
               let overOdd = match.odds.apiMainOver,
               let underOdd = match.odds.apiMainUnder {
                if let underOutcome = underOutcome(for: line),
                   let overOutcome = overOutcome(for: line) {
                    HStack(spacing: 10) {
                        oddSelectionCard(
                            label: "U \(formattedGoalLine(line))",
                            outcome: underOutcome,
                            odd: underOdd
                        )
                        oddSelectionCard(
                            label: "O \(formattedGoalLine(line))",
                            outcome: overOutcome,
                            odd: overOdd
                        )
                    }
                } else {
                    HStack(spacing: 10) {
                        readonlyOddCard(label: "U \(formattedGoalLine(line))", odd: underOdd)
                        readonlyOddCard(label: "O \(formattedGoalLine(line))", odd: overOdd)
                    }
                }
            } else {
                Text("Nessun mercato totale API disponibile per questa partita.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().background(Color.white.opacity(0.18))

            HStack {
                Text("Bookmaker")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(match.odds.apiProvider ?? "N/D")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
            }
        }
    }

    private var handicapSection: some View {
        marketPanel(
            title: "Handicap",
            subtitle: "Mercato point spread API",
            icon: "arrow.left.and.right.righttriangle.left.righttriangle.right"
        ) {
            if let homeOdd = match.odds.handicapHome, let awayOdd = match.odds.handicapAway {
                HStack(spacing: 10) {
                    readonlyOddCard(
                        label: "1 \(formattedSignedLine(match.odds.handicapHomeLine))",
                        odd: homeOdd
                    )
                    readonlyOddCard(
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

    private func marketPanel<Content: View>(
        title: String,
        subtitle: String? = nil,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentCyan)
                    .frame(width: 26, height: 26)
                    .background(Color.accentCyan.opacity(0.14))
                    .clipShape(Circle())

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            content()
        }
        .padding(14)
        .background(panelBackground(stroke: Color.white.opacity(0.18)))
    }

    private func overUnderLinePanel(
        line: String,
        underOdd: Double,
        overOdd: Double,
        underOutcome: MatchOutcome,
        overOutcome: MatchOutcome
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Linea \(line)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.gray)

            HStack(spacing: 10) {
                oddSelectionCard(label: "U \(line)", outcome: underOutcome, odd: underOdd)
                oddSelectionCard(label: "O \(line)", outcome: overOutcome, odd: overOdd)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func oddSelectionCard(label: String, outcome: MatchOutcome, odd: Double) -> some View {
        let isSelected = vm.currentPicks.contains { $0.match.id == match.id && $0.outcome == outcome }
        let bettingOpen = isBettingOpen

        return Button {
            guard bettingOpen else { return }
            vm.addPick(match: match, outcome: outcome, odd: odd)
        } label: {
            VStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                Text(odd.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(size: 15, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundColor(
                bettingOpen
                ? (isSelected ? .black : .white)
                : .gray
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        bettingOpen
                        ? (isSelected ? Color.accentCyan : Color.white.opacity(0.04))
                        : Color.white.opacity(0.02)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        bettingOpen
                        ? (isSelected ? Color.accentCyan : Color.white.opacity(0.20))
                        : Color.white.opacity(0.10),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .disabled(!bettingOpen)
        .opacity(bettingOpen ? 1.0 : 0.55)
    }

    private func readonlyOddCard(label: String, odd: Double) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(odd.formatted(.number.precision(.fractionLength(2))))
                .font(.system(size: 15, weight: .medium))
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
                        .stroke(Color.white.opacity(0.20), lineWidth: 1.5)
                )
        )
    }

    private func infoBadge(text: String, foreground: Color, background: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(background)
            .clipShape(Capsule())
    }

    private func statusPill(text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor)
            .clipShape(Capsule())
    }

    private func panelBackground(stroke: Color) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(stroke, lineWidth: 1.2)
            )
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
