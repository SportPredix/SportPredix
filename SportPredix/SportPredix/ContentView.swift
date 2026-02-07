//
//  ContentView.swift
//  SportPredix
//

import SwiftUI
import AuthenticationServices

// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

// MARK: - FLOATING GLASS TOOLBAR (SENZA ETICHETTE)

struct FloatingGlassToolbar: View {
    @Binding var selectedTab: Int
    @Namespace private var animationNamespace
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Barra principale fluttuante - PIÙ IN BASSO
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    FloatingToolbarButton(
                        index: index,
                        selectedTab: $selectedTab,
                        animationNamespace: animationNamespace
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16) // Più spesso
            .background(
                // Effetto vetro sfocato con riflessi
                FloatingGlassEffect()
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: .black.opacity(0.4),
                radius: 30,
                x: 0,
                y: 10
            )
            .overlay(
                // Bordo luminoso superiore
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .accentCyan.opacity(0.2),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 35) // PIÙ IN BASSO - da 20 a 35
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(true)
        .zIndex(1000)
    }
}

struct FloatingGlassEffect: View {
    @State private var shimmerOffset: CGFloat = -300
    
    var body: some View {
        ZStack {
            // Base vetro sfocato
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.95)
            
            // Base colore
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.11, blue: 0.13).opacity(0.85),
                            Color(red: 0.06, green: 0.07, blue: 0.09).opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Effetto shimmer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.08),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .blur(radius: 2)
                .mask(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            
            // Puntini luminosi
            GeometryReader { geometry in
                ForEach(0..<20) { i in
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: CGFloat.random(in: 1...4))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 1)
                }
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 300
            }
        }
    }
}

struct FloatingToolbarButton: View {
    let index: Int
    @Binding var selectedTab: Int
    let animationNamespace: Namespace.ID
    
    private var icon: String {
        switch index {
        case 0: return "calendar"
        case 1: return "dice.fill"
        case 2: return "list.bullet"
        case 3: return "person.crop.circle"
        default: return "circle"
        }
    }
    
    var body: some View {
        Button {
            withAnimation(
                .spring(response: 0.3, dampingFraction: 0.7)
            ) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 0) {
                // Solo icona - NESSUNA ETICHETTA
                ZStack {
                    // Glow quando selezionato
                    if selectedTab == index {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        .accentCyan.opacity(0.4),
                                        .clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 70, height: 70)
                            .matchedGeometryEffect(id: "glow", in: animationNamespace)
                    }
                    
                    // Cerchio di sfondo
                    Circle()
                        .fill(
                            selectedTab == index ?
                            LinearGradient(
                                colors: [.accentCyan.opacity(0.5), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.white.opacity(0.08), .white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedTab == index ?
                                    LinearGradient(
                                        colors: [.accentCyan.opacity(0.6), .white.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [.white.opacity(0.15), .white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: selectedTab == index ? 2 : 1
                                )
                                .blur(radius: selectedTab == index ? 1 : 0.5)
                        )
                    
                    // Icona
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .symbolEffect(
                            .bounce,
                            options: .speed(1.8),
                            value: selectedTab == index
                        )
                        .foregroundColor(
                            selectedTab == index ? 
                            .white : 
                            .white.opacity(0.8)
                        )
                        .shadow(
                            color: selectedTab == index ? 
                            .accentCyan.opacity(0.6) : 
                            .clear,
                            radius: 4
                        )
                }
                .frame(width: 56, height: 56)
            }
        }
        .buttonStyle(FloatingButtonStyle(isSelected: selectedTab == index))
    }
}

struct FloatingButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

// MARK: - HEADER FLUTTUANTE

struct FloatingHeader: View {
    let title: String
    let balance: Double
    @Binding var showSportPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Titolo
                HStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    if title == "Sport" {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentCyan)
                            .rotationEffect(.degrees(showSportPicker ? 180 : 0))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    showSportPicker.toggle()
                                }
                            }
                    }
                }
                
                Spacer()
                
                // Saldo
                HStack(spacing: 6) {
                    Image(systemName: "eurosign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentCyan)
                        .symbolEffect(.pulse, options: .speed(0.5))
                    
                    Text("€\(balance, specifier: "%.2f")")
                        .font(.headline.monospacedDigit())
                        .foregroundColor(.accentCyan)
                        .bold()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentCyan.opacity(0.3), lineWidth: 1)
                                .blur(radius: 0.5)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Color.black.opacity(0.3)
                    .background(.ultraThinMaterial.opacity(0.7))
                    .edgesIgnoringSafeArea(.top)
            )
            
            // Linea divisoria
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
    }
}

// MARK: - MAIN VIEW CON TOOLBAR SOPRA

struct ContentView: View {
    
    @StateObject private var vm = BettingViewModel()
    @Namespace private var animationNamespace
    
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Sfondo principale
                Color.black.ignoresSafeArea()
                
                if vm.isSignedInWithApple {
                    ZStack {
                        // CONTENUTO PRINCIPALE
                        VStack(spacing: 0) {
                            // Header (tranne per Casino)
                            if vm.selectedTab != 1 {
                                FloatingHeader(
                                    title: vm.selectedTab == 0 ? "Sport" : 
                                           vm.selectedTab == 2 ? "Storico" : "Profilo",
                                    balance: vm.balance,
                                    showSportPicker: $vm.showSportPicker
                                )
                            }
                            
                            // Contenuto per ogni tab
                            Group {
                                if vm.selectedTab == 0 {
                                    calendarBarView
                                    
                                    if vm.isLoading {
                                        loadingView
                                    } else {
                                        matchListView
                                    }
                                } else if vm.selectedTab == 1 {
                                    // Casino - CON SFONDO CHE SI ESTENDE
                                    CasinoFullView()
                                        .environmentObject(vm)
                                        .edgesIgnoringSafeArea(.bottom) // Importante
                                } else if vm.selectedTab == 2 {
                                    placedBetsView
                                        .padding(.bottom, 100)
                                } else if vm.selectedTab == 3 {
                                    ProfileView()
                                        .environmentObject(vm)
                                        .padding(.bottom, 100)
                                } else {
                                    Color.black
                                        .padding(.bottom, 100)
                                }
                            }
                        }
                        .id(refreshID)
                        
                        // TOOLBAR FLUTTUANTE SOPRA IL CONTENUTO
                        FloatingGlassToolbar(selectedTab: $vm.selectedTab)
                        
                        // Bottoni fluttuanti per scommesse
                        floatingButtonView
                    }
                } else {
                    AppleSignInRequiredView()
                }
            }
            .sheet(isPresented: $vm.showSheet) {
                BetSheet(
                    picks: $vm.currentPicks,
                    balance: $vm.balance,
                    totalOdd: vm.totalOdd
                ) { stake in vm.confirmSlip(stake: stake) }
            }
            .sheet(item: $vm.showSlipDetail) { SlipDetailView(slip: $0) }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.checkAppleAuthOnLaunch()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppleSignInCompleted"))) { _ in
            refreshID = UUID()
            vm.objectWillChange.send()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppleSignOutCompleted"))) { _ in
            refreshID = UUID()
            vm.objectWillChange.send()
        }
    }
    
    // MARK: - CALENDAR BAR
    private var calendarBarView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    let date = vm.dateForIndex(index)
                    
                    VStack(spacing: 4) {
                        Text(vm.formattedDay(date))
                            .font(.title2.bold())
                        Text(vm.formattedMonth(date))
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 90, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(vm.selectedDayIndex == index ? Color.accentCyan : Color.white.opacity(0.2), lineWidth: 3)
                    )
                    .onTapGesture { vm.selectedDayIndex = index }
                    .animation(.easeInOut, value: vm.selectedDayIndex)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: LOADING VIEW
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentCyan))
                .scaleEffect(1.5)
            
            Text("Caricamento partite...")
                .foregroundColor(.accentCyan)
                .font(.headline)
            
            Text("Sto recuperando le quote più recenti")
                .foregroundColor(.gray)
                .font(.caption)
            
            Spacer()
        }
        .padding(.bottom, 100)
    }
    
    // MARK: MATCH LIST
    private var matchListView: some View {
        let groupedMatches = vm.matchesForSelectedDay()
        let isYesterday = vm.selectedDayIndex == 0
        
        return ScrollView {
            VStack(spacing: 16) {
                if groupedMatches.isEmpty && !vm.isLoading {
                    emptyMatchesView
                } else {
                    ForEach(groupedMatches.keys.sorted(), id: \.self) { time in
                        VStack(spacing: 10) {
                            HStack {
                                Text(time)
                                    .font(.headline)
                                    .foregroundColor(.accentCyan)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            
                            ForEach(groupedMatches[time]!) { match in
                                NavigationLink(destination: MatchDetailView(match: match, vm: vm)) {
                                    matchCardView(match: match, disabled: isYesterday)
                                }
                                .disabled(isYesterday)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100) // Spazio per la toolbar
        }
        .id("\(vm.selectedDayIndex)-\(vm.selectedSport)")
        .transition(.opacity)
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 50)
            
            Image(systemName: vm.selectedSport == "Calcio" ? "soccerball" : "tennis.racket")
                .font(.system(size: 60))
                .foregroundColor(.accentCyan)
            
            Text("Nessuna partita disponibile")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Torna più tardi per vedere nuove partite")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.bottom, 100)
    }
    
    private func matchCardView(match: Match, disabled: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.home)
                        .font(.headline)
                        .foregroundColor(disabled ? .gray : .white)
                        .lineLimit(1)
                    
                    Text(match.competition)
                        .font(.caption2)
                        .foregroundColor(.accentCyan)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.away)
                        .font(.headline)
                        .foregroundColor(disabled ? .gray : .white)
                        .lineLimit(1)
                    
                    if let actualResult = match.actualResult {
                        Text(actualResult)
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text(match.status)
                            .font(.caption2)
                            .foregroundColor(match.status == "FINISHED" ? .green : 
                                           match.status == "LIVE" ? .red : .orange)
                    }
                }
            }
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(match.odds.home, specifier: "%.2f")")
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                
                if vm.selectedSport == "Calcio" {
                    Divider()
                        .frame(height: 30)
                        .background(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 4) {
                        Text("X")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(match.odds.draw, specifier: "%.2f")")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                    .frame(height: 30)
                    .background(Color.gray.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("2")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(match.odds.away, specifier: "%.2f")")
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(disabled ? Color.gray.opacity(0.1) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(disabled ? Color.gray.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(disabled ? 0.6 : 1.0)
    }
    
    // MARK: PLACED BETS
    private var placedBetsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                if vm.slips.isEmpty {
                    emptyBetsView
                } else {
                    ForEach(vm.slips) { slip in
                        Button { vm.showSlipDetail = slip } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quota \(slip.totalOdd, specifier: "%.2f")")
                                    .foregroundColor(.accentCyan)
                                Text("Puntata €\(slip.stake, specifier: "%.2f")")
                                    .foregroundColor(.white)
                                Text("Vincita potenziale €\(slip.potentialWin, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                if let won = slip.isWon {
                                    Text(won ? "ESITO: VINTA" : "ESITO: PERSA")
                                        .foregroundColor(won ? .green : .red)
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        .onAppear { vm.evaluateAllSlips() }
    }
    
    private var emptyBetsView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 50)
            
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.accentCyan)
            
            Text("Nessuna scommessa piazzata")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Torna alla sezione scommesse per iniziare")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - FLOATING BUTTON PER SCHEDINE
    private var floatingButtonView: some View {
        Group {
            if !vm.currentPicks.isEmpty && vm.selectedTab != 3 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack(alignment: .topTrailing) {
                            Button { vm.showSheet = true } label: {
                                Image(systemName: "rectangle.stack.fill")
                                    .foregroundColor(.black)
                                    .padding(16)
                                    .background(Color.accentCyan)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                            }
                            
                            Text("\(vm.currentPicks.count)")
                                .font(.caption2.bold())
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                                .offset(x: 8, y: -8)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 120) // Sopra la toolbar
                    }
                }
            }
        }
    }
}

// MARK: - CASINO FULL VIEW (SISTEMATO PER SFONDO A TUTTA PAGINA)

struct CasinoFullView: View {
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        ZStack {
            // SFONDO CHE SI ESTENDE OVUNQUE
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .edgesIgnoringSafeArea(.all) // IMPORTANTE: si estende ovunque
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        Text("Casino")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("€\(vm.balance, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.accentCyan)
                            .bold()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // Linea divisoria
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
                .background(Color.black.opacity(0.3))
                
                // Contenuto del Casino che SI ESTENDE FINO IN FONDO
                GamesContentView()
                    .environmentObject(vm)
            }
        }
    }
}

// MARK: - GAMES CONTENT VIEW (SISTEMATO)

struct GamesContentView: View {
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
                .padding(.bottom, 50) // Spazio minore, lo sfondo si estende
            }
            .padding(.bottom, 120) // Spazio per la toolbar
        }
        .background(Color.clear) // Trasparente per mostrare lo sfondo del CasinoFullView
    }
}

// MARK: - APPLE SIGN IN REQUIRED VIEW (resta invariato)

struct AppleSignInRequiredView: View {
    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentCyan.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "apple.logo")
                    .font(.system(size: 50))
                    .foregroundColor(.accentCyan)
            }
            
            VStack(spacing: 12) {
                Text("Benvenuto in SportPredix")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Accedi con il tuo Apple ID per iniziare a scommettere\nÈ l'unico metodo di accesso disponibile per garantire la massima sicurezza.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                benefitRow(
                    icon: "lock.shield.fill",
                    title: "Privacy Garantita",
                    description: "Apple non traccia la tua attività nelle scommesse"
                )
                
                benefitRow(
                    icon: "envelope.badge.fill",
                    title: "Email Protetta",
                    description: "La tua email personale rimane sempre privata"
                )
                
                benefitRow(
                    icon: "checkmark.seal.fill",
                    title: "Sicurezza Apple",
                    description: "Face ID / Touch ID integrati"
                )
                
                benefitRow(
                    icon: "person.badge.key.fill",
                    title: "Accesso Esclusivo",
                    description: "Solo utenti Apple possono utilizzare l'app"
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            Spacer()
            
            if isSigningIn {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.accentCyan)
                    
                    Text("Accesso in corso...")
                        .foregroundColor(.accentCyan)
                        .font(.caption)
                }
                .padding(.bottom, 40)
            } else {
                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        isSigningIn = true
                    } onCompletion: { result in
                        handleSignInCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    
                    Button(action: {
                        let debugUserID = "debug_user_\(UUID().uuidString)"
                        UserDefaults.standard.set(debugUserID, forKey: "appleUserID")
                        UserDefaults.standard.set("Debug User", forKey: "userName")
                        UserDefaults.standard.synchronize()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("AppleSignInCompleted"),
                                object: nil
                            )
                        }
                    }) {
                        Text("Debug Login (testing)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                    
                    Text("Nessun altro metodo di accesso disponibile")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .padding()
        .alert("Errore Accesso", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentCyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    private func handleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        DispatchQueue.main.async {
            isSigningIn = false
            
            switch result {
            case .success(let authorization):
                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    let userID = credential.user
                    UserDefaults.standard.set(userID, forKey: "appleUserID")
                    
                    if let fullName = credential.fullName {
                        let nameComponents = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                        
                        if !nameComponents.isEmpty {
                            let fullNameString = nameComponents.joined(separator: " ")
                            UserDefaults.standard.set(fullNameString, forKey: "userName")
                        } else if let currentName = UserDefaults.standard.string(forKey: "userName") {
                            UserDefaults.standard.set(currentName, forKey: "userName")
                        }
                    }
                    
                    UserDefaults.standard.synchronize()
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AppleSignInCompleted"),
                        object: nil,
                        userInfo: ["userID": userID]
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AppleSignInCompleted"),
                            object: nil
                        )
                    }
                } else {
                    errorMessage = "Credenziale di autenticazione non valida"
                    showError = true
                }
                
            case .failure(let error):
                errorMessage = error.localizedDescription
                
                if let authError = error as? ASAuthorizationError {
                    switch authError.code {
                    case .canceled:
                        errorMessage = "Accesso annullato"
                    case .failed:
                        errorMessage = "Accesso fallito"
                    case .invalidResponse:
                        errorMessage = "Risposta non valida"
                    case .notHandled:
                        errorMessage = "Richiesta non gestita"
                    case .unknown:
                        errorMessage = "Errore sconosciuto"
                    case .notInteractive:
                        errorMessage = "Richiesta non interattiva"
                    case .matchedExcludedCredential:
                        errorMessage = "Credenziali escluse"
                    case .credentialImport:
                        errorMessage = "Errore import credenziali"
                    case .credentialExport:
                        errorMessage = "Errore export credenziali"
                    case .preferSignInWithApple:
                        errorMessage = "Preferito Sign in with Apple"
                    case .deviceNotConfiguredForPasskeyCreation:
                        errorMessage = "Dispositivo non configurato"
                    @unknown default:
                        errorMessage = "Errore sconosciuto"
                    }
                }
                
                showError = true
            }
        }
    }
}
// MARK: - CASINO FULL VIEW

struct CasinoFullView: View {
    @EnvironmentObject var vm: BettingViewModel
    
    var body: some View {
        ZStack {
            // Sfondo che parte DALL'ALTO e copre TUTTO
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header DEDICATO per Casino
                VStack(spacing: 0) {
                    HStack {
                        Text("Casino")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Saldo utente
                        Text("€\(vm.balance, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.accentCyan)
                            .bold()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
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
                .background(Color.black.opacity(0.3))
                
                // Contenuto del Casino
                GamesContentView()
                    .environmentObject(vm)
            }
        }
    }
}

// MARK: - GAMES CONTENT VIEW

struct GamesContentView: View {
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
                        // Usa GameButton dal file GameView.swift
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
            .padding(.bottom, 100) // Spazio extra per la toolbar
        }
        .background(Color.clear)
    }
}