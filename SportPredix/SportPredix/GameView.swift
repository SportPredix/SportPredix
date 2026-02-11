//
//  GameView.swift
//  SportPredix
//
//  Created by Redesign Final
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
            backgroundGradient
            
            VStack(spacing: 0) {
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
    
    private var initialContent: some View {
        VStack(spacing: 28) {
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
            
            VStack(spacing: 12) {
                infoCard(icon: "eurosign.circle", title: "Costo", value: "€50", color: .accentCyan)
                infoCard(icon: "crown.fill", title: "Premio massimo", value: "€1.000", color: .yellow)
                infoCard(icon: "percent", title: "Probabilità vincita", value: "60%", color: .green)
            }
            
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
    
    private func infoCard(icon: String, title: String, value: String, color: Color) -> some View {
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
    
    private var playingContent: some View {
        VStack(spacing: 28) {
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
            
            ScratchableCardRedesignedFinal(
                prize: prize,
                prizeColor: prizeColor,
                onScratch: { progress in
                    scratchProgress = progress
                    if progress >= 75 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            revealCard()
                        }
                    }
                }
            )
            .frame(height: 380)
            
            HStack(spacing: 10) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.caption)
                    .foregroundColor(.accentCyan)
                
                Text("Gratta con il dito - Più gratti, più scopri!")
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
    
    private var resultContent: some View {
        VStack(spacing: 28) {
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
            
            HStack(spacing: 16) {
                Button(action: playAgain) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("RIGIOCA SUBITO")
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
            gameState = .playing
            scratchProgress = 0
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

// MARK: - SCRATCHABLE CARD FINAL - FIXED SWIPE ISSUE
struct ScratchableCardRedesignedFinal: View {
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
                
                // Layer grattabile FIXED - Niente gesture, solo UIView
                ScratchOverlayFinal(
                    touchPoints: $touchPoints,
                    scratchedPercentage: $scratchedPercentage,
                    onScratch: onScratch,
                    showHint: $showScratchHint
                )
                .background(
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.35, green: 0.35, blue: 0.4),
                                Color(red: 0.25, green: 0.25, blue: 0.3),
                                Color(red: 0.2, green: 0.2, blue: 0.25)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                        
                        GridPatternFine()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        
                        DottedPattern()
                            .fill(Color.white.opacity(0.1))
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

// MARK: - GRID PATTERN FINE
struct GridPatternFine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 12
        
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

// MARK: - DOTTED PATTERN
struct DottedPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 8
        
        for x in stride(from: 2, through: rect.width, by: step) {
            for y in stride(from: 2, through: rect.height, by: step) {
                let dotRect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                path.addEllipse(in: dotRect)
            }
        }
        
        return path
    }
}

// MARK: - SCRATCH OVERLAY FINAL - NO SWIPE ISSUE
struct ScratchOverlayFinal: UIViewRepresentable {
    @Binding var touchPoints: [CGPoint]
    @Binding var scratchedPercentage: Double
    var onScratch: (Double) -> Void
    @Binding var showHint: Bool
    
    func makeUIView(context: Context) -> ScratchUIViewFinal {
        let view = ScratchUIViewFinal()
        view.onScratch = onScratch
        view.scratchedPercentageBinding = $scratchedPercentage
        view.touchPointsBinding = $touchPoints
        view.showHintBinding = $showHint
        return view
    }
    
    func updateUIView(_ uiView: ScratchUIViewFinal, context: Context) {
        uiView.showHint = showHint
    }
}

class ScratchUIViewFinal: UIView {
    var onScratch: ((Double) -> Void)?
    var scratchedPercentageBinding: Binding<Double>?
    var touchPointsBinding: Binding<[CGPoint]>?
    var showHintBinding: Binding<Bool>?
    var showHint: Bool = true
    
    private var scratchedArea: CGFloat = 0
    private var lastPercentage: Double = 0
    private var brushSize: CGFloat = 35
    private var isFirstTouch = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // IMPEDISCE PROPAGAZIONE AI GESTI SOTTOSTANTI
        super.touchesBegan(touches, with: event)
        next?.touchesBegan(touches, with: event)
        
        if isFirstTouch {
            showHintBinding?.wrappedValue = false
            showHint = false
            isFirstTouch = false
        }
        
        handleTouches(touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // IMPEDISCE PROPAGAZIONE AI GESTI SOTTOSTANTI
        super.touchesMoved(touches, with: event)
        next?.touchesMoved(touches, with: event)
        
        handleTouches(touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // IMPEDISCE PROPAGAZIONE AI GESTI SOTTOSTANTI
        super.touchesEnded(touches, with: event)
        next?.touchesEnded(touches, with: event)
    }
    
    private func handleTouches(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let previousPoint = touch.previousLocation(in: self)
        
        touchPointsBinding?.wrappedValue.append(point)
        
        // Calcola area grattata
        let distance = hypot(point.x - previousPoint.x, point.y - previousPoint.y)
        let radius = brushSize * (1 + CGFloat.random(in: -0.2...0.2))
        
        if distance > 0 {
            scratchedArea += CGFloat.pi * radius * radius * 0.5
            scratchedArea += distance * radius * 1.5
        } else {
            scratchedArea += CGFloat.pi * radius * radius
        }
        
        let totalArea = bounds.width * bounds.height
        let percentage = min((scratchedArea / totalArea) * 100, 100)
        
        if abs(percentage - lastPercentage) > 0.5 {
            scratchedPercentageBinding?.wrappedValue = percentage
            onScratch?(percentage)
            lastPercentage = percentage
        }
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Sfondo
        context.setFillColor(UIColor(white: 0.22, alpha: 0.98).cgColor)
        context.fill(rect)
        
        // Pattern
        context.setFillColor(UIColor(white: 0.28, alpha: 1).cgColor)
        let step: CGFloat = 6
        for x in stride(from: 0, through: rect.width, by: step) {
            for y in stride(from: 0, through: rect.height, by: step) {
                if (Int(x/step) + Int(y/step)) % 3 == 0 {
                    let dotRect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.fill(dotRect)
                }
            }
        }
        
        // Rimuovi aree grattate
        context.setBlendMode(.clear)
        
        if let binding = touchPointsBinding {
            let points = binding.wrappedValue.suffix(150)
            
            for point in points {
                let size = brushSize + CGFloat.random(in: -5...8)
                let circleRect = CGRect(
                    x: point.x - size/2,
                    y: point.y - size/2,
                    width: size,
                    height: size
                )
                context.fillEllipse(in: circleRect)
                
                for _ in 0..<8 {
                    let offsetX = CGFloat.random(in: -size...size)
                    let offsetY = CGFloat.random(in: -size...size)
                    let extraSize = CGFloat.random(in: 5...12)
                    let extraRect = CGRect(
                        x: point.x + offsetX - extraSize/2,
                        y: point.y + offsetY - extraSize/2,
                        width: extraSize,
                        height: extraSize
                    )
                    context.fillEllipse(in: extraRect)
                }
            }
        }
    }
}

// MARK: - SLOT MACHINE FINAL - PROPORZIONI PERFETTE
struct SlotMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var gameState: GameState = .initial
    @State private var reel1Index: Int = Int.random(in: 0..<6)
    @State private var reel2Index: Int = Int.random(in: 0..<6)
    @State private var reel3Index: Int = Int.random(in: 0..<6)
    @State private var winAmount: Int = 0
    @State private var isSpinning = false
    @State private var showInsufficientBalance = false
    @State private var spinCount = 0
    @State private var spinTimer: Timer? = nil
    @State private var reelPositions: [CGFloat] = [0, 0, 0]
    @State private var reelSpeeds: [CGFloat] = [0, 0, 0]
    @State private var showWinAnimation = false
    
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
            backgroundGradient
            
            VStack(spacing: 0) {
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
            spinTimer?.invalidate()
            spinTimer = nil
        }
        .alert("Saldo insufficiente", isPresented: $showInsufficientBalance) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(String(format: "Serve €10 per giocare.\nTuo saldo: €%.2f", balance))
        }
    }
    
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
                
                HStack(spacing: 6) {
                    Image(systemName: "slot.machine")
                        .font(.system(size: 16))
                        .foregroundColor(.pink)
                    
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
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
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
    
    private var initialContent: some View {
        VStack(spacing: 28) {
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
            
            VStack(spacing: 12) {
                infoCardSlot(icon: "eurosign.circle", title: "Costo per giro", value: "€10", color: .pink)
                infoCardSlot(icon: "crown.fill", title: "Premio massimo", value: "€500", color: .yellow)
                infoCardSlot(icon: "checkmark.circle", title: "3 simboli uguali", value: "Vincita!", color: .green)
            }
            
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
    
    private var spinningContent: some View {
        VStack(spacing: 28) {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    SlotReelProportionalView(
                        symbol: $reel1Index,
                        symbols: symbols,
                        isSpinning: isSpinning,
                        position: $reelPositions[0],
                        speed: $reelSpeeds[0],
                        reelIndex: 0
                    )
                    .frame(width: 100, height: 160)
                    
                    SlotReelProportionalView(
                        symbol: $reel2Index,
                        symbols: symbols,
                        isSpinning: isSpinning,
                        position: $reelPositions[1],
                        speed: $reelSpeeds[1],
                        reelIndex: 1
                    )
                    .frame(width: 100, height: 160)
                    
                    SlotReelProportionalView(
                        symbol: $reel3Index,
                        symbols: symbols,
                        isSpinning: isSpinning,
                        position: $reelPositions[2],
                        speed: $reelSpeeds[2],
                        reelIndex: 2
                    )
                    .frame(width: 100, height: 160)
                }
                .frame(maxWidth: .infinity)
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
    
    private var resultContent: some View {
        VStack(spacing: 28) {
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    VStack {
                        Text(symbols[reel1Index])
                            .font(.system(size: 56))
                            .shadow(color: winAmount > 0 ? .yellow.opacity(0.8) : .clear, radius: 10)
                    }
                    .frame(width: 100, height: 140)
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
                                        Color.yellow.opacity(0.8) :
                                        Color.white.opacity(0.1),
                                        lineWidth: winAmount > 0 ? 3 : 1
                                    )
                            )
                    )
                    
                    VStack {
                        Text(symbols[reel2Index])
                            .font(.system(size: 56))
                            .shadow(color: winAmount > 0 ? .yellow.opacity(0.8) : .clear, radius: 10)
                    }
                    .frame(width: 100, height: 140)
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
                                        Color.yellow.opacity(0.8) :
                                        Color.white.opacity(0.1),
                                        lineWidth: winAmount > 0 ? 3 : 1
                                    )
                            )
                    )
                    
                    VStack {
                        Text(symbols[reel3Index])
                            .font(.system(size: 56))
                            .shadow(color: winAmount > 0 ? .yellow.opacity(0.8) : .clear, radius: 10)
                    }
                    .frame(width: 100, height: 140)
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
                                        Color.yellow.opacity(0.8) :
                                        Color.white.opacity(0.1),
                                        lineWidth: winAmount > 0 ? 3 : 1
                                    )
                            )
                    )
                }
                .frame(maxWidth: .infinity)
                
                if winAmount > 0 {
                    Text("JACKPOT!")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                        .scaleEffect(showWinAnimation ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: showWinAnimation
                        )
                        .onAppear { showWinAnimation = true }
                        .onDisappear { showWinAnimation = false }
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
            
            HStack(spacing: 16) {
                Button(action: playAgain) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("RIGIOCA SUBITO")
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
    
    private func startSpin() {
        guard balance >= 10 else {
            showInsufficientBalance = true
            return
        }
        
        balance -= 10
        gameState = .spinning
        isSpinning = true
        spinCount += 1
        showWinAnimation = false
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Reset velocità con valori iniziali diversi per ogni rullo
        for i in 0..<3 {
            reelSpeeds[i] = CGFloat.random(in: 15...25)
            reelPositions[i] = 0
        }
        
        // Timer per animazione con fisica realistica
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in 0..<3 {
                // Accelerazione graduale
                if reelSpeeds[i] < 35 {
                    reelSpeeds[i] += CGFloat.random(in: 0.3...0.7)
                }
                
                // Movimento
                reelPositions[i] += reelSpeeds[i]
                
                // Reset posizione e cambio simbolo
                if reelPositions[i] > 80 {
                    reelPositions[i] -= 80
                    
                    switch i {
                    case 0: reel1Index = Int.random(in: 0..<symbols.count)
                    case 1: reel2Index = Int.random(in: 0..<symbols.count)
                    case 2: reel3Index = Int.random(in: 0..<symbols.count)
                    default: break
                    }
                }
            }
        }
        
        // Stop con decelerazione progressiva
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            stopSpinWithDeceleration()
        }
    }
    
    private func stopSpinWithDeceleration() {
        var decelerationCount = 0
        
        let decelerationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            decelerationCount += 1
            var allStopped = true
            
            for i in 0..<3 {
                // Decelerazione
                if reelSpeeds[i] > 0.5 {
                    reelSpeeds[i] *= 0.82
                    reelSpeeds[i] -= 0.3
                    allStopped = false
                } else {
                    reelSpeeds[i] = 0
                }
                
                // Movimento residuo
                reelPositions[i] += reelSpeeds[i]
                
                if reelPositions[i] > 80 {
                    reelPositions[i] -= 80
                    
                    switch i {
                    case 0: reel1Index = Int.random(in: 0..<symbols.count)
                    case 1: reel2Index = Int.random(in: 0..<symbols.count)
                    case 2: reel3Index = Int.random(in: 0..<symbols.count)
                    default: break
                    }
                }
            }
            
            if allStopped || decelerationCount > 35 {
                timer.invalidate()
                finalizeSpin()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            decelerationTimer.invalidate()
            finalizeSpin()
        }
    }
    
    private func finalizeSpin() {
        spinTimer?.invalidate()
        spinTimer = nil
        isSpinning = false
        
        // Posizioni finali
        reelPositions = [0, 0, 0]
        reelSpeeds = [0, 0, 0]
        
        // Simboli finali
        reel1Index = Int.random(in: 0..<symbols.count)
        reel2Index = Int.random(in: 0..<symbols.count)
        reel3Index = Int.random(in: 0..<symbols.count)
        
        // Calcola vincita
        if reel1Index == reel2Index && reel2Index == reel3Index {
            let symbol = symbols[reel1Index]
            let multiplier = symbolMultipliers[symbol] ?? 0
            winAmount = multiplier * 10
            
            balance += Double(winAmount)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showWinAnimation = true
        } else {
            winAmount = 0
            showWinAnimation = false
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            gameState = .finished
        }
    }
    
    private func playAgain() {
        withAnimation(.easeOut(duration: 0.3)) {
            gameState = .spinning
            winAmount = 0
            showWinAnimation = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                startSpin()
            }
        }
    }
}

// MARK: - SLOT REEL PROPORTIONAL VIEW - PERFETTE PROPORZIONI
struct SlotReelProportionalView: View {
    @Binding var symbol: Int
    let symbols: [String]
    let isSpinning: Bool
    @Binding var position: CGFloat
    @Binding var speed: CGFloat
    let reelIndex: Int
    
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
            
            // Simboli animati - 5 simboli per scorrimento fluido
            VStack(spacing: 8) {
                ForEach(-2..<3) { i in
                    let index = (symbol + i + symbols.count * 2) % symbols.count
                    Text(symbols[index])
                        .font(.system(size: 42))
                        .shadow(color: .white.opacity(0.2), radius: 2)
                        .blur(radius: isSpinning ? min(speed / 12, 2.5) : 0)
                }
            }
            .offset(y: position)
            
            // Effetti di luce
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 35)
                
                Spacer()
                
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.15)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 35)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Bordo metallico
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        }
        .frame(width: 100, height: 160)
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
                        .fill(color.opacity(0.15))
                        .frame(width: 70, height: 70)
                        .blur(radius: 8)
                    
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