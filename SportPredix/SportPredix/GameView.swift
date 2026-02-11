//
//  GameView.swift
//  SportPredix
//
//  Created by Redesign
//

import SwiftUI
import Combine

// MARK: - GIOCO GRATTA E VINCI RIDESIGNED
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
        (amount: 0, probability: 40, color: Color.gray),
        (amount: 50, probability: 25, color: Color(red: 68/255, green: 224/255, blue: 203/255)),
        (amount: 100, probability: 15, color: Color.green),
        (amount: 250, probability: 10, color: Color.orange),
        (amount: 500, probability: 7, color: Color.purple),
        (amount: 1000, probability: 3, color: Color.yellow)
    ]
    
    var body: some View {
        ZStack {
            // Sfondo come l'app principale
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header con vetro
                glassHeader
                
                ScrollView {
                    VStack(spacing: 24) {
                        if gameState == .initial {
                            initialContent
                        } else if gameState == .playing {
                            playingContent
                        } else {
                            resultContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .onAppear {
            selectProbabilisticPrize()
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(String(format: "Serve €50 per giocare.\nTuo saldo: €%.2f", balance))
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.06, green: 0.07, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentCyan.opacity(0.25),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.clear
                ]),
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header con vetro
    private var glassHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentCyan)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Gratta e Vinci")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text("Costo: €50")
                        .font(.caption)
                        .foregroundColor(.accentCyan)
                }
                
                Spacer()
                
                // Saldo
                HStack(spacing: 6) {
                    Image(systemName: "eurosign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentCyan)
                    
                    Text(String(format: "€%.2f", balance))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Linea sottile divisoria
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .accentCyan.opacity(0.3),
                            .blue.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .blur(radius: 0.5)
                .padding(.horizontal, 20)
        }
        .background(Color.black.opacity(0.3).background(.ultraThinMaterial.opacity(0.7)))
    }
    
    // MARK: - Initial Content
    private var initialContent: some View {
        VStack(spacing: 28) {
            // Card principale
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentCyan.opacity(0.2),
                                    Color.blue.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentCyan)
                        .shadow(color: .accentCyan.opacity(0.5), radius: 10)
                }
                
                VStack(spacing: 8) {
                    Text("Gratta e Vinci")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Scopri il tuo premio grattando la carta")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                    )
            )
            
            // Info cards
            VStack(spacing: 12) {
                infoCard(icon: "eurosign.circle", title: "Costo", value: "€50", color: .accentCyan)
                infoCard(icon: "crown.fill", title: "Premio massimo", value: "€1.000", color: .yellow)
                infoCard(icon: "percent", title: "Probabilità vincita", value: "60%", color: .green)
            }
            
            // Bottone
            Button(action: startGame) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("INIZIA A GIOCARE")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .accentCyan,
                            .accentCyan.opacity(0.8),
                            Color.blue.opacity(0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .accentCyan.opacity(0.35), radius: 14, x: 0, y: 8)
            }
        }
    }
    
    // MARK: - Info Card
    private func infoCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            // Icona
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Playing Content
    private var playingContent: some View {
        VStack(spacing: 28) {
            // Progress bar
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progresso grattamento")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(Int(scratchProgress))%")
                        .font(.headline.bold())
                        .foregroundColor(.accentCyan)
                }
                
                ProgressView(value: scratchProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentCyan))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .shadow(color: .accentCyan.opacity(0.3), radius: 4)
            }
            .padding(.horizontal, 4)
            
            // Card grattabile
            ScratchableCardRedesigned(
                prize: prize,
                prizeColor: prizeColor,
                onScratch: { progress in
                    scratchProgress = progress
                    if progress >= 75 {
                        revealCard()
                    }
                }
            )
            .frame(height: 380)
            
            // Istruzioni
            HStack(spacing: 10) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.caption)
                    .foregroundColor(.accentCyan)
                
                Text("Gratta l'area grigia per scoprire il premio")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        Capsule()
                            .stroke(Color.accentCyan.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Result Content
    private var resultContent: some View {
        VStack(spacing: 28) {
            // Risultato card
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    prizeColor.opacity(0.2),
                                    prizeColor.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(prizeColor.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: prize > 0 ? "crown.fill" : "xmark")
                        .font(.system(size: 48))
                        .foregroundColor(prizeColor)
                        .shadow(color: prizeColor.opacity(0.5), radius: 10)
                }
                
                VStack(spacing: 12) {
                    Text(prize > 0 ? "HAI VINTO!" : "RITENTA")
                        .font(.title2.bold())
                        .foregroundColor(prizeColor)
                    
                    Text("€\(prize)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(prizeColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Riepilogo
            VStack(spacing: 16) {
                resultRow(label: "Costo biglietto", value: "-€50", color: .red)
                
                if prize > 0 {
                    resultRow(label: "Premio vinto", value: "+€\(prize)", color: .green)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    resultRow(
                        label: "Guadagno netto",
                        value: "€\(prize - 50)",
                        color: prize >= 50 ? .green : .orange,
                        isBold: true
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                resultRow(
                    label: "Nuovo saldo",
                    value: String(format: "€%.2f", balance),
                    color: .accentCyan,
                    isBold: true
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            
            // Bottom buttons
            HStack(spacing: 16) {
                // Rigioca button
                Button(action: playAgain) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("RIGIOCA")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.accentCyan, .accentCyan.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Menu button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("MENU")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.accentCyan.opacity(0.5), lineWidth: 1.5)
                    )
                }
            }
        }
    }
    
    // MARK: - Result Row
    private func resultRow(label: String, value: String, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: isBold ? .semibold : .regular))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: isBold ? .bold : .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Helper
    private var prizeColor: Color {
        prizes.first(where: { $0.amount == prize })?.color ?? .accentCyan
    }
    
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
        withAnimation(.easeInOut(duration: 0.5)) {
            gameState = .finished
        }
        
        if prize > 0 {
            balance += Double(prize)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    private func playAgain() {
        withAnimation(.easeOut(duration: 0.3)) {
            scratchProgress = 0
            gameState = .initial
            selectProbabilisticPrize()
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
}

// MARK: - SCRATCHABLE CARD RIDESIGNED
struct ScratchableCardRedesigned: View {
    let prize: Int
    let prizeColor: Color
    var onScratch: (Double) -> Void
    
    @State private var scratchedPercentage: Double = 0
    @State private var touchPoints: [CGPoint] = []
    @State private var showScratchHint = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card con premio
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Icona premio
                    Image(systemName: prize > 0 ? "crown.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(prizeColor.opacity(0.8))
                        .shadow(color: prizeColor.opacity(0.5), radius: 10)
                    
                    VStack(spacing: 8) {
                        Text("€\(prize)")
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(prize > 0 ? "VINCITA" : "RITENTA")
                            .font(.caption.bold())
                            .foregroundColor(prizeColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(prizeColor.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(prizeColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.12, blue: 0.15),
                            Color(red: 0.05, green: 0.06, blue: 0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Layer grattabile
                ScratchOverlayRedesigned(
                    touchPoints: $touchPoints,
                    scratchedPercentage: $scratchedPercentage,
                    onScratch: onScratch
                )
                .background(
                    ZStack {
                        // Pattern grattabile
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.25, green: 0.25, blue: 0.3),
                                Color(red: 0.2, green: 0.2, blue: 0.25)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Effetto metallico
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                        
                        // Pattern griglia
                        GridPattern()
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        
                        // Hint iniziale
                        if showScratchHint && touchPoints.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "hand.draw.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("Gratta qui")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                )
                .mask(
                    Rectangle()
                        .fill(Color.white)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LinearGradient(
                    colors: [.white.opacity(0.2), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - GRID PATTERN
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 20
        
        for x in stride(from: 0, through: rect.width, by: step) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        for y in stride(from: 0, through: rect.height, by: step) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

// MARK: - SCRATCH OVERLAY RIDESIGNED
struct ScratchOverlayRedesigned: UIViewRepresentable {
    @Binding var touchPoints: [CGPoint]
    @Binding var scratchedPercentage: Double
    var onScratch: (Double) -> Void
    
    func makeUIView(context: Context) -> ScratchUIView {
        let view = ScratchUIView()
        view.onScratch = onScratch
        view.scratchedPercentageBinding = $scratchedPercentage
        view.touchPointsBinding = $touchPoints
        return view
    }
    
    func updateUIView(_ uiView: ScratchUIView, context: Context) {}
}

class ScratchUIView: UIView {
    var onScratch: ((Double) -> Void)?
    var scratchedPercentageBinding: Binding<Double>?
    var touchPointsBinding: Binding<[CGPoint]>?
    private var scratchedArea: CGFloat = 0
    private var lastPercentage: Double = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        touchPointsBinding?.wrappedValue.append(point)
        
        // Calcola area grattata
        let radius: CGFloat = 20
        scratchedArea += CGFloat.pi * radius * radius
        
        let totalArea = bounds.width * bounds.height
        let percentage = min((scratchedArea / totalArea) * 100, 100)
        
        scratchedPercentageBinding?.wrappedValue = percentage
        onScratch?(percentage)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Sfondo semi-trasparente
        context.setFillColor(UIColor(white: 0.2, alpha: 0.95).cgColor)
        context.fill(rect)
        
        // Disegna pattern
        context.setFillColor(UIColor(white: 0.25, alpha: 1).cgColor)
        let step: CGFloat = 8
        for x in stride(from: 0, through: rect.width, by: step) {
            for y in stride(from: 0, through: rect.height, by: step) {
                if (Int(x/step) + Int(y/step)) % 2 == 0 {
                    let dotRect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(dotRect)
                }
            }
        }
        
        // Rimuovi aree grattate
        context.setBlendMode(.clear)
        if let binding = touchPointsBinding {
            for point in binding.wrappedValue {
                let circleRect = CGRect(
                    x: point.x - 20,
                    y: point.y - 20,
                    width: 40,
                    height: 40
                )
                context.fillEllipse(in: circleRect)
                
                // Aggiungi qualche punto extra per effetto realistico
                for _ in 0..<3 {
                    let offsetX = CGFloat.random(in: -15...15)
                    let offsetY = CGFloat.random(in: -15...15)
                    let extraRect = CGRect(
                        x: point.x + offsetX - 8,
                        y: point.y + offsetY - 8,
                        width: 16,
                        height: 16
                    )
                    context.fillEllipse(in: extraRect)
                }
            }
        }
    }
}

// MARK: - SLOT MACHINE RIDESIGNED
struct SlotMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var gameState: GameState = .initial
    @State private var reels: [SlotReelState] = [
        SlotReelState(symbols: ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"]),
        SlotReelState(symbols: ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"]),
        SlotReelState(symbols: ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"])
    ]
    @State private var winAmount: Int = 0
    @State private var isSpinning = false
    @State private var showInsufficientBalance = false
    @State private var spinCount = 0
    @State private var spinTimer: Timer.TimerPublisher = Timer.publish(every: 0.05, on: .main, in: .common)
    @State private var timerSubscription: AnyCancellable?
    
    enum GameState {
        case initial
        case spinning
        case finished
    }
    
    let symbols = ["🍒", "🍋", "🍊", "🔔", "💎", "7️⃣"]
    let symbolMultipliers: [String: Int] = [
        "🍒": 5,
        "🍋": 8,
        "🍊": 10,
        "🔔": 15,
        "💎": 30,
        "7️⃣": 50
    ]
    
    var body: some View {
        ZStack {
            // Sfondo come l'app principale
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header con vetro
                glassHeader
                
                ScrollView {
                    VStack(spacing: 28) {
                        if gameState == .initial {
                            initialContent
                        } else if gameState == .spinning {
                            spinningContent
                        } else {
                            resultContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .onDisappear {
            timerSubscription?.cancel()
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(String(format: "Serve €10 per giocare.\nTuo saldo: €%.2f", balance))
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.06, green: 0.07, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.pink.opacity(0.25),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.15),
                    Color.clear
                ]),
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header
    private var glassHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentCyan)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Slot Machine")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text("Costo: €10")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
                
                Spacer()
                
                // Saldo
                HStack(spacing: 6) {
                    Image(systemName: "eurosign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentCyan)
                    
                    Text(String(format: "€%.2f", balance))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .pink.opacity(0.3),
                            .purple.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .blur(radius: 0.5)
                .padding(.horizontal, 20)
        }
        .background(Color.black.opacity(0.3).background(.ultraThinMaterial.opacity(0.7)))
    }
    
    // MARK: - Initial Content
    private var initialContent: some View {
        VStack(spacing: 28) {
            // Card principale
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.pink.opacity(0.2),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: "slot.machine")
                        .font(.system(size: 48))
                        .foregroundColor(.pink)
                        .shadow(color: .pink.opacity(0.5), radius: 10)
                }
                
                VStack(spacing: 8) {
                    Text("Slot Machine")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Fai girare i rulli e vinci!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.pink.opacity(0.18), lineWidth: 1)
                    )
            )
            
            // Info cards
            VStack(spacing: 12) {
                infoCardSlot(icon: "eurosign.circle", title: "Costo per giro", value: "€10", color: .pink)
                infoCardSlot(icon: "crown.fill", title: "Premio massimo", value: "€500", color: .yellow)
                infoCardSlot(icon: "checkmark.circle", title: "3 simboli uguali", value: "Vincita!", color: .green)
            }
            
            // Bottone
            Button(action: startSpin) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("INIZIA A GIOCARE")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .pink,
                            .pink.opacity(0.8),
                            .purple.opacity(0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .pink.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            
            // Tabella premi
            VStack(alignment: .leading, spacing: 16) {
                Text("TABELLA PREMI")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(symbols.enumerated()), id: \.element) { index, symbol in
                        HStack {
                            Text(symbol)
                                .font(.title3)
                            Text("x\(symbolMultipliers[symbol] ?? 0)")
                                .font(.caption.bold())
                                .foregroundColor(.pink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Info Card Slot
    private func infoCardSlot(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Spinning Content
    private var spinningContent: some View {
        VStack(spacing: 28) {
            // Rulli animati
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        SlotReelViewRedesigned(
                            reelState: $reels[index],
                            isSpinning: isSpinning,
                            spinTimer: $spinTimer,
                            timerSubscription: $timerSubscription
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.15),
                                Color(red: 0.08, green: 0.08, blue: 0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .pink.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            
            // Stato spinning
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                    .scaleEffect(1.2)
                
                Text("La macchina sta girando...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Spin #\(spinCount)")
                    .font(.caption)
                    .foregroundColor(.pink)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Pulsante disabilitato
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("GIRANDO...")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.pink.opacity(0.3))
                .cornerRadius(16)
            }
            .disabled(true)
        }
    }
    
    // MARK: - Result Content
    private var resultContent: some View {
        VStack(spacing: 28) {
            // Rulli finali
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        VStack {
                            Text(symbols[reels[index].currentIndex])
                                .font(.system(size: 64))
                                .shadow(color: winAmount > 0 ? .yellow.opacity(0.5) : .clear, radius: 10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.15, green: 0.15, blue: 0.18),
                                            Color(red: 0.1, green: 0.1, blue: 0.12)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            winAmount > 0 ?
                                            Color.yellow.opacity(0.6) :
                                            Color.white.opacity(0.1),
                                            lineWidth: winAmount > 0 ? 2 : 1
                                        )
                                )
                        )
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            
            // Risultato
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    winAmount > 0 ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2),
                                    winAmount > 0 ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(
                                    winAmount > 0 ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: winAmount > 0 ? "crown.fill" : "xmark")
                        .font(.system(size: 36))
                        .foregroundColor(winAmount > 0 ? .yellow : .gray)
                }
                
                VStack(spacing: 4) {
                    Text(winAmount > 0 ? "HAI VINTO!" : "RITENTA")
                        .font(.title3.bold())
                        .foregroundColor(winAmount > 0 ? .yellow : .gray)
                    
                    if winAmount > 0 {
                        Text("€\(winAmount)")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(winAmount > 0 ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Riepilogo
            VStack(spacing: 16) {
                resultRowSlot(label: "Costo giro", value: "-€10", color: .red)
                
                if winAmount > 0 {
                    resultRowSlot(label: "Vincita", value: "+€\(winAmount)", color: .green)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    resultRowSlot(
                        label: "Guadagno netto",
                        value: "€\(winAmount - 10)",
                        color: winAmount >= 10 ? .green : .orange,
                        isBold: true
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                resultRowSlot(
                    label: "Nuovo saldo",
                    value: String(format: "€%.2f", balance),
                    color: .accentCyan,
                    isBold: true
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            
            // Bottom buttons
            HStack(spacing: 16) {
                Button(action: playAgain) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("RIGIOCA")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.pink, .pink.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("MENU")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.pink.opacity(0.5), lineWidth: 1.5)
                    )
                }
            }
        }
    }
    
    // MARK: - Result Row Slot
    private func resultRowSlot(label: String, value: String, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: isBold ? .semibold : .regular))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: isBold ? .bold : .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Functions
    private func startSpin() {
        guard balance >= 10 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 10
        gameState = .spinning
        isSpinning = true
        spinCount += 1
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Avvia il timer per lo spinning
        spinTimer = Timer.publish(every: 0.05, on: .main, in: .common)
        timerSubscription = spinTimer.connect()
        
        // Stop dopo 2.5 secondi
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            stopSpin()
        }
    }
    
    private func stopSpin() {
        isSpinning = false
        timerSubscription?.cancel()
        
        // Calcola vincita
        let symbol1 = reels[0].currentIndex
        let symbol2 = reels[1].currentIndex
        let symbol3 = reels[2].currentIndex
        
        if symbol1 == symbol2 && symbol2 == symbol3 {
            let symbol = symbols[symbol1]
            let multiplier = symbolMultipliers[symbol] ?? 0
            winAmount = multiplier * 10 // €10 per moltiplicatore
            
            balance += Double(winAmount)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            winAmount = 0
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            gameState = .finished
        }
    }
    
    private func playAgain() {
        withAnimation(.easeOut(duration: 0.3)) {
            gameState = .initial
            winAmount = 0
            reels = [
                SlotReelState(symbols: symbols),
                SlotReelState(symbols: symbols),
                SlotReelState(symbols: symbols)
            ]
        }
    }
}

// MARK: - SLOT REEL STATE
struct SlotReelState {
    let symbols: [String]
    var currentIndex: Int
    var isSpinning: Bool = false
    var offset: CGFloat = 0
    
    init(symbols: [String]) {
        self.symbols = symbols
        self.currentIndex = Int.random(in: 0..<symbols.count)
    }
    
    mutating func startSpinning() {
        isSpinning = true
        offset = 0
    }
    
    mutating func stopSpinning() {
        isSpinning = false
        offset = 0
    }
    
    mutating func updateSpin() {
        if isSpinning {
            offset += 40
            if offset > 100 {
                offset -= 100
                currentIndex = (currentIndex + 1) % symbols.count
            }
        }
    }
}

// MARK: - SLOT REEL VIEW RIDESIGNED
struct SlotReelViewRedesigned: View {
    @Binding var reelState: SlotReelState
    let isSpinning: Bool
    @Binding var spinTimer: Timer.TimerPublisher
    @Binding var timerSubscription: AnyCancellable?
    
    var body: some View {
        ZStack {
            // Sfondo
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.18, blue: 0.22),
                            Color(red: 0.12, green: 0.12, blue: 0.16)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Simboli animati
            VStack(spacing: 20) {
                ForEach(-1..<2) { i in
                    let index = (reelState.currentIndex + i + reelState.symbols.count) % reelState.symbols.count
                    Text(reelState.symbols[index])
                        .font(.system(size: 48))
                        .shadow(color: .white.opacity(0.2), radius: 2)
                }
            }
            .offset(y: reelState.offset)
            
            // Effetti di luce
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 40)
                
                Spacer()
                
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.1)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 40)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Bordo
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
            
            // Effetto scintillio quando fermo
            if !isSpinning && reelState.isSpinning == false {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                    .blur(radius: 2)
            }
        }
        .frame(height: 160)
        .onReceive(spinTimer) { _ in
            if isSpinning {
                reelState.updateSpin()
            }
        }
        .onChange(of: isSpinning) { newValue in
            if newValue {
                reelState.startSpinning()
            } else {
                reelState.stopSpinning()
            }
        }
    }
}

// MARK: - GAME BUTTON RIDESIGNED
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
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                return
            }
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            showGame = true
        } label: {
            VStack(spacing: 16) {
                // Icona con effetto vetro
                ZStack {
                    // Glow
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 70, height: 70)
                        .blur(radius: 8)
                    
                    // Cerchio principale
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            color.opacity(0.6),
                                            color.opacity(0.2)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: color.opacity(0.5), radius: 5)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Prezzo badge
                Text(title == "Gratta e Vinci" ? "€50" : "Gioca")
                    .font(.caption.bold())
                    .foregroundColor(title == "Gratta e Vinci" ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(title == "Gratta e Vinci" ? 
                                  LinearGradient(colors: [.accentCyan, .accentCyan.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                  LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                    )
                    .overlay(
                        Capsule()
                            .stroke(title == "Gratta e Vinci" ? Color.white.opacity(0.3) : color.opacity(0.3), lineWidth: 1)
                    )
            }
            .frame(width: 160, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.3), .clear, color.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 15, x: 0, y: 8)
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

// MARK: - COMING SOON VIEW
struct ComingSoonView: View {
    let gameName: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.06, green: 0.07, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentCyan.opacity(0.2),
                                    Color.blue.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "clock.badge")
                        .font(.system(size: 56))
                        .foregroundColor(.accentCyan)
                        .shadow(color: .accentCyan.opacity(0.5), radius: 10)
                }
                
                Text(gameName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Prossimamente disponibile")
                    .font(.headline)
                    .foregroundColor(.accentCyan)
                
                Text("Questo gioco sarà disponibile nelle prossime versioni dell'app")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Torna al Casino")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.accentCyan, .accentCyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
}