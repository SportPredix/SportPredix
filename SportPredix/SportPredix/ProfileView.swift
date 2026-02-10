//
//  ProfileView.swift
//  SportPredix
//
//  Created by Francesco on 16/01/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var vm: BettingViewModel
    @EnvironmentObject var auth: AuthViewModel
    
    @State private var showResetAlert = false
    @State private var showPreferences = false
    @State private var showAppInfoAlert = false
    
    var initials: String {
        let baseName = !vm.userName.isEmpty ? vm.userName : (auth.userEmail ?? "?")
        let parts = baseName.split(separator: " ")
        if let firstChar = parts.first?.first, let lastChar = parts.last?.first, parts.count >= 2 {
            return "\(firstChar)\(lastChar)".uppercased()
        } else if let firstChar = parts.first?.first {
            return String(firstChar).uppercased()
        }
        return "?"
    }
    
    var displayName: String {
        if !vm.userName.isEmpty { return vm.userName }
        if let email = auth.userEmail, !email.isEmpty { return email }
        return "Utente"
    }
    
    var displayEmail: String {
        auth.userEmail ?? "email non disponibile"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if auth.isSignedIn {
                authenticatedProfileView
            } else {
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
            Text("Vuoi davvero resettare il tuo account? Perderai tutte le scommesse piazzate e il saldo tornera a EUR 1000.")
        }
        .alert("SportPredix Info", isPresented: $showAppInfoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Versione 2.0\nLogin Email/Password\n(c) 2026 SportPredix")
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
        }
    }
    
    private var notAuthenticatedView: some View {
        VStack(spacing: 24) {
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
                
                Image(systemName: "person.badge.key")
                    .font(.system(size: 50))
                    .foregroundColor(.accentCyan)
            }
            
            VStack(spacing: 12) {
                Text("Accesso richiesto")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Devi accedere per vedere il profilo. Torna alla schermata principale per il login.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var authenticatedProfileView: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerCard
                accountCard
                quickSettings
                userStats
                accountActions
                signOutButton
                Spacer().frame(height: 30)
            }
            .padding(.top, 20)
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
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
            .padding(.top, 20)
            
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(displayEmail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text("Saldo: EUR \(vm.balance, specifier: \"%.2f\")")
                .font(.title3.bold())
                .foregroundColor(.accentCyan)
                .padding(.top, 4)
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
    
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.accentCyan)
                    .frame(width: 24)
                Text("Account")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(displayEmail)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var quickSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Impostazioni rapide")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                toggleRow(icon: "bell", title: "Notifiche", isOn: $vm.notificationsEnabled)
                toggleRow(icon: "lock", title: "Privacy", isOn: $vm.privacyEnabled)
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
                actionButton(icon: "arrow.counterclockwise", title: "Reset account", color: .red) {
                    showResetAlert = true
                }
                
                actionButton(icon: "plus.circle", title: "Deposita EUR 100", color: .green) {
                    depositFunds()
                }
                
                actionButton(icon: "info.circle", title: "Info app", color: .accentCyan, showsChevron: true) {
                    showAppInfoAlert = true
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    private var signOutButton: some View {
        Button(action: signOut) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18))
                Text("Esci dall'account")
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
    
    private func depositFunds() {
        vm.balance += 100
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func signOut() {
        auth.signOut()
        vm.setCurrentUserId(nil)
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
                .onChange(of: isOn.wrappedValue) { _, _ in
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
        showsChevron: Bool = false,
        action: @escaping () -> Void
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
