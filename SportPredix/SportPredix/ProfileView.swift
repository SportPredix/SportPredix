//
//  ProfileView.swift
//  SportPredix
//
//  Created by Francesco on 16/01/26.
//

import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    
    @EnvironmentObject var vm: BettingViewModel
    @State private var showNameField = false
    @State private var showResetAlert = false
    @State private var showPreferences = false
    @State private var showAppInfoAlert = false
    @State private var tempUserName: String = ""
    @State private var appleUserID: String = ""
    @State private var appleEmail: String = ""
    @State private var appleName: String = ""
    
    // ⭐⭐⭐ NUOVO: Calcola le iniziali con stile Apple
    var initials: String {
        // Prima prova con nome Apple
        if !appleName.isEmpty {
            let parts = appleName.split(separator: " ")
            if let firstChar = parts.first?.first, let lastChar = parts.last?.first, parts.count >= 2 {
                return "\(firstChar)\(lastChar)".uppercased()
            } else if let firstChar = parts.first?.first {
                return String(firstChar).uppercased()
            }
        }
        
        // Fallback al nome utente
        guard !vm.userName.isEmpty else { return "?" }
        
        let parts = vm.userName.split(separator: " ")
        
        if let firstChar = parts.first?.first, let lastChar = parts.last?.first, parts.count >= 2 {
            return "\(firstChar)\(lastChar)".uppercased()
        } else if let firstChar = parts.first?.first {
            return String(firstChar).uppercased()
        }
        
        return "?"
    }
    
    // ⭐⭐⭐ NUOVO: Nome visualizzato (Apple prima, poi utente)
    var displayName: String {
        if !appleName.isEmpty {
            return appleName
        } else if !vm.userName.isEmpty {
            return vm.userName
        } else {
            return "Utente Apple"
        }
    }
    
    // ⭐⭐⭐ NUOVO: Email mascherata Apple
    var displayEmail: String {
        if !appleEmail.isEmpty {
            if appleEmail.contains("privaterelay.appleid.com") {
                // Email mascherata Apple
                let components = appleEmail.split(separator: "@")
                if let localPart = components.first, localPart.count > 4 {
                    let masked = "\(localPart.prefix(2))•••\(localPart.suffix(2))"
                    return "\(masked)@icloud.com"
                }
            }
            return appleEmail
        }
        return "email-privata@apple.com"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // ⭐⭐⭐ MODIFICATO: Controllo se utente è loggato con Apple
            if vm.isSignedInWithApple {
                // Utente autenticato
                authenticatedProfileView
            } else {
                // Utente non autenticato
                notAuthenticatedView
            }
        }
        .alert("Reset Account", isPresented: $showResetAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Reset", role: .destructive) {
                vm.resetAccount()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } message: {
            Text("Vuoi davvero resettare il tuo account? Perderai tutte le scommesse piazzate e il saldo tornerà a €1000.")
        }
        .alert("SportPredix Info", isPresented: $showAppInfoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Versione 2.0\nSign in with Apple Esclusivo\n© 2026 SportPredix")
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
        }
        .onAppear {
            loadAppleUserData()
            tempUserName = vm.userName
        }
    }
    
    // ⭐⭐⭐ NUOVO: Vista per utente NON autenticato
    private var notAuthenticatedView: some View {
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
                Text("Accesso Apple Richiesto")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Devi accedere con Apple ID per accedere al profilo.\nTorna alla schermata principale per autenticarti.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            // Informazioni sicurezza Apple
            VStack(alignment: .leading, spacing: 16) {
                securityInfoRow(
                    icon: "lock.shield.fill",
                    title: "Sicurezza Apple",
                    description: "Face ID / Touch ID integrati"
                )
                
                securityInfoRow(
                    icon: "envelope.badge.fill",
                    title: "Privacy",
                    description: "La tua email non viene condivisa"
                )
                
                securityInfoRow(
                    icon: "person.badge.key.fill",
                    title: "Accesso Unico",
                    description: "Solo account Apple autorizzati"
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // ⭐⭐⭐ MODIFICATO: Vista profilo autenticato
    private var authenticatedProfileView: some View {
        ScrollView {
            VStack(spacing: 28) {
                
                // MARK: - HEADER CARD MIGLIORATA
                headerCard
                
                // ⭐⭐⭐ NUOVO: CARD INFO ACCOUNT APPLE
                appleAccountCard
                
                // MARK: - QUICK SETTINGS (FUNZIONANTI)
                quickSettings
                
                // MARK: - USER STATS
                userStats
                
                // MARK: - ACCOUNT ACTIONS
                accountActions
                
                // ⭐⭐⭐ NUOVO: BOTTONE DISCONNESSIONE
                signOutButton
                
                Spacer()
                    .frame(height: 30)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - HEADER CARD MIGLIORATA con badge Apple
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Avatar con badge Apple
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentCyan.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Text(initials)
                        .font(.largeTitle.bold())
                        .foregroundColor(.accentCyan)
                }
                
                // Badge Apple
                Circle()
                    .fill(Color.black)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "apple.logo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 5, y: 5)
            }
            .padding(.top, 20)
            
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.accentCyan)
                    
                    Text("Account Apple Verificato")
                        .font(.caption)
                        .foregroundColor(.accentCyan)
                }
            }
            
            Text("Saldo: €\(vm.balance, specifier: "%.2f")")
                .font(.title3.bold())
                .foregroundColor(.accentCyan)
                .padding(.top, 4)
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    showNameField.toggle()
                    tempUserName = vm.userName
                }
            } label: {
                Text(showNameField ? "Chiudi" : "Modifica nome visualizzato")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            
            if showNameField {
                nameFieldView
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentCyan.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // ⭐⭐⭐ NUOVO: Card info account Apple
    private var appleAccountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "apple.logo")
                    .foregroundColor(.accentCyan)
                    .frame(width: 24)
                
                Text("Account Apple Collegato")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email Apple")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(displayEmail)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                .padding(.vertical, 8)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                HStack {
                    Image(systemName: "person.badge.key.fill")
                        .foregroundColor(.gray)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ID Utente Apple")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if !appleUserID.isEmpty {
                            Text("••••\(String(appleUserID.suffix(6)))")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("ID sicuro Apple")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var nameFieldView: some View {
        VStack(spacing: 12) {
            TextField("Inserisci nome visualizzato", text: $tempUserName)
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Button("Salva Nome") {
                vm.userName = tempUserName
                showNameField = false
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentCyan)
            .foregroundColor(.black)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Impostazioni rapide")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                toggleRow(
                    icon: "bell",
                    title: "Notifiche",
                    isOn: $vm.notificationsEnabled
                )
                
                toggleRow(
                    icon: "lock",
                    title: "Privacy",
                    isOn: $vm.privacyEnabled
                )
                
                Button {
                    showPreferences = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                            .foregroundColor(.accentCyan)
                            .frame(width: 28)
                        
                        Text("Preferenze app")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    private var userStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiche utente")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                statRow(title: "Scommesse piazzate", value: "\(vm.totalBetsCount)")
                statRow(title: "Vinte", value: "\(vm.totalWins)")
                statRow(title: "Perse", value: "\(vm.totalLosses)")
                
                if vm.totalBetsCount > 0 {
                    let winRate = Double(vm.totalWins) / Double(vm.totalBetsCount) * 100
                    let formattedWinRate = String(format: "%.1f%%", winRate)
                    statRow(title: "Percentuale vittorie", value: formattedWinRate)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    private var accountActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Azioni account")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                actionButton(
                    icon: "arrow.counterclockwise",
                    title: "Reset account",
                    color: .red,
                    action: { showResetAlert = true }
                )
                
                actionButton(
                    icon: "plus.circle",
                    title: "Deposita €100",
                    color: .green,
                    action: depositFunds
                )
                
                actionButton(
                    icon: "person.crop.circle.badge.gear",
                    title: "Gestisci account Apple",
                    color: .accentCyan,
                    action: manageAppleAccount,
                    showsChevron: true
                )
                
                actionButton(
                    icon: "info.circle",
                    title: "Info app",
                    color: .accentCyan,
                    action: { showAppInfoAlert = true },
                    showsChevron: true
                )
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    // ⭐⭐⭐ NUOVO: Bottone per disconnettersi
    private var signOutButton: some View {
        Button(action: signOut) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18))
                
                Text("Esci dall'account Apple")
                    .font(.headline)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - FUNZIONI PROFILO
    
    // ⭐⭐⭐ NUOVO: Carica dati Apple
    private func loadAppleUserData() {
        appleUserID = UserDefaults.standard.string(forKey: "appleUserID") ?? ""
        
        // Qui normalmente recupereresti i dati dal Keychain
        // Per ora usiamo dati di esempio
        if !appleUserID.isEmpty {
            appleEmail = "utente.apple@icloud.com"
            appleName = "Utente Apple"
        }
    }
    
    // ⭐⭐⭐ NUOVO: Gestisci account Apple
    private func manageAppleAccount() {
        if let url = URL(string: "App-Prefs:APPLE_ID_SETTINGS") {
            UIApplication.shared.open(url)
        }
    }
    
    // ⭐⭐⭐ NUOVO: Disconnetti account Apple
    private func signOut() {
        // Rimuove l'ID Apple salvato
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        
        // Resetta i dati Apple locali
        appleUserID = ""
        appleEmail = ""
        appleName = ""
        
        // Forza il refresh della vista principale
        NotificationCenter.default.post(
            name: NSNotification.Name("AppleSignOutCompleted"),
            object: nil
        )
    }
    
    private func depositFunds() {
        vm.balance += 100
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - FUNZIONI HELPER
    
    private func securityInfoRow(icon: String, title: String, description: String) -> some View {
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
    
    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentCyan)
                .frame(width: 28)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .accentCyan))
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { _, newValue in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
        }
        .padding(.vertical, 6)
    }
    
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.accentCyan)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    private func actionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void,
        showsChevron: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 28)
                
                Text(title)
                    .foregroundColor(color)
                
                Spacer()
                
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 10)
        }
    }
}