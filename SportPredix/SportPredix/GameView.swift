//
//  GameView.swift
//  SportPredix
//
//  Created by FINAL FIXED
//

import SwiftUI
import Combine

// MARK: - GIOCO GRATTA E VINCI - DEFINITIVO CON PREMI CORRETTI
struct ScratchCardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var scratchProgress: Double = 0.0
    @State private var prize: Int = 0
    @State private var gameState: GameState = .initial
    @State private var showInsufficientBalance = false
    
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
            Color.black.ignoresSafeArea()
            
            if gameState == .initial {
                initialView
            } else if gameState == .playing {
                playingView
            } else {
                resultView
            }
        }
        .onAppear {
            selectPrize()
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Servono €50 per giocare")
        }
    }
    
    // MARK: - INITIAL VIEW
    private var initialView: some View {
        VStack {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentCyan)
                }
                Spacer()
                Text("Gratta e Vinci")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("€\(Int(balance))")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider().background(Color.accentCyan.opacity(0.3))
            
            Spacer()
            
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.accentCyan)
                    
                    Text("Gratta e Vinci")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("€50")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.accentCyan)
                        .cornerRadius(25)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Label("Premio massimo: €1.000", systemImage: "crown.fill")
                        .foregroundColor(.yellow)
                    Label("Probabilità vincita: 60%", systemImage: "percent")
                        .foregroundColor(.green)
                    Label("Gratta per scoprire il premio", systemImage: "hand.draw.fill")
                        .foregroundColor(.accentCyan)
                }
                .font(.subheadline)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                
                Button(action: startGame) {
                    Text("GIOCA")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentCyan)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // MARK: - PLAYING VIEW
    private var playingView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentCyan)
                }
                Spacer()
                Text("Gratta e Vinci")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("€\(Int(balance))")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider().background(Color.accentCyan.opacity(0.3))
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progresso")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(scratchProgress))%")
                        .foregroundColor(.accentCyan)
                        .bold()
                }
                ProgressView(value: scratchProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentCyan))
                    .scaleEffect(x: 1, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // CARD GRATTABILE
            ZStack {
                // Sfondo premio
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .overlay(
                        VStack {
                            Text("€\(prize)")
                                .font(.system(size: 52, weight: .bold))
                                .foregroundColor(.white)
                            Text(prize > 0 ? "VINCITA" : "RITENTA")
                                .font(.headline)
                                .foregroundColor(prize > 0 ? .green : .gray)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                    )
                
                // Layer grattabile
                ScratchViewFinal(
                    progress: $scratchProgress,
                    onComplete: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            revealCard()
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [.gray, .darkGray],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .mask(RoundedRectangle(cornerRadius: 24))
            }
            .frame(height: 380)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Text("Gratta con il dito sulla carta")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 16)
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // MARK: - RESULT VIEW
    private var resultView: some View {
        VStack {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentCyan)
                }
                Spacer()
                Text("Risultato")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("€\(Int(balance))")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider().background(Color.accentCyan.opacity(0.3))
            
            Spacer()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(prize > 0 ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: prize > 0 ? "crown.fill" : "xmark")
                        .font(.system(size: 60))
                        .foregroundColor(prize > 0 ? .green : .gray)
                }
                
                Text(prize > 0 ? "HAI VINTO!" : "RITENTA")
                    .font(.title.bold())
                    .foregroundColor(prize > 0 ? .green : .gray)
                
                Text("€\(prize)")
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Costo biglietto")
                        Spacer()
                        Text("-€50")
                            .foregroundColor(.red)
                    }
                    
                    if prize > 0 {
                        HStack {
                            Text("Premio vinto")
                            Spacer()
                            Text("+€\(prize)")
                                .foregroundColor(.green)
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("Guadagno netto")
                                .bold()
                            Spacer()
                            Text("€\(prize - 50)")
                                .foregroundColor(prize >= 50 ? .green : .orange)
                                .bold()
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    HStack {
                        Text("Nuovo saldo")
                            .bold()
                        Spacer()
                        Text("€\(Int(balance))")
                            .foregroundColor(.accentCyan)
                            .bold()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                HStack(spacing: 16) {
                    Button(action: playAgain) {
                        Text("RIGIOCA")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.accentCyan)
                            .cornerRadius(16)
                    }
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("CHIUDI")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentCyan, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // MARK: - FUNCTIONS - CORRETTE!
    private func startGame() {
        guard balance >= 50 else {
            showInsufficientBalance = true
            return
        }
        balance -= 50
        selectPrize()           // Seleziona nuovo premio
        scratchProgress = 0
        gameState = .playing
    }
    
    private func revealCard() {
        // AGGIUNGE IL PREMIO UNA SOLA VOLTA
        if prize > 0 {
            balance += Double(prize)
        }
        gameState = .finished
    }
    
    private func playAgain() {
        guard balance >= 50 else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        balance -= 50
        selectPrize()           // SELEZIONA NUOVO PREMIO! (non riusa il vecchio)
        scratchProgress = 0
        gameState = .playing
    }
    
    private func selectPrize() {
        let total = prizes.reduce(0) { $0 + $1.probability }
        var random = Int.random(in: 1...total)
        for p in prizes {
            if random <= p.probability {
                prize = p.amount    // IMPOSTA IL NUOVO PREMIO
                return
            }
            random -= p.probability
        }
    }
}

// MARK: - SCRATCH VIEW FINAL
struct ScratchViewFinal: UIViewRepresentable {
    @Binding var progress: Double
    var onComplete: () -> Void
    
    func makeUIView(context: Context) -> ScratchUI {
        let view = ScratchUI()
        view.progressBinding = $progress
        view.onComplete = onComplete
        return view
    }
    
    func updateUIView(_ uiView: ScratchUI, context: Context) {}
}

class ScratchUI: UIView {
    var progressBinding: Binding<Double>?
    var onComplete: (() -> Void)?
    
    private var scratchedArea: CGFloat = 0
    private var totalArea: CGFloat = 0
    private let brushSize: CGFloat = 45
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        isMultipleTouchEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        totalArea = bounds.width * bounds.height
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
    
    private func handleTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        scratchedArea += CGFloat.pi * brushSize * brushSize * 0.6
        scratchedArea = min(scratchedArea, totalArea * 0.9)
        
        let percentage = (scratchedArea / totalArea) * 100
        progressBinding?.wrappedValue = percentage
        
        if percentage >= 80 {
            onComplete?()
        }
        
        let path = UIBezierPath(ovalIn: CGRect(x: point.x - brushSize/2, y: point.y - brushSize/2, width: brushSize, height: brushSize))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        layer.mask = shapeLayer
    }
}

// MARK: - SLOT MACHINE - CON PREMI PER 2 SIMBOLI
struct SlotMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var gameState: GameState = .initial
    @State private var reels: [Int] = [0, 1, 2]
    @State private var winAmount: Int = 0
    @State private var isSpinning = false
    @State private var showInsufficientBalance = false
    @State private var spinTimer: Timer?
    
    enum GameState {
        case initial
        case spinning
        case finished
    }
    
    let symbols = ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"]
    let multipliers3 = [5, 8, 10, 15, 30, 50]   // 3 uguali
    let multipliers2 = [1, 2, 3, 4, 8, 12]      // 2 uguali (premi piccoli)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if gameState == .initial {
                initialView
            } else if gameState == .spinning {
                spinningView
            } else {
                resultView
            }
        }
        .onDisappear {
            spinTimer?.invalidate()
            spinTimer = nil
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Servono €10 per giocare")
        }
    }
    
    // MARK: - INITIAL VIEW
    private var initialView: some View {
        VStack {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentCyan)
                }
                Spacer()
                Text("Slot Machine")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "slot.machine")
                        .foregroundColor(.pink)
                    Text("€\(Int(balance))")
                        .font(.headline)
                        .foregroundColor(.accentCyan)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider().background(Color.pink.opacity(0.3))
            
            Spacer()
            
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "slot.machine")
                        .font(.system(size: 70))
                        .foregroundColor(.pink)
                    
                    Text("Slot Machine")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("€10")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.pink)
                        .cornerRadius(25)
                }
                
                // TABELLA PREMI COMPLETA
                VStack(alignment: .leading, spacing: 16) {
                    Text("🎰 3 SIMBOLI UGUALI")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(0..<symbols.count, id: \.self) { i in
                            HStack {
                                Text(symbols[i])
                                Text("x\(multipliers3[i])")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Text("🎰 2 SIMBOLI UGUALI")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(0..<symbols.count, id: \.self) { i in
                            HStack {
                                Text(symbols[i])
                                Text("x\(multipliers2[i])")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Button(action: startSpin) {
                    Text("GIOCA")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.pink)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // MARK: - SPINNING VIEW
    private var spinningView: some View {
        VStack {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentCyan)
                }
                Spacer()
                Text("Slot Machine")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("€\(Int(balance))")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider().background(Color.pink.opacity(0.3))
            
            Spacer()
            
            // RULLI
            HStack(spacing: 20) {
                ForEach(0..<3) { i in
                    SlotReelSimple(
                        symbol: $reels[i],
                        symbols: symbols,
                        isSpinning: isSpinning
                    )
                    .frame(width: 90, height: 140)
                }
            }
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                    .scaleEffect(1.5)
                Text("GIRANDO...")
                    .font(.headline)
                    .foregroundColor(.pink)
            }
            .padding(.top, 40)
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // MARK: - RESULT VIEW
    private var resultView: some View {
        VStack {
            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentCyan)
                }
                Spacer()
                Text("Risultato")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("€\(Int(balance))")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Divider().background(Color.pink.opacity(0.3))
            
            Spacer()
            
            VStack(spacing: 30) {
                // RULLI FERMI
                HStack(spacing: 20) {
                    ForEach(0..<3) { i in
                        VStack {
                            Text(symbols[reels[i]])
                                .font(.system(size: 56))
                        }
                        .frame(width: 90, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(winAmount > 0 ? Color.yellow : Color.white.opacity(0.2), 
                                               lineWidth: winAmount > 0 ? 3 : 1)
                                )
                        )
                    }
                }
                
                // RISULTATO
                VStack(spacing: 15) {
                    Image(systemName: winAmount > 0 ? "crown.fill" : "xmark")
                        .font(.system(size: 50))
                        .foregroundColor(winAmount > 0 ? .yellow : .gray)
                    
                    Text(winAmount > 0 ? "HAI VINTO!" : "RITENTA")
                        .font(.title2.bold())
                        .foregroundColor(winAmount > 0 ? .yellow : .gray)
                    
                    if winAmount > 0 {
                        Text("€\(winAmount)")
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 25)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                
                // RIEPILOGO
                VStack(spacing: 15) {
                    HStack {
                        Text("Costo giro")
                        Spacer()
                        Text("-€10")
                            .foregroundColor(.red)
                    }
                    
                    if winAmount > 0 {
                        HStack {
                            Text("Vincita")
                            Spacer()
                            Text("+€\(winAmount)")
                                .foregroundColor(.green)
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("Guadagno netto")
                                .bold()
                            Spacer()
                            Text("€\(winAmount - 10)")
                                .foregroundColor(winAmount >= 10 ? .green : .orange)
                                .bold()
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    HStack {
                        Text("Nuovo saldo")
                            .bold()
                        Spacer()
                        Text("€\(Int(balance))")
                            .foregroundColor(.accentCyan)
                            .bold()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                // BOTTONI
                HStack(spacing: 16) {
                    Button(action: playAgain) {
                        Text("RIGIOCA")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.pink)
                            .cornerRadius(16)
                    }
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("CHIUDI")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.pink, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // MARK: - FUNCTIONS
    private func startSpin() {
        guard balance >= 10 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 10
        winAmount = 0
        gameState = .spinning
        isSpinning = true
        
        var spinCounter = 0
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { timer in
            reels[0] = Int.random(in: 0..<symbols.count)
            reels[1] = Int.random(in: 0..<symbols.count)
            reels[2] = Int.random(in: 0..<symbols.count)
            
            spinCounter += 1
            if spinCounter > 28 {
                timer.invalidate()
                stopSpin()
            }
        }
    }
    
    private func stopSpin() {
        isSpinning = false
        
        // Calcola vincita
        if reels[0] == reels[1] && reels[1] == reels[2] {
            // 3 simboli uguali
            winAmount = multipliers3[reels[0]] * 10
            balance += Double(winAmount)
        } else if reels[0] == reels[1] || reels[1] == reels[2] || reels[0] == reels[2] {
            // 2 simboli uguali - trova quale
            if reels[0] == reels[1] || reels[0] == reels[2] {
                winAmount = multipliers2[reels[0]] * 5  // premio piccolo
            } else {
                winAmount = multipliers2[reels[1]] * 5
            }
            balance += Double(winAmount)
        } else {
            winAmount = 0
        }
        
        gameState = .finished
    }
    
    private func playAgain() {
        guard balance >= 10 else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        balance -= 10
        winAmount = 0
        gameState = .spinning
        isSpinning = true
        
        var spinCounter = 0
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { timer in
            reels[0] = Int.random(in: 0..<symbols.count)
            reels[1] = Int.random(in: 0..<symbols.count)
            reels[2] = Int.random(in: 0..<symbols.count)
            
            spinCounter += 1
            if spinCounter > 28 {
                timer.invalidate()
                stopSpin()
            }
        }
    }
}

// MARK: - SLOT REEL SIMPLE
struct SlotReelSimple: View {
    @Binding var symbol: Int
    let symbols: [String]
    let isSpinning: Bool
    
    @State private var offset: CGFloat = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.22))
            
            VStack(spacing: 8) {
                ForEach(-1..<2) { i in
                    let index = (symbol + i + symbols.count) % symbols.count
                    Text(symbols[index])
                        .font(.system(size: 44))
                }
            }
            .offset(y: offset)
            
            VStack {
                LinearGradient(colors: [Color(red: 0.18, green: 0.18, blue: 0.22), .clear], startPoint: .top, endPoint: .center)
                    .frame(height: 30)
                Spacer()
                LinearGradient(colors: [.clear, Color(red: 0.18, green: 0.18, blue: 0.22)], startPoint: .center, endPoint: .bottom)
                    .frame(height: 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
        }
        .frame(width: 90, height: 140)
        .onChange(of: isSpinning) { spinning in
            if spinning {
                timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    offset += 25
                    if offset > 70 {
                        offset = 0
                    }
                }
            } else {
                timer?.invalidate()
                timer = nil
                offset = 0
            }
        }
    }
}

// MARK: - GAMES VIEW
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
        .background(Color.clear)
    }
}

// MARK: - GAME BUTTON
struct GameButton: View {
    let title: String
    let icon: String
    let color: Color
    @State private var showGame = false
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        Button {
            if title == "Gratta e Vinci" && vm.balance < 50 {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                return
            }
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            showGame = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(title == "Gratta e Vinci" ? "€50" : "Gioca")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.3))
                    .cornerRadius(12)
            }
            .frame(width: 160, height: 170)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showGame) {
            if title == "Gratta e Vinci" {
                ScratchCardView(balance: $vm.balance)
            } else if title == "Slot Machine" {
                SlotMachineView(balance: $vm.balance)
            } else {
                ComingSoonView(gameName: title)
            }
        }
    }
}

// MARK: - COMING SOON
struct ComingSoonView: View {
    let gameName: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.accentCyan)
                
                Text(gameName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Prossimamente disponibile")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Torna indietro")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentCyan)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
}