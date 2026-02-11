//
//  GameView.swift
//  SportPredix
//
//  Created by FINAL FIX
//

import SwiftUI
import Combine

// MARK: - GIOCO GRATTA E VINCI - COMPLETAMENTE RIFATTO
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
            // SFONDO
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER SEMPLICE
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.accentCyan)
                    }
                    
                    Spacer()
                    
                    Text("Gratta e Vinci")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("€\(Int(balance))")
                        .font(.headline.bold())
                        .foregroundColor(.accentCyan)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                
                Divider()
                    .background(Color.accentCyan.opacity(0.3))
                
                if gameState == .initial {
                    initialView
                } else if gameState == .playing {
                    playingView
                } else {
                    resultView
                }
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
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentCyan)
                    
                    Text("Gratta e Vinci")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Costo: €50")
                        .font(.headline)
                        .foregroundColor(.accentCyan)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.accentCyan.opacity(0.2))
                        .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                
                VStack(spacing: 15) {
                    infoRow(icon: "eurosign.circle", text: "Premio massimo: €1.000")
                    infoRow(icon: "percent", text: "Probabilità vincita: 60%")
                    infoRow(icon: "hand.tap", text: "Gratta per scoprire il premio")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                Button(action: startGame) {
                    Text("GIOCA")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentCyan)
                        .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .padding(20)
        }
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentCyan)
                .frame(width: 24)
            
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
            
            Spacer()
        }
    }
    
    // MARK: - PLAYING VIEW - FIXED NO SWIPE
    private var playingView: some View {
        VStack(spacing: 20) {
            // Progress bar
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // CARD GRATTABILE - FIXED
            ScratchCardFinal(
                prize: prize,
                onScratch: { progress in
                    scratchProgress = progress
                    if progress >= 80 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            revealCard()
                        }
                    }
                }
            )
            .frame(height: 380)
            .padding(.horizontal, 20)
            
            Text("Gratta con il dito sulla carta")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 10)
            
            Spacer()
        }
    }
    
    // MARK: - RESULT VIEW
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Risultato
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(prize > 0 ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: prize > 0 ? "crown.fill" : "xmark")
                            .font(.system(size: 50))
                            .foregroundColor(prize > 0 ? .green : .gray)
                    }
                    
                    Text(prize > 0 ? "HAI VINTO!" : "RITENTA")
                        .font(.title2.bold())
                        .foregroundColor(prize > 0 ? .green : .gray)
                    
                    Text("€\(prize)")
                        .font(.system(size: 50, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                
                // Riepilogo
                VStack(spacing: 15) {
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
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                // Bottoni
                HStack(spacing: 15) {
                    Button(action: playAgain) {
                        Text("RIGIOCA")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.accentCyan)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("CHIUDI")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentCyan, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - FUNCTIONS
    private func startGame() {
        guard balance >= 50 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 50
        gameState = .playing
        scratchProgress = 0
        selectPrize()
    }
    
    private func revealCard() {
        withAnimation {
            gameState = .finished
        }
        
        if prize > 0 {
            balance += Double(prize)
        }
    }
    
    private func playAgain() {
        guard balance >= 50 else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        balance -= 50
        gameState = .playing
        scratchProgress = 0
        selectPrize()
    }
    
    private func selectPrize() {
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
}

// MARK: - SCRATCH CARD FINAL - FIXED NO SWIPE
struct ScratchCardFinal: UIViewRepresentable {
    let prize: Int
    var onScratch: (Double) -> Void
    
    func makeUIView(context: Context) -> ScratchUIViewFinal2 {
        let view = ScratchUIViewFinal2()
        view.prize = prize
        view.onScratch = onScratch
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }
    
    func updateUIView(_ uiView: ScratchUIViewFinal2, context: Context) {
        uiView.prize = prize
    }
}

class ScratchUIViewFinal2: UIView {
    var prize: Int = 0
    var onScratch: ((Double) -> Void)?
    
    private var scratchedArea: CGFloat = 0
    private var totalArea: CGFloat = 0
    private var isFirstTouch = true
    private let brushSize: CGFloat = 40
    
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
    
    // BLOCCO COMPLETO DEI GESTI
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // NON chiamare super.touchesBegan per bloccare la propagazione
        handleTouches(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // NON chiamare super.touchesMoved per bloccare la propagazione
        handleTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // NON chiamare super.touchesEnded per bloccare la propagazione
    }
    
    private func handleTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let previousPoint = touch.previousLocation(in: self)
        
        // Calcola area grattata
        let distance = hypot(point.x - previousPoint.x, point.y - previousPoint.y)
        
        if distance > 0 {
            scratchedArea += CGFloat.pi * brushSize * brushSize * 0.3
            scratchedArea += distance * brushSize * 0.8
        } else {
            scratchedArea += CGFloat.pi * brushSize * brushSize * 0.5
        }
        
        scratchedArea = min(scratchedArea, totalArea * 0.9)
        
        let percentage = (scratchedArea / totalArea) * 100
        onScratch?(percentage)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Disegna il premio sullo sfondo
        drawPrize(in: rect)
        
        // Disegna il layer grattabile
        context.setFillColor(UIColor(white: 0.25, alpha: 0.98).cgColor)
        context.fill(rect)
        
        // Disegna pattern
        context.setFillColor(UIColor(white: 0.35, alpha: 1).cgColor)
        let step: CGFloat = 8
        for x in stride(from: 0, through: rect.width, by: step) {
            for y in stride(from: 0, through: rect.height, by: step) {
                if Int(x/step + y/step) % 2 == 0 {
                    context.fill(CGRect(x: x, y: y, width: 2, height: 2))
                }
            }
        }
        
        // Rimuovi aree grattate
        context.setBlendMode(.clear)
        
        // Ottieni i punti del tocco corrente (simulato)
        // In una implementazione reale, dovresti memorizzare i punti
        // Questa è una versione semplificata
    }
    
    private func drawPrize(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Sfondo del premio
        context.setFillColor(UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1).cgColor)
        context.fill(rect)
        
        // Testo premio
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let prizeString = "€\(prize)"
        let size = prizeString.size(withAttributes: attributes)
        let point = CGPoint(x: center.x - size.width/2, y: center.y - size.height/2)
        
        prizeString.draw(at: point, withAttributes: attributes)
        
        if prize > 0 {
            let subtitle = "VINCITA"
            let subAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.green
            ]
            let subSize = subtitle.size(withAttributes: subAttributes)
            subtitle.draw(at: CGPoint(x: center.x - subSize.width/2, y: center.y + 30), withAttributes: subAttributes)
        } else {
            let subtitle = "RITENTA"
            let subAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.gray
            ]
            let subSize = subtitle.size(withAttributes: subAttributes)
            subtitle.draw(at: CGPoint(x: center.x - subSize.width/2, y: center.y + 30), withAttributes: subAttributes)
        }
    }
}

// MARK: - SLOT MACHINE - COMPLETAMENTE RIFATTA
struct SlotMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var gameState: GameState = .initial
    @State private var reels: [Int] = [0, 1, 2]
    @State private var winAmount: Int = 0
    @State private var isSpinning = false
    @State private var showInsufficientBalance = false
    @State private var spinCount = 0
    
    enum GameState {
        case initial
        case spinning
        case finished
    }
    
    let symbols = ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"]
    let multipliers = [5, 8, 10, 15, 30, 50]
    
    var body: some View {
        ZStack {
            // SFONDO
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.accentCyan)
                    }
                    
                    Spacer()
                    
                    Text("Slot Machine")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "slot.machine")
                            .foregroundColor(.pink)
                        Text("€\(Int(balance))")
                            .font(.headline.bold())
                            .foregroundColor(.accentCyan)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                
                Divider()
                    .background(Color.pink.opacity(0.3))
                
                if gameState == .initial {
                    initialView
                } else if gameState == .spinning {
                    spinningView
                } else {
                    resultView
                }
            }
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Servono €10 per giocare")
        }
    }
    
    // MARK: - INITIAL VIEW
    private var initialView: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "slot.machine")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("Slot Machine")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Costo: €10")
                        .font(.headline)
                        .foregroundColor(.pink)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.pink.opacity(0.2))
                        .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                
                // TABELLA PREMI
                VStack(alignment: .leading, spacing: 15) {
                    Text("TABELLA PREMI")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(0..<symbols.count, id: \.self) { i in
                            HStack {
                                Text(symbols[i])
                                    .font(.title3)
                                Text("x\(multipliers[i])")
                                    .font(.caption)
                                    .foregroundColor(.pink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                Button(action: startSpin) {
                    Text("GIOCA")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.pink)
                        .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .padding(20)
        }
    }
    
    // MARK: - SPINNING VIEW
    private var spinningView: some View {
        VStack(spacing: 30) {
            // RULLI - PROPORZIONI PERFETTE
            HStack(spacing: 15) {
                ForEach(0..<3) { i in
                    SlotReelFinal(
                        symbol: $reels[i],
                        symbols: symbols,
                        isSpinning: isSpinning
                    )
                    .frame(width: 90, height: 140)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 10)
            
            VStack(spacing: 15) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                    .scaleEffect(1.2)
                
                Text("GIRANDO...")
                    .font(.headline)
                    .foregroundColor(.pink)
            }
            .padding(.vertical, 20)
            
            Spacer()
        }
        .padding(.top, 30)
    }
    
    // MARK: - RESULT VIEW
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // RULLI FERMI
                HStack(spacing: 15) {
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
                .padding(.vertical, 20)
                
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
                
                // BOTTONI
                HStack(spacing: 15) {
                    Button(action: playAgain) {
                        Text("RIGIOCA")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("CHIUDI")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - FUNCTIONS
    private func startSpin() {
        guard balance >= 10 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 10
        gameState = .spinning
        isSpinning = true
        spinCount += 1
        
        // ANIMAZIONE REALISTICA
        var spinCounter = 0
        Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { timer in
            // Cambia simboli casualmente
            reels[0] = Int.random(in: 0..<symbols.count)
            reels[1] = Int.random(in: 0..<symbols.count)
            reels[2] = Int.random(in: 0..<symbols.count)
            
            spinCounter += 1
            
            // Stop dopo 2 secondi
            if spinCounter > 28 {
                timer.invalidate()
                stopSpin()
            }
        }
    }
    
    private func stopSpin() {
        isSpinning = false
        
        // SIMBOLI FINALI CASUALI
        reels[0] = Int.random(in: 0..<symbols.count)
        reels[1] = Int.random(in: 0..<symbols.count)
        reels[2] = Int.random(in: 0..<symbols.count)
        
        // CALCOLO VINCITA
        if reels[0] == reels[1] && reels[1] == reels[2] {
            winAmount = multipliers[reels[0]] * 10
            balance += Double(winAmount)
        } else {
            winAmount = 0
        }
        
        withAnimation {
            gameState = .finished
        }
    }
    
    private func playAgain() {
        guard balance >= 10 else {
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        balance -= 10
        gameState = .spinning
        isSpinning = true
        winAmount = 0
        spinCount += 1
        
        var spinCounter = 0
        Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { timer in
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

// MARK: - SLOT REEL FINAL - PERFETTE PROPORZIONI
struct SlotReelFinal: View {
    @Binding var symbol: Int
    let symbols: [String]
    let isSpinning: Bool
    
    @State private var offset: CGFloat = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // SFONDO
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.22))
            
            // SIMBOLI
            VStack(spacing: 8) {
                ForEach(-1..<2) { i in
                    let index = (symbol + i + symbols.count) % symbols.count
                    Text(symbols[index])
                        .font(.system(size: 44))
                        .shadow(color: .white.opacity(0.2), radius: 2)
                }
            }
            .offset(y: offset)
            
            // EFFETTI LUCE
            VStack {
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.18, blue: 0.22), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 30)
                
                Spacer()
                
                LinearGradient(
                    colors: [.clear, Color(red: 0.18, green: 0.18, blue: 0.22)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // BORDO
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
        }
        .frame(width: 90, height: 140)
        .onChange(of: isSpinning) { spinning in
            if spinning {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startAnimation() {
        stopAnimation()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            offset += 25
            if offset > 70 {
                offset = 0
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        offset = 0
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