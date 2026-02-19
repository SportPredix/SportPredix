//
//  GameView.swift
//  SportPredix
//

import SwiftUI
import Foundation

private enum CasinoGame: String, CaseIterable, Identifiable {
    case scratch = "Gratta e Vinci"
    case slot = "Slot Machine"
    case crazyTime = "Crazy Time"
    case roulette = "Roulette"
    case blackjack = "Blackjack"
    case poker = "Poker"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scratch:
            return "sparkles"
        case .slot:
            return "slot.machine"
        case .crazyTime:
            return "clock.badge"
        case .roulette:
            return "circle.grid.cross"
        case .blackjack:
            return "suit.club"
        case .poker:
            return "suit.spade"
        }
    }

    var accent: Color {
        switch self {
        case .scratch:
            return .accentCyan
        case .slot:
            return .pink
        case .crazyTime:
            return .orange
        case .roulette:
            return .green
        case .blackjack:
            return .indigo
        case .poker:
            return .yellow
        }
    }

    var stake: Double {
        switch self {
        case .scratch:
            return 15
        case .slot:
            return 10
        case .crazyTime:
            return 20
        case .roulette:
            return 15
        case .blackjack:
            return 25
        case .poker:
            return 20
        }
    }
}

private struct CasinoGameHostView: View {
    let game: CasinoGame
    @Binding var balance: Double

    var body: some View {
        switch game {
        case .scratch:
            ScratchCardView(balance: $balance)
        case .slot:
            SlotMachineView(balance: $balance)
        case .crazyTime:
            CrazyTimeView(balance: $balance)
        case .roulette:
            RouletteView(balance: $balance)
        case .blackjack:
            BlackjackView(balance: $balance)
        case .poker:
            PokerView(balance: $balance)
        }
    }
}

private struct GameShell<Content: View>: View {
    let game: CasinoGame
    @Binding var balance: Double
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(game: CasinoGame, balance: Binding<Double>, @ViewBuilder content: () -> Content) {
        self.game = game
        self._balance = balance
        self.content = content()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(game.accent)
                            .frame(width: 32, height: 32)
                    }

                    Text(game.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Label(balance.moneyLabel, systemImage: "creditcard.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(game.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Divider()
                    .overlay(game.accent.opacity(0.35))

                ScrollView {
                    content
                        .padding(20)
                }
            }
        }
    }
}

private struct PanelCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String
    let valueColor: Color

    init(title: String, value: String, valueColor: Color = .white) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .font(.system(.body, design: .monospaced).bold())
        }
    }
}

private extension Double {
    var moneyLabel: String {
        String(format: "EUR %.2f", self)
    }
}

private struct CasinoCard: Identifiable, Hashable {
    enum Suit: String, CaseIterable {
        case hearts = "H"
        case diamonds = "D"
        case clubs = "C"
        case spades = "S"

        var color: Color {
            switch self {
            case .hearts, .diamonds:
                return .red
            case .clubs, .spades:
                return .white
            }
        }
    }

    let id = UUID()
    let rank: Int
    let suit: Suit

    var rankLabel: String {
        switch rank {
        case 14:
            return "A"
        case 13:
            return "K"
        case 12:
            return "Q"
        case 11:
            return "J"
        default:
            return "\(rank)"
        }
    }

    var blackjackValue: Int {
        if rank == 14 {
            return 11
        }
        return min(rank, 10)
    }
}

private struct PlayingCardView: View {
    let card: CasinoCard
    var faceDown = false
    var highlighted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(faceDown ? Color.gray.opacity(0.35) : Color(red: 0.11, green: 0.11, blue: 0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(highlighted ? Color.accentCyan : Color.white.opacity(0.2), lineWidth: highlighted ? 2 : 1)
                )

            if faceDown {
                Image(systemName: "questionmark")
                    .font(.title2.bold())
                    .foregroundColor(.white.opacity(0.9))
            } else {
                VStack(spacing: 4) {
                    Text(card.rankLabel)
                        .font(.headline.bold())
                    Text(card.suit.rawValue)
                        .font(.title3.bold())
                }
                .foregroundColor(card.suit.color)
            }
        }
        .frame(width: 58, height: 86)
    }
}

private func drawCard() -> CasinoCard {
    CasinoCard(
        rank: Int.random(in: 2...14),
        suit: CasinoCard.Suit.allCases.randomElement() ?? .spades
    )
}

// MARK: - SCRATCH CARD

struct ScratchCardView: View {
    @Binding var balance: Double

    @State private var hiddenSymbols = Array(repeating: 0, count: 9)
    @State private var revealedIndexes: Set<Int> = []
    @State private var roundActive = false
    @State private var roundResolved = false
    @State private var payout: Double = 0
    @State private var resultText = "Acquista un biglietto per iniziare."
    @State private var showInsufficientBalance = false

    private let symbols = ["star.fill", "crown.fill", "bolt.fill", "flame.fill", "leaf.fill"]

    private var stake: Double { CasinoGame.scratch.stake }

    var body: some View {
        GameShell(game: .scratch, balance: $balance) {
            VStack(spacing: 18) {
                PanelCard {
                    Text("Biglietto istantaneo")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Costo \(stake.moneyLabel). Rivela 9 caselle: con 3 simboli uguali vinci.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<9, id: \.self) { index in
                        Button {
                            revealCell(index)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(revealedIndexes.contains(index) ? Color.accentCyan.opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )

                                if revealedIndexes.contains(index) {
                                    Image(systemName: symbols[hiddenSymbols[index]])
                                        .font(.title2)
                                        .foregroundColor(.accentCyan)
                                } else {
                                    Text("?")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 70)
                        }
                        .disabled(!roundActive || revealedIndexes.contains(index))
                    }
                }

                PanelCard {
                    Text(resultText)
                        .foregroundColor(.white)

                    SummaryRow(title: "Puntata", value: stake.moneyLabel, valueColor: .red)
                    SummaryRow(title: "Vincita", value: payout.moneyLabel, valueColor: payout > 0 ? .green : .gray)
                    SummaryRow(title: "Netto", value: (payout - stake).moneyLabel, valueColor: payout >= stake ? .green : .orange)
                }

                Button(action: startRound) {
                    Text(roundResolved || !roundActive ? "Nuovo biglietto" : "Biglietto in corso")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accentCyan)
                        .cornerRadius(14)
                }
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Servono almeno \(stake.moneyLabel) per giocare.")
        }
    }

    private func startRound() {
        guard balance >= stake else {
            showInsufficientBalance = true
            return
        }

        balance -= stake
        hiddenSymbols = (0..<9).map { _ in Int.random(in: 0..<symbols.count) }
        revealedIndexes.removeAll()
        payout = 0
        roundActive = true
        roundResolved = false
        resultText = "Tocca le caselle e scopri se hai fatto 3 simboli uguali."
    }

    private func revealCell(_ index: Int) {
        guard roundActive else { return }
        guard !revealedIndexes.contains(index) else { return }

        revealedIndexes.insert(index)

        if revealedIndexes.count == hiddenSymbols.count {
            resolveRound()
        }
    }

    private func resolveRound() {
        roundActive = false
        roundResolved = true

        var counts: [Int: Int] = [:]
        for symbol in hiddenSymbols {
            counts[symbol, default: 0] += 1
        }

        let maxCount = counts.values.max() ?? 0
        let multiplier: Double

        switch maxCount {
        case 6...:
            multiplier = 12
        case 5:
            multiplier = 7
        case 4:
            multiplier = 4
        case 3:
            multiplier = 2
        default:
            multiplier = 0
        }

        payout = stake * multiplier

        if payout > 0 {
            balance += payout
            resultText = "Hai centrato \(maxCount) simboli uguali: vinci \(payout.moneyLabel)."
        } else {
            resultText = "Nessuna combinazione utile. Riprova con un altro biglietto."
        }
    }
}

// MARK: - SLOT MACHINE

struct SlotMachineView: View {
    @Binding var balance: Double

    @State private var reels = [0, 1, 2]
    @State private var isSpinning = false
    @State private var payout: Double = 0
    @State private var resultText = "Premi Gira per avviare i rulli."
    @State private var showInsufficientBalance = false

    private let symbols = ["suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "suit.spade.fill", "star.fill", "crown.fill"]
    private let tripleMultipliers: [Double] = [4, 5, 6, 7, 10, 15]
    private let pairMultipliers: [Double] = [1.2, 1.4, 1.6, 1.8, 2.2, 2.8]

    private var stake: Double { CasinoGame.slot.stake }

    var body: some View {
        GameShell(game: .slot, balance: $balance) {
            VStack(spacing: 18) {
                PanelCard {
                    Text("Slot a 3 rulli")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Costo giro \(stake.moneyLabel). Tris e coppie pagano in base al simbolo.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.pink.opacity(0.35), lineWidth: 1)
                                )

                            Image(systemName: symbols[reels[index]])
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.pink)
                                .symbolEffect(.bounce, value: reels[index])
                        }
                        .frame(width: 90, height: 110)
                    }
                }

                PanelCard {
                    Text(resultText)
                        .foregroundColor(.white)
                    SummaryRow(title: "Puntata", value: stake.moneyLabel, valueColor: .red)
                    SummaryRow(title: "Vincita", value: payout.moneyLabel, valueColor: payout > 0 ? .green : .gray)
                }

                Button(action: startSpin) {
                    HStack(spacing: 8) {
                        if isSpinning {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(isSpinning ? "Giro in corso..." : "Gira")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.pink)
                    .cornerRadius(14)
                }
                .disabled(isSpinning)
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Servono almeno \(stake.moneyLabel) per giocare.")
        }
    }

    private func startSpin() {
        guard !isSpinning else { return }
        guard balance >= stake else {
            showInsufficientBalance = true
            return
        }

        balance -= stake
        payout = 0
        resultText = "Giro in corso..."
        isSpinning = true

        Task { @MainActor in
            for _ in 0..<20 {
                reels = (0..<3).map { _ in Int.random(in: 0..<symbols.count) }
                try? await Task.sleep(nanoseconds: 90_000_000)
            }

            isSpinning = false
            resolveSpin()
        }
    }

    private func resolveSpin() {
        var counts: [Int: Int] = [:]
        reels.forEach { counts[$0, default: 0] += 1 }

        if let tripleSymbol = counts.first(where: { $0.value == 3 })?.key {
            payout = stake * tripleMultipliers[tripleSymbol]
            resultText = "Tris! Incassi \(payout.moneyLabel)."
        } else if let pairSymbol = counts.first(where: { $0.value == 2 })?.key {
            payout = stake * pairMultipliers[pairSymbol]
            resultText = "Coppia! Incassi \(payout.moneyLabel)."
        } else {
            payout = 0
            resultText = "Nessuna combinazione vincente."
        }

        if payout > 0 {
            balance += payout
        }
    }
}

// MARK: - CRAZY TIME

private struct CrazySegment: Identifiable {
    let id = UUID()
    let label: String
    let weight: Int
    let multiplier: Double
}

private struct CrazyTimeView: View {
    @Binding var balance: Double

    @State private var selectedLabel = "2"
    @State private var landedLabel: String?
    @State private var payout: Double = 0
    @State private var isSpinning = false
    @State private var resultText = "Scegli una puntata e gira la ruota."
    @State private var showInsufficientBalance = false

    private var stake: Double { CasinoGame.crazyTime.stake }

    private let segments = [
        CrazySegment(label: "1", weight: 28, multiplier: 1),
        CrazySegment(label: "2", weight: 22, multiplier: 2),
        CrazySegment(label: "5", weight: 14, multiplier: 5),
        CrazySegment(label: "10", weight: 7, multiplier: 10),
        CrazySegment(label: "BONUS", weight: 3, multiplier: 25)
    ]

    var body: some View {
        GameShell(game: .crazyTime, balance: $balance) {
            VStack(spacing: 18) {
                PanelCard {
                    Text("Ruota multipli")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Punta su 1, 2, 5, 10 o BONUS. Se esce la tua scelta, incassi il moltiplicatore.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                PanelCard {
                    Text("Scelta")
                        .foregroundColor(.white)
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(segments.map(\.label), id: \.self) { label in
                            Button(action: { selectedLabel = label }) {
                                Text(label)
                                    .font(.subheadline.bold())
                                    .foregroundColor(selectedLabel == label ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(selectedLabel == label ? Color.orange : Color.white.opacity(0.08))
                                    .cornerRadius(10)
                            }
                        }
                    }

                    if let landedLabel {
                        Text("Uscita: \(landedLabel)")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                    }
                }

                PanelCard {
                    Text(resultText)
                        .foregroundColor(.white)
                    SummaryRow(title: "Puntata", value: stake.moneyLabel, valueColor: .red)
                    SummaryRow(title: "Vincita", value: payout.moneyLabel, valueColor: payout > 0 ? .green : .gray)
                }

                Button(action: spinWheel) {
                    HStack(spacing: 8) {
                        if isSpinning {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(isSpinning ? "Ruota in movimento..." : "Gira ruota")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.orange)
                    .cornerRadius(14)
                }
                .disabled(isSpinning)
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Servono almeno \(stake.moneyLabel) per giocare.")
        }
    }

    private func spinWheel() {
        guard !isSpinning else { return }
        guard balance >= stake else {
            showInsufficientBalance = true
            return
        }

        balance -= stake
        payout = 0
        landedLabel = nil
        resultText = "Ruota in movimento..."
        isSpinning = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 850_000_000)

            let weightedPool = segments.flatMap { Array(repeating: $0, count: $0.weight) }
            let landed = weightedPool.randomElement() ?? segments[0]

            landedLabel = landed.label
            isSpinning = false

            if selectedLabel == landed.label {
                payout = stake * landed.multiplier
                balance += payout
                resultText = "Presa! Hai centrato \(landed.label) e vinto \(payout.moneyLabel)."
            } else {
                payout = 0
                resultText = "E uscito \(landed.label). Nessuna vincita in questo giro."
            }
        }
    }
}

// MARK: - ROULETTE

private enum RouletteBet: String, CaseIterable, Identifiable {
    case red = "Rosso"
    case black = "Nero"
    case even = "Pari"
    case odd = "Dispari"
    case number = "Numero"

    var id: String { rawValue }
}

private enum RoulettePocketColor {
    case red
    case black
    case green
}

private struct RouletteView: View {
    @Binding var balance: Double

    @State private var selectedBet: RouletteBet = .red
    @State private var selectedNumber = 17
    @State private var lastNumber: Int?
    @State private var payout: Double = 0
    @State private var resultText = "Scegli una giocata e avvia la ruota."
    @State private var isSpinning = false
    @State private var showInsufficientBalance = false

    private let redNumbers: Set<Int> = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]

    private var stake: Double { CasinoGame.roulette.stake }

    var body: some View {
        GameShell(game: .roulette, balance: $balance) {
            VStack(spacing: 18) {
                PanelCard {
                    Text("Roulette europea")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Rosso/Nero/Pari/Dispari pagano x2. Numero secco paga x36.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                PanelCard {
                    Text("Tipo puntata")
                        .foregroundColor(.white)
                        .font(.headline)

                    Picker("Puntata", selection: $selectedBet) {
                        ForEach(RouletteBet.allCases) { bet in
                            Text(bet.rawValue).tag(bet)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedBet == .number {
                        Stepper("Numero: \(selectedNumber)", value: $selectedNumber, in: 0...36)
                            .foregroundColor(.white)
                    }
                }

                if let lastNumber {
                    PanelCard {
                        Text("Ultima uscita")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("\(lastNumber)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(pocketColor(for: lastNumber).color)
                            .cornerRadius(12)
                    }
                }

                PanelCard {
                    Text(resultText)
                        .foregroundColor(.white)
                    SummaryRow(title: "Puntata", value: stake.moneyLabel, valueColor: .red)
                    SummaryRow(title: "Vincita", value: payout.moneyLabel, valueColor: payout > 0 ? .green : .gray)
                }

                Button(action: spinRoulette) {
                    HStack(spacing: 8) {
                        if isSpinning {
                            ProgressView()
                                .tint(.black)
                        }
                        Text(isSpinning ? "Ruota in corsa..." : "Lancia pallina")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.green)
                    .cornerRadius(14)
                }
                .disabled(isSpinning)
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Servono almeno \(stake.moneyLabel) per giocare.")
        }
    }

    private func spinRoulette() {
        guard !isSpinning else { return }
        guard balance >= stake else {
            showInsufficientBalance = true
            return
        }

        balance -= stake
        payout = 0
        resultText = "Ruota in corsa..."
        isSpinning = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)

            let number = Int.random(in: 0...36)
            lastNumber = number
            isSpinning = false

            let winner = didWin(bet: selectedBet, number: number)
            if winner {
                let multiplier: Double = selectedBet == .number ? 36 : 2
                payout = stake * multiplier
                balance += payout
                resultText = "Colpo preso! Numero uscito \(number), incasso \(payout.moneyLabel)."
            } else {
                resultText = "Numero uscito \(number). Questa volta non hai preso la giocata."
            }
        }
    }

    private func didWin(bet: RouletteBet, number: Int) -> Bool {
        switch bet {
        case .red:
            return pocketColor(for: number) == .red
        case .black:
            return pocketColor(for: number) == .black
        case .even:
            return number != 0 && number.isMultiple(of: 2)
        case .odd:
            return number % 2 == 1
        case .number:
            return number == selectedNumber
        }
    }

    private func pocketColor(for number: Int) -> RoulettePocketColor {
        if number == 0 {
            return .green
        }
        return redNumbers.contains(number) ? .red : .black
    }
}

private extension RoulettePocketColor {
    var color: Color {
        switch self {
        case .red:
            return .red
        case .black:
            return .black
        case .green:
            return .green
        }
    }
}

// MARK: - BLACKJACK

private enum BlackjackPhase {
    case idle
    case playerTurn
    case finished
}

private struct BlackjackView: View {
    @Binding var balance: Double

    @State private var playerCards: [CasinoCard] = []
    @State private var dealerCards: [CasinoCard] = []
    @State private var hideDealerSecondCard = true
    @State private var phase: BlackjackPhase = .idle
    @State private var payout: Double = 0
    @State private var resultText = "Distribuisci per iniziare una mano."
    @State private var showInsufficientBalance = false

    private var stake: Double { CasinoGame.blackjack.stake }

    var body: some View {
        GameShell(game: .blackjack, balance: $balance) {
            VStack(spacing: 18) {
                PanelCard {
                    Text("Blackjack 21")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Vittoria x2, push rimborsa la puntata, blackjack naturale x2.5.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                PanelCard {
                    Text("Banco")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 10) {
                        ForEach(Array(dealerCards.enumerated()), id: \.element.id) { index, card in
                            PlayingCardView(card: card, faceDown: hideDealerSecondCard && index == 1)
                        }
                    }

                    Text("Valore: \(dealerVisibleValue)")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                PanelCard {
                    Text("Giocatore")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 10) {
                        ForEach(playerCards) { card in
                            PlayingCardView(card: card)
                        }
                    }

                    Text("Valore: \(handValue(playerCards))")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                PanelCard {
                    Text(resultText)
                        .foregroundColor(.white)
                    SummaryRow(title: "Puntata", value: stake.moneyLabel, valueColor: .red)
                    SummaryRow(title: "Vincita", value: payout.moneyLabel, valueColor: payout > 0 ? .green : .gray)
                }

                if phase == .playerTurn {
                    HStack(spacing: 12) {
                        Button(action: hit) {
                            Text("Carta")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.indigo)
                                .cornerRadius(14)
                        }

                        Button(action: stand) {
                            Text("Stai")
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.indigo.opacity(0.8))
                                .cornerRadius(14)
                        }
                    }
                } else {
                    Button(action: deal) {
                        Text(phase == .finished ? "Nuova mano" : "Distribuisci")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.indigo)
                            .cornerRadius(14)
                    }
                }
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Servono almeno \(stake.moneyLabel) per giocare.")
        }
    }

    private var dealerVisibleValue: Int {
        if hideDealerSecondCard, let first = dealerCards.first {
            return handValue([first])
        }
        return handValue(dealerCards)
    }

    private func deal() {
        guard balance >= stake else {
            showInsufficientBalance = true
            return
        }

        balance -= stake
        payout = 0
        resultText = "Mano in corso."

        playerCards = [drawCard(), drawCard()]
        dealerCards = [drawCard(), drawCard()]
        hideDealerSecondCard = true
        phase = .playerTurn

        let playerValue = handValue(playerCards)
        if playerValue == 21 {
            stand(isNaturalBlackjack: true)
        }
    }

    private func hit() {
        guard phase == .playerTurn else { return }

        playerCards.append(drawCard())
        let value = handValue(playerCards)

        if value > 21 {
            hideDealerSecondCard = false
            payout = 0
            resultText = "Sballato a \(value). Mano persa."
            phase = .finished
        }
    }

    private func stand(isNaturalBlackjack: Bool = false) {
        guard phase == .playerTurn else { return }

        hideDealerSecondCard = false

        while handValue(dealerCards) < 17 {
            dealerCards.append(drawCard())
        }

        resolveRound(isNaturalBlackjack: isNaturalBlackjack)
    }

    private func resolveRound(isNaturalBlackjack: Bool) {
        let playerValue = handValue(playerCards)
        let dealerValue = handValue(dealerCards)

        if playerValue > 21 {
            payout = 0
            resultText = "Hai superato 21. Mano persa."
        } else if dealerValue > 21 {
            payout = stake * 2
            balance += payout
            resultText = "Il banco sballa a \(dealerValue). Vinci \(payout.moneyLabel)."
        } else if isNaturalBlackjack && playerValue == 21 && dealerValue != 21 {
            payout = stake * 2.5
            balance += payout
            resultText = "Blackjack naturale! Vinci \(payout.moneyLabel)."
        } else if playerValue > dealerValue {
            payout = stake * 2
            balance += payout
            resultText = "\(playerValue) contro \(dealerValue): mano vinta."
        } else if playerValue == dealerValue {
            payout = stake
            balance += payout
            resultText = "Push a \(playerValue). Puntata restituita."
        } else {
            payout = 0
            resultText = "\(playerValue) contro \(dealerValue): mano persa."
        }

        phase = .finished
    }

    private func handValue(_ cards: [CasinoCard]) -> Int {
        var total = cards.reduce(0) { $0 + $1.blackjackValue }
        var aceCount = cards.filter { $0.rank == 14 }.count

        while total > 21 && aceCount > 0 {
            total -= 10
            aceCount -= 1
        }

        return total
    }
}

// MARK: - POKER

private enum PokerPhase {
    case idle
    case selectingCards
    case finished
}

private enum PokerRank: String {
    case highCard = "Carta alta"
    case onePair = "Coppia"
    case twoPair = "Doppia coppia"
    case threeOfAKind = "Tris"
    case straight = "Scala"
    case flush = "Colore"
    case fullHouse = "Full"
    case fourOfAKind = "Poker"
    case straightFlush = "Scala colore"
    case royalFlush = "Scala reale"

    var multiplier: Double {
        switch self {
        case .highCard:
            return 0
        case .onePair:
            return 1.2
        case .twoPair:
            return 2
        case .threeOfAKind:
            return 3.5
        case .straight:
            return 5
        case .flush:
            return 7
        case .fullHouse:
            return 10
        case .fourOfAKind:
            return 20
        case .straightFlush:
            return 40
        case .royalFlush:
            return 100
        }
    }
}

private struct PokerView: View {
    @Binding var balance: Double

    @State private var hand: [CasinoCard] = []
    @State private var selectedForChange: Set<Int> = []
    @State private var phase: PokerPhase = .idle
    @State private var rank: PokerRank = .highCard
    @State private var payout: Double = 0
    @State private var resultText = "Distribuisci per ricevere 5 carte."
    @State private var showInsufficientBalance = false

    private var stake: Double { CasinoGame.poker.stake }

    var body: some View {
        GameShell(game: .poker, balance: $balance) {
            VStack(spacing: 18) {
                PanelCard {
                    Text("Video poker draw")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Seleziona fino a 3 carte da cambiare, poi valuta la mano finale.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                PanelCard {
                    Text("Mano")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                            Button {
                                toggleCard(index)
                            } label: {
                                PlayingCardView(
                                    card: card,
                                    faceDown: false,
                                    highlighted: selectedForChange.contains(index)
                                )
                            }
                            .disabled(phase != .selectingCards)
                        }
                    }

                    if phase == .selectingCards {
                        Text("Carte da cambiare: \(selectedForChange.count)/3")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    } else if phase == .finished {
                        Text("Risultato: \(rank.rawValue)")
                            .foregroundColor(.yellow)
                            .font(.subheadline.bold())
                    }
                }

                PanelCard {
                    Text(resultText)
                        .foregroundColor(.white)
                    SummaryRow(title: "Puntata", value: stake.moneyLabel, valueColor: .red)
                    SummaryRow(title: "Vincita", value: payout.moneyLabel, valueColor: payout > 0 ? .green : .gray)
                }

                if phase == .selectingCards {
                    Button(action: drawPhase) {
                        Text("Cambia carte e valuta")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.yellow)
                            .cornerRadius(14)
                    }
                } else {
                    Button(action: dealHand) {
                        Text(phase == .finished ? "Nuova mano" : "Distribuisci")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.yellow)
                            .cornerRadius(14)
                    }
                }
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Servono almeno \(stake.moneyLabel) per giocare.")
        }
    }

    private func dealHand() {
        guard balance >= stake else {
            showInsufficientBalance = true
            return
        }

        balance -= stake
        hand = (0..<5).map { _ in drawCard() }
        selectedForChange.removeAll()
        rank = .highCard
        payout = 0
        resultText = "Seleziona fino a 3 carte da cambiare."
        phase = .selectingCards
    }

    private func toggleCard(_ index: Int) {
        guard phase == .selectingCards else { return }

        if selectedForChange.contains(index) {
            selectedForChange.remove(index)
        } else if selectedForChange.count < 3 {
            selectedForChange.insert(index)
        }
    }

    private func drawPhase() {
        guard phase == .selectingCards else { return }

        for index in selectedForChange {
            hand[index] = drawCard()
        }

        selectedForChange.removeAll()
        rank = evaluatePokerRank(hand)
        payout = stake * rank.multiplier

        if payout > 0 {
            balance += payout
            resultText = "\(rank.rawValue): incassi \(payout.moneyLabel)."
        } else {
            resultText = "\(rank.rawValue): nessuna vincita su questa mano."
        }

        phase = .finished
    }

    private func evaluatePokerRank(_ hand: [CasinoCard]) -> PokerRank {
        let ranks = hand.map(\.rank).sorted()
        let suits = hand.map(\.suit)

        let isFlush = Set(suits).count == 1
        let isStraight = isStraightRanks(ranks)

        let counts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
        let sortedCounts = counts.values.sorted(by: >)

        if isStraight && isFlush && ranks == [10, 11, 12, 13, 14] {
            return .royalFlush
        }
        if isStraight && isFlush {
            return .straightFlush
        }
        if sortedCounts == [4, 1] {
            return .fourOfAKind
        }
        if sortedCounts == [3, 2] {
            return .fullHouse
        }
        if isFlush {
            return .flush
        }
        if isStraight {
            return .straight
        }
        if sortedCounts == [3, 1, 1] {
            return .threeOfAKind
        }
        if sortedCounts == [2, 2, 1] {
            return .twoPair
        }
        if sortedCounts == [2, 1, 1, 1] {
            return .onePair
        }

        return .highCard
    }

    private func isStraightRanks(_ ranks: [Int]) -> Bool {
        let unique = Array(Set(ranks)).sorted()
        guard unique.count == 5 else { return false }

        if unique == [2, 3, 4, 5, 14] {
            return true
        }

        guard let first = unique.first, let last = unique.last else { return false }
        return last - first == 4
    }
}

// MARK: - GRID ENTRY POINTS

struct GamesView: View {
    private let games = CasinoGame.allCases
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @EnvironmentObject var vm: BettingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(games) { game in
                        GameButton(title: game.rawValue, icon: game.icon, color: game.accent)
                            .environmentObject(vm)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding(.bottom, 30)
        }
        .background(Color.clear)
    }
}

struct GameButton: View {
    let title: String
    let icon: String
    let color: Color

    @State private var showGame = false
    @State private var showInsufficientBalance = false

    @EnvironmentObject var vm: BettingViewModel

    private var game: CasinoGame? {
        CasinoGame(rawValue: title)
    }

    private var subtitle: String {
        guard let game else { return "Apri" }
        return "Puntata \(Int(game.stake))"
    }

    var body: some View {
        Button {
            guard let game else {
                showGame = true
                return
            }

            if vm.balance < game.stake {
                showInsufficientBalance = true
                return
            }

            showGame = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.35))
                    .cornerRadius(10)
            }
            .frame(width: 160, height: 175)
            .background(Color.white.opacity(0.05))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showGame) {
            if let game {
                CasinoGameHostView(game: game, balance: $vm.balance)
            } else {
                ComingSoonView(gameName: title)
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) {}
        } message: {
            if let game {
                Text("Servono almeno \(game.stake.moneyLabel) per aprire questo gioco.")
            } else {
                Text("Saldo insufficiente.")
            }
        }
    }
}

struct ComingSoonView: View {
    let gameName: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "clock.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentCyan)

                Text(gameName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Modalita non disponibile in questa versione.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Chiudi")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accentCyan)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
        }
    }
}

