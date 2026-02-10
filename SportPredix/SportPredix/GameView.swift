//
//  GameView.swift
//  SportPredix
//
//  Created by Francesco on 16/01/26.
//

import SwiftUI

struct GamesView: View {
    let games = [
        ("Gratta e Vinci", "sparkles", Color.accentCyan),
        ("Slot Machine", "slot.machine", Color.pink),
        ("Crazy Time", "clock.badge", Color.orange),
        ("Roulette", "circle.grid.cross", Color.green),
        ("Blackjack", "suit.club", Color.purple),
        ("Poker", "suit.spade", Color.yellow)
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Grid giochi
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(games, id: \.0) { game in
                        GameButton(
                            title: game.0,
                            icon: game.1,
                            color: game.2
                        )
                        .environmentObject(vm)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Info footer
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentCyan)
                            .font(.caption)
                        
                        Text("Gioco responsabile • Maggiorenni • Vietato ai minori")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Text("Le vincite sono virtuali")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct GameButton: View {
    let title: String
    let icon: String
    let color: Color
    @State private var showGame = false
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        Button {
            // Verifica saldo per Gratta e Vinci
            if title == "Gratta e Vinci" && vm.balance < 50 {
                // Feedback di errore
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                return
            }
            
            // Feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            showGame = true
        } label: {
            VStack(spacing: 15) {
                // Icona con effetto
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(color)
                        .shadow(color: color.opacity(0.5), radius: 5)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Prezzo per Gratta e Vinci
                if title == "Gratta e Vinci" {
                    Text("€50")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                } else {
                    Text("Gioca")
                        .font(.caption)
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            .frame(width: 160, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .sheet(isPresented: $showGame) {
            if title == "Gratta e Vinci" {
                ScratchCardView(balance: $vm.balance)
            } else if title == "Slot Machine" {
                SlotMachineView(balance: $vm.balance)
            } else {
                VStack {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Prossimamente...")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - GIOCO GRATTA E VINCI CORRETTO (con costo e particelle fixate)
struct ScratchCardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var scratchProgress: Double = 0.0
    @State private var prize: Int = 0
    @State private var gameState: GameState = .initial
    @State private var showInsufficientBalance = false
    @State private var animating = false
    
    enum GameState {
        case initial
        case playing
        case finished
    }
    
    let prizes = [
        (amount: 0, probability: 40),
        (amount: 50, probability: 25),
        (amount: 100, probability: 15),
        (amount: 250, probability: 10),
        (amount: 500, probability: 7),
        (amount: 1000, probability: 3)
    ]
    
    var body: some View {
        ZStack {
            // Sfondo semplice
            Color(red: 0.95, green: 0.95, blue: 0.97)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Gratta e Vinci")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Saldo")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "€%.2f", balance))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                
                Spacer()
                
                // CONTENUTO
                if gameState == .initial {
                    initialView()
                } else if gameState == .playing {
                    playingView()
                } else {
                    resultView()
                }
                
                Spacer()
            }
        }
        .onAppear {
            selectProbabilisticPrize()
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Serve €50 per giocare.\nTuo saldo: €\(balance, specifier: "%.2f")")
        }
    }
    
    // MARK: - VISTA INIZIALE
    @ViewBuilder
    private func initialView() -> some View {
        VStack(spacing: 20) {
            // Card illustrativa
            VStack(spacing: 16) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                VStack(spacing: 4) {
                    Text("Gratta e Vinci")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Scopri il tuo premio grattando la carta")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.white)
            .cornerRadius(12)
            
            // Info
            VStack(spacing: 12) {
                InfoRow(label: "Costo", value: "€50", icon: "eurosign.circle")
                InfoRow(label: "Premio massimo", value: "€1.000", icon: "crown")
                InfoRow(label: "Probabilità vincita", value: "60%", icon: "percent")
            }
            .padding(.horizontal, 16)
            
            // Pulsante
            Button {
                startGame()
            } label: {
                HStack {
                    Text("INIZIA A GIOCARE")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
    
    // MARK: - VISTA GIOCO
    @ViewBuilder
    private func playingView() -> some View {
        VStack(spacing: 16) {
            // Barra progresso
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progresso grattamento")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(Int(scratchProgress))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                ProgressView(value: scratchProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            }
            .padding(.horizontal, 16)
            
            // Card grattabile
            ScratchableCard(
                prize: prize,
                onScratch: { progress in
                    scratchProgress = progress
                    if progress >= 75 {
                        revealCard()
                    }
                }
            )
            .frame(height: 320)
            .padding(.horizontal, 16)
            
            // Istruzioni
            HStack(spacing: 8) {
                Image(systemName: "hand.raised")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Gratta l'area per scoprire il premio")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - VISTA RISULTATO
    @ViewBuilder
    private func resultView() -> some View {
        VStack(spacing: 20) {
            // Box risultato
            VStack(spacing: 16) {
                Image(systemName: prize > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(prize > 0 ? .green : .gray)
                
                VStack(spacing: 4) {
                    Text(prize > 0 ? "Hai vinto!" : "Nessun premio")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("€\(prize)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(prize > 0 ? .green : .gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color.white)
            .cornerRadius(12)
            
            // Riepilogo
            VStack(spacing: 10) {
                ResultRow(label: "Costo card", value: "-€50", color: .red)
                if prize > 0 {
                    ResultRow(label: "Premio", value: "+€\(prize)", color: .green)
                    ResultRow(
                        label: "Guadagno netto",
                        value: "€\(prize - 50)",
                        color: prize >= 50 ? .green : .orange
                    )
                    Divider()
                }
                ResultRow(
                    label: "Nuovo saldo",
                    value: "€\(balance, specifier: "%.2f")",
                    color: .black,
                    isBold: true
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            
            // Pulsanti
            HStack(spacing: 12) {
                Button {
                    playAgain()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Rigioca")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Menu")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.orange)
                    .background(Color.white)
                    .border(Color.orange, width: 1)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
    
    // MARK: - FUNZIONI
    private func startGame() {
        guard balance >= 50 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 50
        gameState = .playing
        scratchProgress = 0
        selectProbabilisticPrize()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func revealCard() {
        if animating { return }
        animating = true
        
        withAnimation(.easeIn(duration: 0.5)) {
            gameState = .finished
        }
        
        if prize > 0 {
            balance += Double(prize)
            launchConfetti()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    private func playAgain() {
        animating = false
        withAnimation(.easeOut(duration: 0.3)) {
            scratchProgress = 0
            gameState = .initial
            confetti.removeAll()
        }
    }
    
    private func selectProbabilisticPrize() {
        let totalProbability = prizes.reduce(0) { $0 + $1.probability }
        var random = Int.random(in: 1...totalProbability)
        
        for prizeItem in prizes {
            if random <= prizeItem.probability {
                prize = prizeItem.amount
                return
            }
            random -= prizeItem.probability
        }
    }
    
    private func launchConfetti() {
        confetti.removeAll()
        
        for _ in 0..<40 {
            confetti.append(
                Confetti(
                    id: UUID(),
                    x: CGFloat.random(in: 30...UIScreen.main.bounds.width - 30),
                    y: -10,
                    color: [.yellow, .orange, .green].randomElement()!,
                    size: CGFloat.random(in: 6...12),
                    speed: CGFloat.random(in: 3...6)
                )
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                confetti.removeAll()
            }
        }
    }
}

// MARK: - CARD GRATTABILE
struct ScratchableCard: View {
    let prize: Int
    var onScratch: (Double) -> Void
    
    @State private var touchPoints: [CGPoint] = []
    @State private var scratchedPercentage: Double = 0
    
    var body: some View {
        ZStack {
            // Card con premio
            VStack(spacing: 20) {
                Spacer()
                VStack(spacing: 8) {
                    Text("€\(prize)")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text(prize > 0 ? "VINCITA" : "RITENTA")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.5, blue: 0.8),
                        Color(red: 0.15, green: 0.4, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Layer grattabile
            ScratchOverlay(
                touchPoints: $touchPoints,
                onScratch: { percentage in
                    scratchedPercentage = percentage
                    onScratch(percentage)
                }
            )
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1, green: 0.8, blue: 0.2),
                        Color(red: 1, green: 0.75, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
    }
}

// MARK: - SCRATCH OVERLAY
struct ScratchOverlay: UIViewRepresentable {
    @Binding var touchPoints: [CGPoint]
    var onScratch: (Double) -> Void
    
    func makeUIView(context: Context) -> ScratchOverlayView {
        let view = ScratchOverlayView()
        view.onScratch = onScratch
        view.touchPointsBinding = $touchPoints
        return view
    }
    
    func updateUIView(_ uiView: ScratchOverlayView, context: Context) {}
}

class ScratchOverlayView: UIView {
    var onScratch: ((Double) -> Void)?
    var touchPointsBinding: Binding<[CGPoint]>?
    private var scratchedArea: CGFloat = 0
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        touchPointsBinding?.wrappedValue.append(point)
        scratchedArea += 0.5
        
        let totalArea = bounds.width * bounds.height
        let percentage = min((scratchedArea / (totalArea / 100)) * 0.8, 100)
        
        onScratch?(percentage)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // Disegna il layer grattabile
        context?.setFillColor(UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 1).cgColor)
        context?.fill(rect)
        
        // Disegna le aree grattate
        context?.setBlendMode(.clear)
        if let binding = touchPointsBinding {
            for point in binding.wrappedValue {
                let circleRect = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
                context?.fillEllipse(in: circleRect)
            }
        }
    }
}

// MARK: - COMPONENTI SEMPLICI
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    let color: Color
    var isBold = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: isBold ? .semibold : .regular))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: isBold ? .bold : .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - SLOT MACHINE VERSIONE SEMPLIFICATA
struct SlotMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var gameState: GameState = .initial
    @State private var reels: [SlotReel] = [
        SlotReel(),
        SlotReel(),
        SlotReel()
    ]
    @State private var winAmount: Int = 0
    @State private var isSpinning = false
    @State private var confetti: [Confetti] = []
    @State private var showInsufficientBalance = false
    
    enum GameState {
        case initial
        case spinning
        case finished
    }
    
    let symbols = ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"]
    
    var body: some View {
        ZStack {
            // Sfondo semplice
            Color(red: 0.95, green: 0.95, blue: 0.97)
                .ignoresSafeArea()
            
            // Confetti
            ForEach(confetti.indices, id: \.self) { index in
                ConfettiView(confetto: confetti[index])
            }
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Slot Machine")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Saldo")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "€%.2f", balance))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                
                Spacer()
                
                // CONTENUTO
                if gameState == .initial {
                    initialView()
                } else if gameState == .spinning {
                    spinningView()
                } else {
                    resultView()
                }
                
                Spacer()
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Serve €10 per giocare.\nTuo saldo: €\(balance, specifier: "%.2f")")
        }
    }
    
    // MARK: - VISTA INIZIALE
    @ViewBuilder
    private func initialView() -> some View {
        VStack(spacing: 20) {
            // Illustrazione
            VStack(spacing: 16) {
                Image(systemName: "slot.machine")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                VStack(spacing: 4) {
                    Text("Slot Machine")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Fai girare i cilindri e vinci!")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.white)
            .cornerRadius(12)
            
            // Info
            VStack(spacing: 12) {
                InfoRow(label: "Costo per giro", value: "€10", icon: "eurosign.circle")
                InfoRow(label: "Premio massimo", value: "€500", icon: "crown")
                InfoRow(label: "3 simboli uguali", value: "Vincita!", icon: "checkmark.circle")
            }
            .padding(.horizontal, 16)
            
            // Pulsante
            Button {
                startSpin()
            } label: {
                HStack {
                    Text("INIZIA A GIOCARE")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
    
    // MARK: - VISTA SPINNING
    @ViewBuilder
    private func spinningView() -> some View {
        VStack(spacing: 20) {
            // Reels container
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        SlotReelView(
                            symbols: symbols,
                            currentIndex: $reels[index].currentIndex,
                            isSpinning: isSpinning
                        )
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
            }
            
            // Info spinning
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                    Text("La macchina sta girando...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Pulsante disabilitato
            Button {
                // Disabled durante spin
            } label: {
                HStack {
                    Text("GIRA")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white.opacity(0.5))
                .background(Color.red.opacity(0.5))
                .cornerRadius(8)
            }
            .disabled(true)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - VISTA RISULTATO
    @ViewBuilder
    private func resultView() -> some View {
        VStack(spacing: 20) {
            // Reels finali
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        VStack {
                            Text(symbols[reels[index].currentIndex])
                                .font(.system(size: 56))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            
            // Risultato
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: winAmount > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(winAmount > 0 ? .green : .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(winAmount > 0 ? "Hai vinto!" : "Nessuna vincita")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("€\(winAmount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(winAmount > 0 ? .green : .gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            // Riepilogo
            VStack(spacing: 10) {
                ResultRow(label: "Costo giro", value: "-€10", color: .red)
                if winAmount > 0 {
                    ResultRow(label: "Vincita", value: "+€\(winAmount)", color: .green)
                    ResultRow(
                        label: "Guadagno netto",
                        value: "€\(winAmount - 10)",
                        color: winAmount >= 10 ? .green : .orange
                    )
                    Divider()
                }
                ResultRow(
                    label: "Nuovo saldo",
                    value: "€\(balance, specifier: "%.2f")",
                    color: .black,
                    isBold: true
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(8)
            
            Spacer()
            
            // Pulsanti
            HStack(spacing: 12) {
                Button {
                    playAgain()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Gioca Ancora")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Menu")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.red)
                    .background(Color.white)
                    .border(Color.red, width: 1)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - FUNZIONI
    private func startSpin() {
        guard balance >= 10 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 10
        gameState = .spinning
        isSpinning = true
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animazione spinning
        _ = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timerRef in
            for i in 0..<3 {
                reels[i].currentIndex = Int.random(in: 0..<symbols.count)
            }
            
            // Stop dopo ~2.5 secondi
            if timerRef.timeElapsed > 2.5 {
                timerRef.invalidate()
                stopSpin()
            }
        }
    }
    
    private func stopSpin() {
        isSpinning = false
        
        // Check vincita
        let symbol1 = reels[0].currentIndex
        let symbol2 = reels[1].currentIndex
        let symbol3 = reels[2].currentIndex
        
        if symbol1 == symbol2 && symbol2 == symbol3 {
            // Vincita!
            winAmount = calculateWinAmount(symbol: symbol1)
            balance += Double(winAmount)
            launchConfetti()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // Nessuna vincita
            winAmount = 0
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            gameState = .finished
        }
    }
    
    private func calculateWinAmount(symbol: Int) -> Int {
        switch symbols[symbol] {
        case "🍒": return 50
        case "🍋": return 75
        case "🍊": return 100
        case "🔔": return 150
        case "💎": return 300
        case "7️⃣": return 500
        default: return 0
        }
    }
    
    private func playAgain() {
        withAnimation(.easeOut(duration: 0.3)) {
            gameState = .initial
            confetti.removeAll()
            winAmount = 0
            reels = [SlotReel(), SlotReel(), SlotReel()]
        }
    }
    
    private func launchConfetti() {
        confetti.removeAll()
        
        for _ in 0..<50 {
            confetti.append(
                Confetti(
                    id: UUID(),
                    x: CGFloat.random(in: 30...UIScreen.main.bounds.width - 30),
                    y: -10,
                    color: [.yellow, .red, .green].randomElement()!,
                    size: CGFloat.random(in: 6...12),
                    speed: CGFloat.random(in: 3...6)
                )
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                confetti.removeAll()
            }
        }
    }
}

// MARK: - SLOT REEL MODEL
struct SlotReel {
    var currentIndex: Int = Int.random(in: 0..<6)
}

// MARK: - SLOT REEL VIEW CON ANIMAZIONE REALISTICA
struct SlotReelView: View {
    let symbols: [String]
    @Binding var currentIndex: Int
    let isSpinning: Bool
    
    @State private var offset: CGFloat = 0
    @State private var velocity: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.15),
                            Color(red: 0.1, green: 0.1, blue: 0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 0) {
                // Simboli giranti
                VStack(spacing: 40) {
                    ForEach(0..<3) { i in
                        Text(symbols[(currentIndex + i) % symbols.count])
                            .font(.system(size: 48))
                    }
                }
                .offset(y: offset)
                .animation(
                    isSpinning ? nil : .easeOut(duration: 0.3),
                    value: offset
                )
            }
            
            // Maschere top/bottom
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        .clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color(red: 0.95, green: 0.95, blue: 0.97)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
            }
            .ignoresSafeArea()
            
            // Cornice centrale
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 2)
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            if isSpinning {
                offset += 50
                if offset > 100 {
                    offset -= 100 * CGFloat(symbols.count)
                }
            }
        }
    }
}

// MARK: - CONFETTI
struct Confetti: Identifiable {
    let id: UUID = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let speed: CGFloat
}

// MARK: - CONFETTI VIEW
struct ConfettiView: View {
    let confetto: Confetti
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(confetto.color)
            .frame(width: confetto.size, height: confetto.size)
            .offset(x: confetto.x, y: confetto.y + offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 3)) {
                    offset = UIScreen.main.bounds.height + 50
                }
                withAnimation(.easeOut(duration: 3)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - COMING SOON VIEW
struct ComingSoonView: View {
    let gameName: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock.badge")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("\(gameName) - Presto disponibile")
                .font(.title.bold())
                .foregroundColor(.black)
            
            Text("Questo gioco sarà disponibile nelle prossime versioni")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Torna Indietro")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
    }
}
