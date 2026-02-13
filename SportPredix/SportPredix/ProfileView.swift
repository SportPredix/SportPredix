import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var vm: BettingViewModel
    @State private var showLogoutAlert = false
    @State private var showRedeemPopup = false
    @State private var promoCodeInput = ""
    @State private var promoFeedback: String?
    @State private var promoFeedbackColor: Color = .gray
    @State private var redeemedCodeLabel = ""
    @State private var redeemedBonusLabel = ""
    
    var body: some View {
        ZStack {
            background
            
            ScrollView {
                VStack(spacing: 20) {
                    header
                    userCard
                    statsRow
                    accountCard
                    settingsCard
                    redeemCodeCard
                    logoutButton
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            
            if showRedeemPopup {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                
                redeemPopup
                    .padding(.horizontal, 28)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .alert("Conferma Logout", isPresented: $showLogoutAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Esci", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Sei sicuro di voler uscire?")
        }
        .animation(.easeInOut(duration: 0.2), value: showRedeemPopup)
    }
    
    private var background: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.06, green: 0.07, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentCyan.opacity(0.25),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Il tuo profilo")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("Gestisci account e preferenze")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var userCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentCyan,
                                Color.blue.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                    .shadow(color: Color.accentCyan.opacity(0.35), radius: 12, x: 0, y: 6)
                
                Text(String(authManager.currentUserName?.prefix(1) ?? "U").uppercased())
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Text(authManager.currentUserName ?? "Utente")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(authManager.currentUserEmail ?? "Email non disponibile")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(glassCard(cornerRadius: 18))
    }
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Puntate", value: "\(vm.totalBetsCount)", color: .accentCyan)
            statCard(title: "Vinte", value: "\(vm.totalWins)", color: .green)
            statCard(title: "Perse", value: "\(vm.totalLosses)", color: .red)
        }
    }
    
    private var accountCard: some View {
        sectionCard(title: "Account") {
            accountRow(
                icon: "envelope.fill",
                label: "Email",
                value: authManager.currentUserEmail ?? "N/A"
            )
            
            Divider().background(Color.white.opacity(0.08))
            
            accountRow(
                icon: "person.crop.square.fill",
                label: "ID Utente",
                value: authManager.currentUserID?.prefix(8).uppercased() ?? "N/A",
                valueColor: .accentCyan
            )
        }
    }
    
    private var settingsCard: some View {
        sectionCard(title: "Impostazioni") {
            Toggle(isOn: $vm.notificationsEnabled) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.accentCyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifiche")
                            .foregroundColor(.white)
                            .font(.subheadline.bold())
                        Text("Aggiornamenti su quote e risultati")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentCyan))
            
            Divider().background(Color.white.opacity(0.08))
            
            Toggle(isOn: $vm.privacyEnabled) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.accentCyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy")
                            .foregroundColor(.white)
                            .font(.subheadline.bold())
                        Text("Riduci la visibilita dei dati")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentCyan))
        }
    }

    private var redeemCodeCard: some View {
        sectionCard(title: "Riscatta Codice") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Inserisci la parola corretta per sbloccare il bonus.")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("Inserisci qui", text: $promoCodeInput)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )

                Button(action: redeemCode) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Riscatta")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentCyan)
                    )
                }
                .disabled(promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)

                if let promoFeedback {
                    Text(promoFeedback)
                        .font(.caption)
                        .foregroundColor(promoFeedbackColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack(spacing: 10) {
                Image(systemName: "door.left.hand.open")
                Text("Esci")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red.opacity(0.9),
                        Color.red.opacity(0.7)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.red.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .padding(.top, 6)
    }
    
    private var footer: some View {
        VStack(spacing: 6) {
            Text("SportPredix v1.0")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Copyright 2026 SportPredix. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var redeemPopup: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 46))
                .foregroundColor(.green)
            
            Text("Codice Riscattato")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("Codice: \(redeemedCodeLabel)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Importo accreditato: \(redeemedBonusLabel)")
                .font(.headline)
                .foregroundColor(.accentCyan)
            
            Button {
                showRedeemPopup = false
            } label: {
                Text("OK")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentCyan)
                    )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func redeemCode() {
        promoFeedback = "Controllo codice in corso..."
        promoFeedbackColor = .gray

        vm.redeemPromoCode(promoCodeInput) { result in
            switch result {
            case .emptyCode:
                promoFeedback = "Inserisci un codice prima di riscattare."
                promoFeedbackColor = .orange
            case .authRequired:
                promoFeedback = "Devi essere autenticato per riscattare un codice."
                promoFeedbackColor = .red
            case .invalidCode:
                promoFeedback = "Codice non valido."
                promoFeedbackColor = .red
            case .limitReached(let maxUses):
                promoFeedback = "Codice esaurito: limite massimo \(maxUses) utilizzi raggiunto."
                promoFeedbackColor = .orange
            case .alreadyRedeemed:
                promoFeedback = "Hai gia usato questo codice."
                promoFeedbackColor = .orange
            case .storeUnavailable:
                promoFeedback = "Archivio codici non disponibile o errore Firebase."
                promoFeedbackColor = .red
            case .success(let promoCode):
                let bonusText = promoCode.bonus.formatted(
                    .currency(code: "EUR").locale(Locale(identifier: "it_IT"))
                )
                promoFeedback = "Codice accettato: bonus \(bonusText)."
                promoFeedbackColor = .green
                redeemedCodeLabel = promoCode.normalizedCode
                redeemedBonusLabel = bonusText
                showRedeemPopup = true
                promoCodeInput = ""
            }
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(glassCard(cornerRadius: 14))
    }
    
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
        .padding(16)
        .background(glassCard(cornerRadius: 16))
    }
    
    private func accountRow(icon: String, label: String, value: String, valueColor: Color = .white) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
    }
    
    private func glassCard(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
            )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .environmentObject(BettingViewModel())
}
