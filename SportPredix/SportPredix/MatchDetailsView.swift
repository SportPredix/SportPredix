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

    private let tabs: [(title: String, icon: String)] = [
        ("Panoramica", "sparkles"),
        ("1X2", "soccerball"),
        ("Doppia", "square.grid.2x2"),
        ("O/U", "chart.line.uptrend.xyaxis"),
        ("Handicap", "arrow.left.and.right"),
        ("API", "network")
    ]

    private var selectedPicksCount: Int {
        vm.currentPicks.filter { $0.match.id == match.id }.count
    }

    private var isBettingOpen: Bool {
        vm.canBet(on: match)
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        heroCard

                        if !isBettingOpen {
                            lockedBanner
                        }

                        tabsBar
                        visibleMarkets
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
    }

    @ViewBuilder
    private var visibleMarkets: some View {
        switch selectedTab {
        case 0:
            overviewPanel
            oneXTwoPanel
            overUnderPanel
        case 1:
            oneXTwoPanel
        case 2:
            doubleChancePanel
        case 3:
            overUnderPanel
        case 4:
            handicapPanel
        default:
            apiPanel
            handicapPanel
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.05),
                    Color(red: 0.06, green: 0.08, blue: 0.10),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentCyan.opacity(0.10))
                    .frame(height: 140)
                    .blur(radius: 50)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.accentCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Quote Partita")
                    .font(.custom("AvenirNextCondensed-Bold", size: 23))
                    .foregroundColor(.white)
                Text(match.competition)
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .bold))
                Text("\(selectedPicksCount)")
                    .font(.custom("AvenirNext-Bold", size: 13))
            }
            .foregroundColor(.accentCyan)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.78).ignoresSafeArea(edges: .top))
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                teamPill(name: match.home, side: "Casa", alignLeading: true)

                VStack(spacing: 6) {
                    Text("VS")
                        .font(.custom("AvenirNextCondensed-Bold", size: 16))
                        .foregroundColor(.accentCyan)
                    statusTag
                }
                .frame(width: 70)

                teamPill(name: match.away, side: "Trasferta", alignLeading: false)
            }

            HStack(spacing: 8) {
                tinyTag(text: match.time, fill: Color.white.opacity(0.14), foreground: .white)
                if let provider = match.odds.apiProvider {
                    tinyTag(text: provider, fill: Color.white.opacity(0.14), foreground: .white)
                }
                if let actualResult = match.actualResult {
                    tinyTag(text: "Risultato \(actualResult)", fill: Color.green.opacity(0.24), foreground: .green)
                }
            }
        }
        .padding(14)
        .background(surface(0.12))
    }

    private var lockedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .bold))
            Text("Scommesse chiuse: partita iniziata")
                .font(.custom("AvenirNext-DemiBold", size: 13))
        }
        .foregroundColor(.orange)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(surface(0.10))
    }

    private var tabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs.indices, id: \.self) { index in
                    let selected = selectedTab == index
                    let tab = tabs[index]

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedTab = index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(tab.title)
                                .font(.custom("AvenirNext-DemiBold", size: 13))
                        }
                        .foregroundColor(selected ? .black : .white)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(selected ? Color.accentCyan : Color.white.opacity(0.14))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var overviewPanel: some View {
        marketPanel(
            title: "Quote principali",
            subtitle: "Mercati rapidi piu usati",
            icon: "sparkles"
        ) {
            HStack(spacing: 10) {
                oddButton(label: "1", outcome: .home, odd: match.odds.home)
                oddButton(label: "X", outcome: .draw, odd: match.odds.draw)
                oddButton(label: "2", outcome: .away, odd: match.odds.away)
            }

            HStack(spacing: 10) {
                oddButton(label: "1X", outcome: .homeDraw, odd: match.odds.homeDraw)
                oddButton(label: "12", outcome: .homeAway, odd: match.odds.homeAway)
                oddButton(label: "X2", outcome: .drawAway, odd: match.odds.drawAway)
            }
        }
    }

    private var oneXTwoPanel: some View {
        marketPanel(
            title: "1X2",
            subtitle: "Esito finale della partita",
            icon: "soccerball"
        ) {
            HStack(spacing: 10) {
                oddButton(label: "1", outcome: .home, odd: match.odds.home)
                oddButton(label: "X", outcome: .draw, odd: match.odds.draw)
                oddButton(label: "2", outcome: .away, odd: match.odds.away)
            }
        }
    }

    private var doubleChancePanel: some View {
        marketPanel(
            title: "Doppia chance",
            subtitle: "Derivate dal mercato 1X2",
            icon: "square.grid.2x2"
        ) {
            HStack(spacing: 10) {
                oddButton(label: "1X", outcome: .homeDraw, odd: match.odds.homeDraw)
                oddButton(label: "12", outcome: .homeAway, odd: match.odds.homeAway)
                oddButton(label: "X2", outcome: .drawAway, odd: match.odds.drawAway)
            }
        }
    }

    private var overUnderPanel: some View {
        let subtitle = match.odds.apiMainTotalLine.map {
            "Linea API: \($0.formatted(.number.precision(.fractionLength(1))))"
        }

        return marketPanel(
            title: "Over / Under",
            subtitle: subtitle ?? "Linee gol disponibili",
            icon: "chart.line.uptrend.xyaxis"
        ) {
            VStack(spacing: 8) {
                lineRow(
                    line: "0.5",
                    underOdd: match.odds.under05,
                    overOdd: match.odds.over05,
                    underOutcome: .under05,
                    overOutcome: .over05
                )
                lineRow(
                    line: "1.5",
                    underOdd: match.odds.under15,
                    overOdd: match.odds.over15,
                    underOutcome: .under15,
                    overOutcome: .over15
                )
                lineRow(
                    line: "2.5",
                    underOdd: match.odds.under25,
                    overOdd: match.odds.over25,
                    underOutcome: .under25,
                    overOutcome: .over25
                )
                lineRow(
                    line: "3.5",
                    underOdd: match.odds.under35,
                    overOdd: match.odds.over35,
                    underOutcome: .under35,
                    overOutcome: .over35
                )
                lineRow(
                    line: "4.5",
                    underOdd: match.odds.under45,
                    overOdd: match.odds.over45,
                    underOutcome: .under45,
                    overOutcome: .over45
                )
            }
        }
    }

    private var apiPanel: some View {
        marketPanel(
            title: "Mercati API",
            subtitle: "Snapshot dal feed bookmaker",
            icon: "network"
        ) {
            if let line = match.odds.apiMainTotalLine,
               let overOdd = match.odds.apiMainOver,
               let underOdd = match.odds.apiMainUnder {
                if let underOutcome = underOutcome(for: line),
                   let overOutcome = overOutcome(for: line) {
                    HStack(spacing: 10) {
                        oddButton(
                            label: "U \(formattedGoalLine(line))",
                            outcome: underOutcome,
                            odd: underOdd
                        )
                        oddButton(
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
                Text("Nessun mercato totale API disponibile.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("Bookmaker")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Text(match.odds.apiProvider ?? "N/D")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(.white)
            }
            .padding(.top, 2)
        }
    }

    private var handicapPanel: some View {
        marketPanel(
            title: "Handicap",
            subtitle: "Mercato point spread",
            icon: "arrow.left.and.right"
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
                Text("Mercato handicap non disponibile.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func marketPanel<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 24, height: 24)
                    .background(Color.accentCyan)
                    .clipShape(Circle())

                Text(title)
                    .font(.custom("AvenirNextCondensed-Bold", size: 22))
                    .foregroundColor(.white)
            }

            Text(subtitle)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(.gray)

            content()
        }
        .padding(14)
        .background(surface(0.11))
    }

    private func lineRow(
        line: String,
        underOdd: Double,
        overOdd: Double,
        underOutcome: MatchOutcome,
        overOutcome: MatchOutcome
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Linea \(line)")
                .font(.custom("AvenirNext-DemiBold", size: 12))
                .foregroundColor(.gray)

            HStack(spacing: 10) {
                oddButton(label: "U \(line)", outcome: underOutcome, odd: underOdd)
                oddButton(label: "O \(line)", outcome: overOutcome, odd: overOdd)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func oddButton(label: String, outcome: MatchOutcome, odd: Double) -> some View {
        let isSelected = vm.currentPicks.contains { $0.match.id == match.id && $0.outcome == outcome }

        return Button {
            guard isBettingOpen else { return }
            vm.addPick(match: match, outcome: outcome, odd: odd)
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .font(.custom("AvenirNextCondensed-Bold", size: 18))
                Text(odd.formatted(.number.precision(.fractionLength(2))))
                    .font(.custom("Menlo-Bold", size: 13))
            }
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(isSelected ? Color.accentCyan : Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isBettingOpen)
        .opacity(isBettingOpen ? 1.0 : 0.65)
    }

    private func readonlyOddCard(label: String, odd: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("AvenirNextCondensed-Bold", size: 18))
                .foregroundColor(.white)
            Text(odd.formatted(.number.precision(.fractionLength(2))))
                .font(.custom("Menlo-Bold", size: 13))
                .foregroundColor(.accentCyan)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusTag: some View {
        Text(match.status)
            .font(.custom("AvenirNext-DemiBold", size: 11))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(statusFill)
            .clipShape(Capsule())
    }

    private func teamPill(name: String, side: String, alignLeading: Bool) -> some View {
        VStack(alignment: alignLeading ? .leading : .trailing, spacing: 3) {
            Text(name)
                .font(.custom("AvenirNextCondensed-Bold", size: 25))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(alignLeading ? .leading : .trailing)
            Text(side)
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: alignLeading ? .leading : .trailing)
    }

    private func tinyTag(text: String, fill: Color, foreground: Color) -> some View {
        Text(text)
            .font(.custom("AvenirNext-Medium", size: 11))
            .foregroundColor(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(fill)
            .clipShape(Capsule())
    }

    private func surface(_ opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(opacity))
    }

    private var statusFill: Color {
        switch match.status.uppercased() {
        case "FINISHED":
            return .green.opacity(0.8)
        case "LIVE":
            return .red.opacity(0.8)
        default:
            return .orange.opacity(0.8)
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
