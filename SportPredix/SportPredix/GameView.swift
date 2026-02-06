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
        ZStack {
            // Sfondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Particelle di sfondo
            GeometryReader { geometry in
                ForEach(0..<15) { i in
                    Circle()
                        .fill(Color.accentCyan.opacity(0.1))
                        .frame(width: CGFloat.random(in: 5...20))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 2)
                }
            }
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Casino")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Gioca e Vinci")
                            .font(.title3)
                            .foregroundColor(.accentCyan)
                        
                        Text("Saldo: €\(vm.balance, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 5)
                    }
                    .padding(.top, 20)
                    
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
                        .padding(.top, 10)
                        
                        Text("Le vincite sono virtuali")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                }
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
                
                Text("Gioca")
                    .font(.caption)
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .cornerRadius(10)
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
                ComingSoonView(gameName: title)
            }
        }
    }
}

// MARK: - GIOCO GRATTA E VINCI RIVISTO
struct ScratchCardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var scratchedPoints: [CGPoint] = []
    @State private var isScratched = false
    @State private var prize: Int = 0
    @State private var showPrize = false
    @State private var scratchOpacity: Double = 1.0
    @State private var showResult = false
    @State private var scratchesNeeded = 40
    @State private var currentScratches = 0
    @State private var animationAmount: Double = 0
    @State private var confetti: [Confetti] = []
    
    // Premi più realistici con probabilità
    let prizes = [
        (amount: 0, probability: 40, color: Color.gray),
        (amount: 50, probability: 25, color: Color.green),
        (amount: 100, probability: 15, color: Color.yellow),
        (amount: 250, probability: 10, color: Color.orange),
        (amount: 500, probability: 7, color: Color.pink),
        (amount: 1000, probability: 3, color: Color.red)
    ]
    
    var body: some View {
        ZStack {
            // Sfondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.15, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti
            ForEach(confetti) { confetto in
                ConfettiView(confetto: confetto)
            }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.accentCyan)
                            .font(.system(size: 24))
                    }
                    
                    Spacer()
                    
                    Text("GRATTA & VINCI")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Pulsante saldo
                    Text("€\(balance, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.accentCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentCyan.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if !showResult {
                    // Istruzioni
                    VStack(spacing: 10) {
                        Text("Gratta per scoprire il tuo premio!")
                            .font(.headline)
                            .foregroundColor(.accentCyan)
                        
                        Text("Premi possibili:")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        // Premi disponibili
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(prizes.filter { $0.amount > 0 }, id: \.amount) { prize in
                                    PrizeChip(amount: prize.amount, color: prize.color)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 5)
                        
                        // Progresso grattatura
                        VStack(spacing: 8) {
                            Text("Gratta l'area per rivelare")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            ProgressView(value: Double(currentScratches), total: Double(scratchesNeeded))
                                .progressViewStyle(LinearProgressViewStyle(tint: .accentCyan))
                                .frame(width: 200)
                                .scaleEffect(y: 1.5)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // CARD GRATTA E VINCI
                    ZStack {
                        // PREMIO (sotto)
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.1, green: 0.6, blue: 0.5),
                                            Color(red: 0.2, green: 0.8, blue: 0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 320, height: 400)
                                .shadow(color: .accentCyan.opacity(0.5), radius: 20)
                            
                            VStack(spacing: 15) {
                                if prize > 0 {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.yellow)
                                        .shadow(color: .yellow, radius: 10)
                                    
                                    Text("€\(prize)")
                                        .font(.system(size: 64, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                        .shadow(color: .white, radius: 5)
                                    
                                    Text("HAI VINTO!")
                                        .font(.title.bold())
                                        .foregroundColor(.black)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.title)
                                        .foregroundColor(.yellow)
                                        .rotationEffect(.degrees(animationAmount * 360))
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    
                                    Text("RITENTA")
                                        .font(.system(size: 50, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                    
                                    Text("Nessun premio questa volta")
                                        .font(.title3)
                                        .foregroundColor(.black.opacity(0.8))
                                    
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // STRATO DA GRATTARE (sopra)
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.9),
                                            Color.gray.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 320, height: 400)
                                .overlay(
                                    ZStack {
                                        // Pattern texture
                                        ForEach(0..<50) { i in
                                            Circle()
                                                .fill(Color.black.opacity(0.1))
                                                .frame(width: CGFloat.random(in: 5...15))
                                                .position(
                                                    x: CGFloat.random(in: 0...320),
                                                    y: CGFloat.random(in: 0...400)
                                                )
                                        }
                                        
                                        VStack(spacing: 20) {
                                            Image(systemName: "hand.tap.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white.opacity(0.3))
                                            
                                            Text("GRATTA QUI")
                                                .font(.title.bold())
                                                .foregroundColor(.white.opacity(0.4))
                                                .shadow(color: .black.opacity(0.5), radius: 2)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.title)
                                                .foregroundColor(.accentCyan.opacity(0.3))
                                        }
                                    }
                                )
                        }
                        .opacity(scratchOpacity)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !isScratched && scratchOpacity > 0 {
                                        let newPoint = value.location
                                        scratchedPoints.append(newPoint)
                                        currentScratches += 1
                                        
                                        // Effetto di grattatura
                                        withAnimation(.linear(duration: 0.1)) {
                                            scratchOpacity = max(0.0, scratchOpacity - 0.02)
                                        }
                                        
                                        if currentScratches >= scratchesNeeded {
                                            revealPrize()
                                        }
                                    }
                                }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.accentCyan.opacity(0.5), lineWidth: 3)
                            .shadow(color: .accentCyan, radius: 10)
                    )
                    
                    Spacer()
                    
                    // Pulsanti azione
                    HStack(spacing: 20) {
                        Button {
                            resetScratchCard()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Nuova Card")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(15)
                        }
                        
                        Button {
                            revealPrize()
                        } label: {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text("Rivela Ora")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentCyan)
                            .cornerRadius(15)
                        }
                        .disabled(isScratched)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    
                } else {
                    // Schermata risultato
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // Animazione risultato
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            prize > 0 ? .yellow.opacity(0.3) : .gray.opacity(0.3),
                                            .clear
                                        ]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 150
                                    )
                                )
                                .frame(width: 300, height: 300)
                                .scaleEffect(animationAmount)
                                .animation(
                                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                    value: animationAmount
                                )
                            
                            VStack(spacing: 20) {
                                Image(systemName: prize > 0 ? "gift.fill" : "xmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(prize > 0 ? .yellow : .gray)
                                    .shadow(color: prize > 0 ? .yellow : .gray, radius: 10)
                                
                                Text(prize > 0 ? "COMPLIMENTI!" : "PECCATO!")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(prize > 0 ? .accentCyan : .white)
                                
                                Text(prize > 0 ? "€\(prize)" : "Nessun premio")
                                    .font(.system(size: 60, weight: .bold, design: .rounded))
                                    .foregroundColor(prize > 0 ? .yellow : .gray)
                                    .shadow(color: prize > 0 ? .yellow.opacity(0.5) : .clear, radius: 5)
                                
                                if prize > 0 {
                                    Text("+ €\(prize) aggiunti al saldo!")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                        .padding(.top, 5)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Pulsanti
                        VStack(spacing: 15) {
                            Button {
                                resetScratchCard()
                            } label: {
                                Text(prize > 0 ? "GIOCA ANCORA" : "RIPROVA")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentCyan)
                                    .cornerRadius(20)
                                    .shadow(color: .accentCyan.opacity(0.5), radius: 10)
                            }
                            
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("TORNA AL CASINO")
                                    .font(.headline)
                                    .foregroundColor(.accentCyan)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 40)
                }
            }
        }
        .onAppear {
            // Seleziona premio probabilistico
            selectProbabilisticPrize()
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationAmount = 1.2
            }
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
    
    private func revealPrize() {
        withAnimation(.easeInOut(duration: 0.8)) {
            isScratched = true
            scratchOpacity = 0.0
            
            // Aspetta un po' poi mostra il risultato
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring()) {
                    showResult = true
                }
                
                // Aggiungi premio al saldo
                if prize > 0 {
                    balance += Double(prize)
                    
                    // Lancia confetti se vinto
                    launchConfetti()
                    
                    // Feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func resetScratchCard() {
        withAnimation(.spring()) {
            scratchedPoints = []
            isScratched = false
            scratchOpacity = 1.0
            currentScratches = 0
            showResult = false
            confetti = []
            
            // Seleziona nuovo premio probabilistico
            selectProbabilisticPrize()
        }
    }
    
    private func launchConfetti() {
        for _ in 0..<50 {
            let confetto = Confetti(
                id: UUID(),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                color: [.yellow, .accentCyan, .pink, .green, .orange].randomElement()!,
                size: CGFloat.random(in: 5...15),
                speed: CGFloat.random(in: 2...5)
            )
            confetti.append(confetto)
        }
        
        // Rimuovi confetti dopo 3 secondi
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confetti.removeAll()
        }
    }
}

// MARK: - SLOT MACHINE NUOVA E FUNZIONANTE
struct SlotMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var balance: Double
    
    @State private var reels: [[String]] = [
        ["🍒", "🍋", "🍊", "⭐", "🔔", "7️⃣"],
        ["🍒", "🍋", "🍊", "⭐", "🔔", "7️⃣"],
        ["🍒", "🍋", "🍊", "⭐", "🔔", "7️⃣"]
    ]
    
    @State private var currentReels = ["🍒", "🍒", "🍒"]
    @State private var isSpinning = false
    @State private var spinCount = 0
    @State private var betAmount: Double = 10
    @State private var winAmount: Double = 0
    @State private var showWinAnimation = false
    @State private var lastWin: Double = 0
    @State private var jackpot: Double = 5000
    @State private var sparklePositions: [CGPoint] = []
    
    let betOptions: [Double] = [5, 10, 25, 50, 100]
    
    var body: some View {
        ZStack {
            // Sfondo slot machine
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Luci neone
            GeometryReader { geometry in
                ForEach(0..<8) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.pink.opacity(0.3),
                                    Color.pink.opacity(0.1),
                                    .clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200)
                        .position(
                            x: CGFloat(i % 2 == 0 ? 0 : geometry.size.width),
                            y: CGFloat(i / 2) * (geometry.size.height / 4) + 50
                        )
                        .blur(radius: 30)
                }
            }
            
            // Scintille vincenti
            ForEach(sparklePositions, id: \.self) { position in
                Image(systemName: "sparkle")
                    .foregroundColor(.yellow)
                    .font(.caption)
                    .position(position)
                    .opacity(showWinAnimation ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: showWinAnimation)
            }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.pink)
                            .font(.system(size: 24))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("SLOT MACHINE")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(color: .pink, radius: 5)
                        
                        Text("JACKPOT: €\(jackpot, specifier: "%.0f")")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SALDO")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("€\(balance, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.accentCyan)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Area slot machine
                VStack(spacing: 0) {
                    // Cornice superiore
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.gray, .white, .gray]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 20)
                        .cornerRadius(10, corners: [.topLeft, .topRight])
                    
                    // Schermo slot
                    ZStack {
                        // Sfondo schermo
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.05, green: 0.05, blue: 0.15),
                                        Color(red: 0.1, green: 0.1, blue: 0.25)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Reels
                        HStack(spacing: 15) {
                            ForEach(0..<3, id: \.self) { index in
                                ReelView(
                                    symbol: currentReels[index],
                                    isSpinning: isSpinning,
                                    index: index
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Cornice interna
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                            .padding(5)
                    }
                    .frame(height: 180)
                    
                    // Cornice inferiore
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.gray, .white, .gray]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 20)
                        .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                }
                .padding(.horizontal, 30)
                .shadow(color: .black.opacity(0.8), radius: 20, y: 10)
                
                // Linea vincente
                HStack {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(Color.yellow.opacity(0.5))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 5)
                
                // Risultato
                VStack(spacing: 10) {
                    if showWinAnimation {
                        Text("VINTA: €\(winAmount, specifier: "%.2f")")
                            .font(.title.bold())
                            .foregroundColor(.yellow)
                            .scaleEffect(showWinAnimation ? 1.1 : 1.0)
                            .animation(
                                .spring(response: 0.3, dampingFraction: 0.5).repeatCount(3, autoreverses: true),
                                value: showWinAnimation
                            )
                    } else if lastWin > 0 {
                        Text("Ultima vincita: €\(lastWin, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        Text("Pronto a giocare!")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Combinazioni vincenti
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            WinningCombinationView(symbols: ["7️⃣", "7️⃣", "7️⃣"], multiplier: "100x", color: .red)
                            WinningCombinationView(symbols: ["🔔", "🔔", "🔔"], multiplier: "50x", color: .orange)
                            WinningCombinationView(symbols: ["⭐", "⭐", "⭐"], multiplier: "25x", color: .yellow)
                            WinningCombinationView(symbols: ["🍒", "🍒", "🍒"], multiplier: "10x", color: .pink)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }
                .frame(height: 100)
                
                Spacer()
                
                // Controlli
                VStack(spacing: 20) {
                    // Selezione puntata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PUNTATA: €\(betAmount, specifier: "%.0f")")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            ForEach(betOptions, id: \.self) { amount in
                                Button {
                                    betAmount = amount
                                } label: {
                                    Text("€\(Int(amount))")
                                        .font(.headline)
                                        .foregroundColor(betAmount == amount ? .black : .white)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(
                                            betAmount == amount ?
                                            Color.accentCyan :
                                                Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // Pulsante SPIN
                    Button(action: spinReels) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [.pink, .purple]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: .pink.opacity(0.7), radius: 20)
                            
                            if isSpinning {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                            } else {
                                VStack(spacing: 5) {
                                    Text("SPIN")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("€\(betAmount, specifier: "%.0f")")
                                        .font(.headline)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .disabled(isSpinning || balance < betAmount)
                    .scaleEffect(isSpinning ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSpinning)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func spinReels() {
        guard !isSpinning, balance >= betAmount else { return }
        
        // Deduci la puntata
        balance -= betAmount
        
        // Resetta animazione
        showWinAnimation = false
        sparklePositions.removeAll()
        
        // Inizia spin
        isSpinning = true
        spinCount += 1
        
        // Feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Animazione spin
        withAnimation(.easeIn(duration: 0.1)) {
            currentReels = ["❓", "❓", "❓"]
        }
        
        // Simula spin con suoni e vibrazioni
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        
        // Risultato dopo 2 secondi
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let newReels = reels.map { $0.randomElement()! }
            currentReels = newReels
            
            // Calcola vincita
            calculateWin(newReels)
            
            // Fine spin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSpinning = false
                
                // Aggiorna jackpot
                jackpot += betAmount * 0.1
            }
        }
    }
    
    private func calculateWin(_ reels: [String]) {
        winAmount = 0
        
        // Controlla combinazioni vincenti
        if reels[0] == reels[1] && reels[1] == reels[2] {
            // Tre simboli uguali
            switch reels[0] {
            case "7️⃣":
                winAmount = betAmount * 100  // Jackpot!
                jackpot = max(1000, jackpot - winAmount * 0.5)
            case "🔔":
                winAmount = betAmount * 50
            case "⭐":
                winAmount = betAmount * 25
            case "🍊":
                winAmount = betAmount * 15
            case "🍋":
                winAmount = betAmount * 10
            case "🍒":
                winAmount = betAmount * 8
            default:
                winAmount = betAmount * 5
            }
        } else if reels[0] == reels[1] || reels[1] == reels[2] || reels[0] == reels[2] {
            // Due simboli uguali
            winAmount = betAmount * 2
        }
        
        // Se c'è una vincita
        if winAmount > 0 {
            // Aggiungi al saldo
            balance += winAmount
            lastWin = winAmount
            
            // Animazione vincita
            withAnimation(.spring()) {
                showWinAnimation = true
            }
            
            // Crea scintille
            createSparkles()
            
            // Feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Suono (simulato con vibrazione)
            let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
            heavyGenerator.impactOccurred()
            
            // Nascondi animazione dopo 3 secondi
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showWinAnimation = false
                }
            }
        } else {
            // Feedback perdita
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func createSparkles() {
        sparklePositions.removeAll()
        
        for _ in 0..<20 {
            sparklePositions.append(
                CGPoint(
                    x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                    y: CGFloat.random(in: 200...400)
                )
            )
        }
    }
}

// MARK: - COMPONENTI AUSILIARI

struct PrizeChip: View {
    let amount: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "eurosign.circle.fill")
                .foregroundColor(.white)
            
            Text("€\(amount)")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(15)
        .shadow(color: color.opacity(0.5), radius: 3)
    }
}

struct ReelView: View {
    let symbol: String
    let isSpinning: Bool
    let index: Int
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Sfondo reel
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.3),
                            Color(red: 0.1, green: 0.1, blue: 0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.gray.opacity(0.5), .white.opacity(0.2)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            
            // Simbolo
            Text(symbol)
                .font(.system(size: 50))
                .scaleEffect(isSpinning ? 0.8 : 1.0)
                .opacity(isSpinning ? 0.5 : 1.0)
                .animation(
                    .easeInOut(duration: 0.2).repeatCount(isSpinning ? 10 : 0, autoreverses: true),
                    value: isSpinning
                )
        }
        .rotation3DEffect(
            .degrees(isSpinning ? 360 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(
            isSpinning ?
                .linear(duration: 2.0).repeatCount(1, autoreverses: false) :
                .default,
            value: isSpinning
        )
    }
}

struct WinningCombinationView: View {
    let symbols: [String]
    let multiplier: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(symbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.title2)
                }
            }
            
            Text(multiplier)
                .font(.caption.bold())
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.2))
                .cornerRadius(5)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct Confetti: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let speed: CGFloat
}

struct ConfettiView: View {
    let confetto: Confetti
    
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(confetto.color)
            .frame(width: confetto.size, height: confetto.size)
            .position(x: confetto.x, y: confetto.y + yOffset)
            .onAppear {
                withAnimation(.linear(duration: 3)) {
                    yOffset = UIScreen.main.bounds.height + 100
                }
            }
    }
}

struct ComingSoonView: View {
    let gameName: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.15, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "clock.badge")
                    .font(.system(size: 80))
                    .foregroundColor(.accentCyan)
                
                Text("Prossimamente")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text(gameName)
                    .font(.title2)
                    .foregroundColor(.accentCyan)
                    .padding()
                    .background(Color.accentCyan.opacity(0.1))
                    .cornerRadius(15)
                
                Text("Stiamo lavorando a questo gioco\nPresto disponibile!")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button("Torna ai Giochi") {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.dismiss(animated: true)
                    }
                }
                .padding()
                .background(Color.accentCyan)
                .foregroundColor(.black)
                .cornerRadius(15)
                .padding(.bottom, 40)
            }
        }
    }
}

// Estensione per corner radius specifici
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}