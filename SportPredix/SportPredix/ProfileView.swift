//
//  ProfileView.swift
//  SportPredix
//
//  Created by Francesco on 16/01/26.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject var vm: BettingViewModel
    @State private var showNameField = false
    @State private var showResetAlert = false
    @State private var showPreferences = false
    @State private var showAppInfoAlert = false
    @State private var tempUserName: String = ""
    
    var initials: String {
        let parts = vm.userName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts.first!.first!)\(parts.last!.first!)".uppercased()
        } else if let first = vm.userName.first {
            return String(first).uppercased()
        }
        return "?"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    
                    // MARK: - HEADER CARD
                    VStack(spacing: 16) {
                        
                        ZStack {
                            Circle()
                                .fill(Color.accentCyan.opacity(0.25))
                                .frame(width: 90, height: 90)
                            
                            Text(initials)
                                .font(.largeTitle.bold())
                                .foregroundColor(.accentCyan)
                        }
                        .padding(.top, 20)
                        
                        Text(vm.userName.isEmpty ? "Utente" : vm.userName)
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Saldo: €\(vm.balance, specifier: "%.2f")")
                            .font(.title3.bold())
                            .foregroundColor(.accentCyan)
                        
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showNameField.toggle()
                                tempUserName = vm.userName
                            }
                        } label: {
                            Text(showNameField ? "Chiudi" : "Modifica nome")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        
                        if showNameField {
                            VStack(spacing: 12) {
                                TextField("Inserisci nome", text: $tempUserName)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                Button("Salva") {
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
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // MARK: - QUICK SETTINGS (FUNZIONANTI)
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("Impostazioni rapide")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // NOTIFICHE CON TOGGLE
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(.accentCyan)
                                    .frame(width: 28)
                                
                                Text("Notifiche")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $vm.notificationsEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .accentCyan))
                                    .labelsHidden()
                                    .onChange(of: vm.notificationsEnabled) { newValue in
                                        // Feedback tattile
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                            }
                            .padding(.vertical, 6)
                            
                            // PRIVACY CON TOGGLE
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.accentCyan)
                                    .frame(width: 28)
                                
                                Text("Privacy")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $vm.privacyEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .accentCyan))
                                    .labelsHidden()
                                    .onChange(of: vm.privacyEnabled) { newValue in
                                        // Feedback tattile
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                            }
                            .padding(.vertical, 6)
                            
                            // PREFERENZE APP
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
                    
                    // MARK: - USER STATS
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
                                statRow(title: "Percentuale vittorie", value: "\(winRate, specifier: "%.1f")%")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        
                    }
                    .padding(.horizontal)
                    
                    // MARK: - ACCOUNT ACTIONS
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text("Azioni account")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            // RESET ACCOUNT
                            Button {
                                showResetAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.red)
                                        .frame(width: 28)
                                    
                                    Text("Reset account")
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            
                            // DEPOSITA FONDI
                            Button {
                                depositFunds()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.green)
                                        .frame(width: 28)
                                    
                                    Text("Deposita €100")
                                        .foregroundColor(.green)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            
                            // INFO APP
                            Button {
                                showAppInfoAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.accentCyan)
                                        .frame(width: 28)
                                    
                                    Text("Info app")
                                        .foregroundColor(.accentCyan)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.top, 20)
            }
        }
        .alert("Reset Account", isPresented: $showResetAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Reset", role: .destructive) {
                vm.resetAccount()
                // Feedback tattile
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } message: {
            Text("Vuoi davvero resettare il tuo account? Perderai tutte le scommesse piazzate e il saldo tornerà a €1000.")
        }
        .alert("SportPredix Info", isPresented: $showAppInfoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Versione 1.0\nSviluppato per dimostrazione\n© 2024 SportPredix")
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
        }
        .onAppear {
            // Inizializza il nome temporaneo
            tempUserName = vm.userName
        }
    }
    
    // MARK: - FUNZIONI PROFILO
    
    private func depositFunds() {
        vm.balance += 100
        // Mostra un feedback visivo e tattile
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Animazione per il saldo
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // L'animazione è gestita automaticamente dall'@Published property
        }
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
}
