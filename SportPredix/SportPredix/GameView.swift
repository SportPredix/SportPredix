//
//  GameView.swift
//  SportPredix
//

import SwiftUI
import UIKit

private enum CasinoFormatting {
    static func euro(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR"))
    }
}

// MARK: - Slot Machine

struct SlotMachineView: View {
    private enum Phase {
        case lobby
        case spinning
        case result
    }

    @Environment(\.dismiss) private var dismiss
    @Binding var balance: Double

    @State private var phase: Phase = .lobby
    @State private var selectedBet = SlotConfig.defaultBet
    @State private var displayedSymbols: [SlotSymbol] = [.heart, .sun, .diamond]
    @State private var payout: Int = 0
    @State private var isSpinning = false
    @State private var showInsufficientBalance = false
    @State private var spinTask: Task<Void, Never>?

    private var netResult: Int {
        payout - selectedBet
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.12, green: 0.03, blue: 0.08), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                switch phase {
                case .lobby:
                    lobbyView
                case .spinning:
                    spinningView
                case .result:
                    resultView
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .onDisappear {
            spinTask?.cancel()
            spinTask = nil
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Saldo richiesto: \(CasinoFormatting.euro(Double(selectedBet))).")
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.accentCyan)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Slot Machine")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)

            Spacer()

            Text(CasinoFormatting.euro(balance))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accentCyan)
                .monospacedDigit()
        }
        .padding(.top, 12)
    }

    private var lobbyView: some View {
        VStack(spacing: 16) {
            slotDisplay(highlightWin: false)

            VStack(alignment: .leading, spacing: 10) {
                Text("Puntata")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)

                HStack(spacing: 10) {
                    ForEach(SlotConfig.availableBets, id: \.self) { bet in
                        Button {
                            selectedBet = bet
                        } label: {
                            Text(CasinoFormatting.euro(Double(bet)))
                                .font(.caption.weight(.bold))
                                .foregroundColor(selectedBet == bet ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(selectedBet == bet ? Color.accentCyan : Color.white.opacity(0.12))
                                .cornerRadius(10)
                        }
                    }
                }
            }

            payoutTable

            Button {
                startSpin()
            } label: {
                Text("SPIN \(CasinoFormatting.euro(Double(selectedBet)))")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.pink)
                    .cornerRadius(14)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.pink.opacity(0.28), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private var spinningView: some View {
        VStack(spacing: 18) {
            slotDisplay(highlightWin: false)

            ProgressView()
                .tint(.pink)
                .scaleEffect(1.3)

            Text("Rulli in movimento...")
                .font(.headline.weight(.semibold))
                .foregroundColor(.pink)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            slotDisplay(highlightWin: payout > 0)

            Image(systemName: payout > 0 ? "sparkles" : "xmark.circle")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(payout > 0 ? .yellow : .gray)

            Text(
                payout > 0
                    ? "Vincita: \(CasinoFormatting.euro(Double(payout)))"
                    : "Nessuna combinazione"
            )
            .font(.title3.weight(.bold))
            .foregroundColor(.white)

            VStack(spacing: 10) {
                summaryRow(label: "Costo spin", value: "-\(CasinoFormatting.euro(Double(selectedBet)))", valueColor: .red)
                summaryRow(label: "Vincita", value: CasinoFormatting.euro(Double(payout)), valueColor: payout > 0 ? .green : .gray)
                summaryRow(
                    label: "Netto spin",
                    value: "\(netResult >= 0 ? "+" : "-")\(CasinoFormatting.euro(Double(abs(netResult))))",
                    valueColor: netResult >= 0 ? .green : .orange
                )
                summaryRow(label: "Saldo attuale", value: CasinoFormatting.euro(balance), valueColor: .accentCyan)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)

            HStack(spacing: 12) {
                Button {
                    startSpin()
                } label: {
                    Text("Rigioca")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.pink)
                        .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Chiudi")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private var payoutTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tabella vincite")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            ForEach(SlotSymbol.allCases, id: \.self) { symbol in
                HStack(spacing: 8) {
                    Image(systemName: symbol.icon)
                        .foregroundColor(symbol.color)
                    Text(symbol.name)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 70, alignment: .leading)

                    Spacer()

                    Text("3x = x\(symbol.tripleMultiplier)")
                        .foregroundColor(.yellow)
                    Text("2x = x\(symbol.pairMultiplier)")
                        .foregroundColor(.orange)
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    private func slotDisplay(highlightWin: Bool) -> some View {
        HStack(spacing: 10) {
            ForEach(displayedSymbols.indices, id: \.self) { index in
                let symbol = displayedSymbols[index]
                VStack(spacing: 8) {
                    Image(systemName: symbol.icon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(symbol.color)
                    Text(symbol.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.86))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.17, green: 0.11, blue: 0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(highlightWin ? Color.yellow.opacity(0.75) : Color.white.opacity(0.2), lineWidth: 1.5)
                )
                .animation(.easeOut(duration: 0.12), value: symbol)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.pink.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func summaryRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func startSpin() {
        guard !isSpinning else { return }
        guard balance >= Double(selectedBet) else {
            showInsufficientBalance = true
            return
        }

        balance -= Double(selectedBet)
        payout = 0
        isSpinning = true
        phase = .spinning

        let finalSymbols = [drawSlotSymbol(), drawSlotSymbol(), drawSlotSymbol()]

        spinTask?.cancel()
        spinTask = Task {
            await animateSpin(to: finalSymbols)
        }
    }

    @MainActor
    private func animateSpin(to finalSymbols: [SlotSymbol]) async {
        for _ in 0..<20 {
            if Task.isCancelled { return }

            displayedSymbols = [drawSlotSymbol(), drawSlotSymbol(), drawSlotSymbol()]
            try? await Task.sleep(nanoseconds: 70_000_000)
        }

        for index in displayedSymbols.indices {
            if Task.isCancelled { return }

            var nextSymbols = displayedSymbols
            nextSymbols[index] = finalSymbols[index]

            withAnimation(.easeOut(duration: 0.18)) {
                displayedSymbols = nextSymbols
            }

            let delayMs = UInt64(160 + (index * 90))
            try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
        }

        resolveSpin(with: finalSymbols)
        spinTask = nil
    }

    private func resolveSpin(with symbols: [SlotSymbol]) {
        let roundPayout = calculatePayout(symbols: symbols)
        payout = roundPayout
        isSpinning = false

        if roundPayout > 0 {
            balance += Double(roundPayout)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            phase = .result
        }
    }

    private func calculatePayout(symbols: [SlotSymbol]) -> Int {
        guard symbols.count == 3 else { return 0 }

        if symbols[0] == symbols[1], symbols[1] == symbols[2] {
            return selectedBet * symbols[0].tripleMultiplier
        }

        if let pairSymbol = pairSymbol(in: symbols) {
            return selectedBet * pairSymbol.pairMultiplier
        }

        let specialCombo: Set<SlotSymbol> = [.crown, .star, .bolt]
        if Set(symbols) == specialCombo {
            return selectedBet * 5
        }

        return 0
    }

    private func pairSymbol(in symbols: [SlotSymbol]) -> SlotSymbol? {
        if symbols[0] == symbols[1] || symbols[0] == symbols[2] {
            return symbols[0]
        }
        if symbols[1] == symbols[2] {
            return symbols[1]
        }
        return nil
    }

    private func drawSlotSymbol() -> SlotSymbol {
        let totalWeight = SlotSymbol.allCases.reduce(0) { $0 + $1.weight }
        var ticket = Int.random(in: 1...totalWeight)

        for symbol in SlotSymbol.allCases {
            ticket -= symbol.weight
            if ticket <= 0 {
                return symbol
            }
        }

        return .heart
    }
}

// MARK: - Scratch Card

struct ScratchCardView: View {
    private enum Phase {
        case lobby
        case playing
        case result
    }

    @Environment(\.dismiss) private var dismiss
    @Binding var balance: Double

    @State private var phase: Phase = .lobby
    @State private var round: ScratchRound?
    @State private var payout: Int = 0
    @State private var showInsufficientBalance = false

    private var revealedCount: Int {
        round?.tiles.filter(\.isRevealed).count ?? 0
    }

    private var revealProgress: Double {
        guard let round else { return 0 }
        return Double(revealedCount) / Double(max(1, round.tiles.count))
    }

    private var netResult: Int {
        payout - ScratchConfig.ticketCost
    }

    private var currentStakeText: String {
        CasinoFormatting.euro(Double(ScratchConfig.ticketCost))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.12), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                switch phase {
                case .lobby:
                    lobbyView
                case .playing:
                    playingView
                case .result:
                    resultView
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Servono almeno \(currentStakeText) per iniziare.")
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.accentCyan)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Gratta e Vinci")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)

            Spacer()

            Text(CasinoFormatting.euro(balance))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accentCyan)
                .monospacedDigit()
        }
        .padding(.top, 12)
    }

    private var lobbyView: some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.accentCyan)

                Text("Nuovo formato: scopri 9 caselle e cerca 3 simboli uguali.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentCyan.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 10) {
                Text("Costo ticket: \(currentStakeText)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text("Vincita massima: \(CasinoFormatting.euro(Double(ScratchConfig.ticketCost * 12)))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text("Rivelazione manuale casella per casella.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)

            Button {
                startRound()
            } label: {
                Text("Inizia Partita")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.accentCyan)
                    .cornerRadius(14)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private var playingView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                HStack {
                    Text("Caselle aperte: \(revealedCount)/\(ScratchConfig.boardSize)")
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text("\(Int(revealProgress * 100))%")
                        .foregroundColor(.accentCyan)
                        .monospacedDigit()
                }
                .font(.subheadline.weight(.semibold))

                ProgressView(value: revealProgress)
                    .progressViewStyle(.linear)
                    .tint(.accentCyan)
            }

            if let round {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                    spacing: 10
                ) {
                    ForEach(round.tiles) { tile in
                        scratchTile(tile)
                    }
                }
            }

            Button {
                revealAll()
            } label: {
                Text("Scopri Tutto")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.accentCyan.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: payout > 0 ? "checkmark.seal.fill" : "xmark.seal")
                .font(.system(size: 52))
                .foregroundColor(payout > 0 ? .green : .gray)

            Text(payout > 0 ? "Hai vinto \(CasinoFormatting.euro(Double(payout)))" : "Nessuna combinazione vincente")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            if let round {
                Text("Moltiplicatore round: x\(round.payoutMultiplier)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 10) {
                summaryRow(label: "Costo ticket", value: "-\(currentStakeText)", valueColor: .red)
                summaryRow(label: "Vincita", value: CasinoFormatting.euro(Double(payout)), valueColor: payout > 0 ? .green : .gray)
                summaryRow(
                    label: "Netto round",
                    value: "\(netResult >= 0 ? "+" : "-")\(CasinoFormatting.euro(Double(abs(netResult))))",
                    valueColor: netResult >= 0 ? .green : .orange
                )
                summaryRow(label: "Saldo attuale", value: CasinoFormatting.euro(balance), valueColor: .accentCyan)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)

            HStack(spacing: 12) {
                Button {
                    startRound()
                } label: {
                    Text("Rigioca")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.accentCyan)
                        .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Chiudi")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private func scratchTile(_ tile: ScratchTile) -> some View {
        Button {
            revealTile(id: tile.id)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.18))

                if tile.isRevealed {
                    VStack(spacing: 5) {
                        Image(systemName: tile.symbol.icon)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(tile.symbol.tint)
                        Text(tile.symbol.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white.opacity(0.88))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                        )
                }
            }
            .frame(height: 94)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tile.isRevealed ? tile.symbol.tint.opacity(0.7) : Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(tile.isRevealed || phase != .playing)
    }

    private func summaryRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func startRound() {
        guard balance >= Double(ScratchConfig.ticketCost) else {
            showInsufficientBalance = true
            return
        }

        balance -= Double(ScratchConfig.ticketCost)
        payout = 0
        round = generateRound()

        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            phase = .playing
        }
    }

    private func revealTile(id: UUID) {
        guard phase == .playing, var round else { return }
        guard let index = round.tiles.firstIndex(where: { $0.id == id }), !round.tiles[index].isRevealed else { return }

        round.tiles[index].isRevealed = true
        self.round = round

        if let winner = revealedWinner(in: round) {
            finishRound(round: round, winner: winner)
            return
        }

        if round.tiles.allSatisfy(\.isRevealed) {
            finishRound(round: round, winner: nil)
        }
    }

    private func revealAll() {
        guard phase == .playing, var round else { return }

        for index in round.tiles.indices {
            round.tiles[index].isRevealed = true
        }

        self.round = round
        finishRound(round: round, winner: revealedWinner(in: round))
    }

    private func finishRound(round: ScratchRound, winner: ScratchSymbol?) {
        guard phase == .playing else { return }

        payout = winner == nil ? 0 : round.payout
        if payout > 0 {
            balance += Double(payout)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
            phase = .result
        }
    }

    private func generateRound() -> ScratchRound {
        let multiplier = weightedValue(from: [
            (value: 0, weight: 48),
            (value: 1, weight: 22),
            (value: 2, weight: 14),
            (value: 4, weight: 9),
            (value: 8, weight: 5),
            (value: 12, weight: 2)
        ])

        if multiplier == 0 {
            return ScratchRound(
                payout: 0,
                payoutMultiplier: 0,
                tiles: losingTiles()
            )
        }

        let winner = ScratchSymbol.allCases.randomElement() ?? .star
        var symbols = Array(repeating: winner, count: 3)
        let pool = ScratchSymbol.allCases.filter { $0 != winner }

        for _ in 0..<6 {
            symbols.append(pool.randomElement() ?? .bolt)
        }

        symbols.shuffle()

        return ScratchRound(
            payout: ScratchConfig.ticketCost * multiplier,
            payoutMultiplier: multiplier,
            tiles: symbols.map { ScratchTile(symbol: $0) }
        )
    }

    private func losingTiles() -> [ScratchTile] {
        var symbols = ScratchSymbol.allCases.flatMap { symbol in
            Array(repeating: symbol, count: 2)
        }

        symbols.remove(at: Int.random(in: 0..<symbols.count))
        symbols.shuffle()

        return symbols.map { ScratchTile(symbol: $0) }
    }

    private func revealedWinner(in round: ScratchRound) -> ScratchSymbol? {
        let counts = Dictionary(grouping: round.tiles.filter(\.isRevealed), by: \.symbol).mapValues(\.count)
        return counts.first(where: { $0.value >= 3 })?.key
    }
}

private enum ScratchConfig {
    static let ticketCost = 50
    static let boardSize = 9
}

private enum SlotConfig {
    static let defaultBet = 10
    static let availableBets = [10, 25, 50]
}

private enum ScratchSymbol: CaseIterable, Hashable {
    case star
    case bolt
    case flame
    case diamond
    case crown

    var icon: String {
        switch self {
        case .star: return "star.fill"
        case .bolt: return "bolt.fill"
        case .flame: return "flame.fill"
        case .diamond: return "diamond.fill"
        case .crown: return "crown.fill"
        }
    }

    var tint: Color {
        switch self {
        case .star: return .yellow
        case .bolt: return .orange
        case .flame: return .red
        case .diamond: return .cyan
        case .crown: return .purple
        }
    }

    var label: String {
        switch self {
        case .star: return "Stella"
        case .bolt: return "Fulmine"
        case .flame: return "Fiamma"
        case .diamond: return "Diamante"
        case .crown: return "Corona"
        }
    }
}

private struct ScratchTile: Identifiable {
    let id = UUID()
    let symbol: ScratchSymbol
    var isRevealed = false
}

private struct ScratchRound {
    let payout: Int
    let payoutMultiplier: Int
    var tiles: [ScratchTile]
}

private enum SlotSymbol: CaseIterable, Hashable {
    case heart
    case sun
    case diamond
    case bolt
    case star
    case crown

    var icon: String {
        switch self {
        case .heart: return "suit.heart.fill"
        case .sun: return "sun.max.fill"
        case .diamond: return "diamond.fill"
        case .bolt: return "bolt.fill"
        case .star: return "star.fill"
        case .crown: return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .heart: return .pink
        case .sun: return .yellow
        case .diamond: return .cyan
        case .bolt: return .orange
        case .star: return .mint
        case .crown: return .purple
        }
    }

    var name: String {
        switch self {
        case .heart: return "Heart"
        case .sun: return "Sun"
        case .diamond: return "Diamond"
        case .bolt: return "Bolt"
        case .star: return "Star"
        case .crown: return "Crown"
        }
    }

    var weight: Int {
        switch self {
        case .heart: return 28
        case .sun: return 24
        case .diamond: return 19
        case .bolt: return 14
        case .star: return 10
        case .crown: return 5
        }
    }

    var tripleMultiplier: Int {
        switch self {
        case .heart: return 2
        case .sun: return 3
        case .diamond: return 4
        case .bolt: return 6
        case .star: return 10
        case .crown: return 18
        }
    }

    var pairMultiplier: Int {
        switch self {
        case .heart: return 1
        case .sun: return 1
        case .diamond: return 2
        case .bolt: return 2
        case .star: return 4
        case .crown: return 7
        }
    }
}

// MARK: - Games Grid

struct GamesView: View {
    private let games = [
        ("Gratta e Vinci", "sparkles", Color.accentCyan),
        ("Slot Machine", "slot.machine", Color.pink),
        ("Crazy Time", "clock.badge", Color.orange),
        ("Roulette", "circle.grid.cross", Color.green),
        ("Blackjack", "suit.club", Color.purple),
        ("Poker", "suit.spade", Color.yellow)
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @EnvironmentObject var vm: BettingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(games, id: \.0) { game in
                        GameButton(title: game.0, icon: game.1, color: game.2)
                            .environmentObject(vm)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                VStack(spacing: 6) {
                    Text("Gioco responsabile | maggiorenni | vietato ai minori")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("Le vincite sono virtuali")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.75))
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.clear)
    }
}

struct GameButton: View {
    let title: String
    let icon: String
    let color: Color

    @EnvironmentObject var vm: BettingViewModel
    @State private var showGame = false

    private var minStake: Int? {
        switch title {
        case "Gratta e Vinci":
            return ScratchConfig.ticketCost
        case "Slot Machine":
            return SlotConfig.defaultBet
        default:
            return nil
        }
    }

    private var badgeText: String {
        if let minStake {
            return "Min \(CasinoFormatting.euro(Double(minStake)))"
        }
        return "Prossimamente"
    }

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showGame = true
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 66, height: 66)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(badgeText)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.32))
                    .cornerRadius(10)

                if let minStake, vm.balance < Double(minStake) {
                    Text("Saldo basso")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 188)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(color.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showGame) {
            destinationView
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if title == "Gratta e Vinci" {
            ScratchCardView(balance: $vm.balance)
        } else if title == "Slot Machine" {
            SlotMachineView(balance: $vm.balance)
        } else {
            ComingSoonView(gameName: title)
        }
    }
}

struct ComingSoonView: View {
    let gameName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.09), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "clock.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.accentCyan)

                Text(gameName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                Text("Disponibile presto")
                    .font(.headline)
                    .foregroundColor(.accentCyan)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Torna indietro")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accentCyan)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 28)
            }
        }
    }
}

private func weightedValue(from table: [(value: Int, weight: Int)]) -> Int {
    let totalWeight = table.reduce(0) { $0 + $1.weight }
    var ticket = Int.random(in: 1...max(1, totalWeight))

    for item in table {
        ticket -= item.weight
        if ticket <= 0 {
            return item.value
        }
    }

    return table.last?.value ?? 0
}
