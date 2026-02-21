import SwiftUI
import PhotosUI
import UIKit

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

    @State private var editableUserName = ""
    @State private var userNameFeedback: String?
    @State private var userNameFeedbackColor: Color = .gray
    @State private var isSavingUserName = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoFeedback: String?
    @State private var photoFeedbackColor: Color = .gray
    @State private var isSavingPhoto = false

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 20) {
                    userCard
                    statsRow
                    friendsCard
                    logoutButton
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 130)
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

    private var userCard: some View {
        VStack(spacing: 14) {
            if let profileImage = profileUIImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentCyan.opacity(0.7), lineWidth: 2)
                    )
                    .shadow(color: Color.accentCyan.opacity(0.35), radius: 12, x: 0, y: 6)
            } else {
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

    private var profileEditorCard: some View {
        sectionCard(title: "Profilo") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Nome utente", text: $editableUserName)
                    .textInputAutocapitalization(.words)
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
                    .foregroundColor(.white)

                Button(action: saveUserName) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                        Text("Salva nome utente")
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
                .disabled(!canSaveUserName || isSavingUserName)
                .opacity((!canSaveUserName || isSavingUserName) ? 0.5 : 1.0)

                if let userNameFeedback {
                    Text(userNameFeedback)
                        .font(.caption)
                        .foregroundColor(userNameFeedbackColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Puntate", value: "\(vm.totalBetsCount)", color: .accentCyan)
            statCard(title: "Vinte", value: "\(vm.totalWins)", color: .green)
            statCard(title: "Perse", value: "\(vm.totalLosses)", color: .red)
        }
    }

    private var friendsCard: some View {
        sectionCard(title: "Amici") {
            VStack(spacing: 12) {
                NavigationLink {
                    ProfileFriendsCenterView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.accentCyan)

                        Text("Apri sezione amici")
                            .foregroundColor(.white)
                            .font(.subheadline.bold())

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.08))

                accountRow(
                    icon: "number.square.fill",
                    label: "Codice Amico",
                    value: authManager.currentUserAccountCode,
                    valueColor: .accentCyan
                )
            }
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

    private var canSaveUserName: Bool {
        let trimmedInput = editableUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = (authManager.currentUserName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedInput.isEmpty && trimmedInput != currentName
    }

    private var profileUIImage: UIImage? {
        guard let data = authManager.currentUserProfileImageData else { return nil }
        return UIImage(data: data)
    }

    private func saveUserName() {
        let trimmedName = editableUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            userNameFeedback = "Inserisci un nome utente valido."
            userNameFeedbackColor = .orange
            return
        }

        isSavingUserName = true
        userNameFeedback = "Salvataggio nome utente in corso..."
        userNameFeedbackColor = .gray

        authManager.updateUserName(trimmedName) { success in
            isSavingUserName = false

            if success {
                editableUserName = authManager.currentUserName ?? trimmedName
                userNameFeedback = "Nome utente aggiornato."
                userNameFeedbackColor = .green
            } else {
                userNameFeedback = authManager.errorMessage ?? "Errore durante il salvataggio del nome utente."
                userNameFeedbackColor = .red
            }
        }
    }

    @MainActor
    private func handlePhotoSelection(item: PhotosPickerItem) async {
        isSavingPhoto = true
        photoFeedback = "Caricamento foto in corso..."
        photoFeedbackColor = .gray

        do {
            guard let selectedData = try await item.loadTransferable(type: Data.self) else {
                photoFeedback = "Impossibile leggere la foto selezionata."
                photoFeedbackColor = .red
                isSavingPhoto = false
                selectedPhotoItem = nil
                return
            }

            authManager.updateProfileImage(selectedData) { success in
                isSavingPhoto = false
                selectedPhotoItem = nil

                if success {
                    photoFeedback = "Foto profilo aggiornata."
                    photoFeedbackColor = .green
                } else {
                    photoFeedback = authManager.errorMessage ?? "Errore durante il salvataggio della foto."
                    photoFeedbackColor = .red
                }
            }
        } catch {
            photoFeedback = "Errore durante la selezione della foto."
            photoFeedbackColor = .red
            isSavingPhoto = false
            selectedPhotoItem = nil
        }
    }

    private func removeProfilePhoto() {
        guard profileUIImage != nil else { return }

        isSavingPhoto = true
        photoFeedback = "Rimozione foto in corso..."
        photoFeedbackColor = .gray

        authManager.removeProfileImage { success in
            isSavingPhoto = false
            selectedPhotoItem = nil

            if success {
                photoFeedback = "Foto profilo eliminata."
                photoFeedbackColor = .green
            } else {
                photoFeedback = authManager.errorMessage ?? "Errore durante la rimozione della foto."
                photoFeedbackColor = .red
            }
        }
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

struct ProfileSettingsRootView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ProfileSettingsView()
                .navigationTitle("Impostazioni")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Chiudi") {
                            dismiss()
                        }
                        .foregroundColor(.accentCyan)
                    }
                }
        }
    }
}

struct ProfileSettingsView: View {
    @EnvironmentObject var vm: BettingViewModel

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Notifiche") {
                        Toggle(isOn: $vm.notificationsEnabled) {
                            settingsRow(
                                icon: "bell.fill",
                                title: "Notifiche"
                            )
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .accentCyan))
                    }

                    sectionCard(title: "Profilo") {
                        NavigationLink {
                            ProfilePersonalInfoView()
                        } label: {
                            settingsRow(
                                icon: "person.crop.circle.badge.pencil",
                                title: "Modifica informazioni personali",
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    sectionCard(title: "Riscatta Codici") {
                        NavigationLink {
                            ProfileRedeemCodesView()
                        } label: {
                            settingsRow(
                                icon: "checkmark.seal.fill",
                                title: "Riscatta Codici",
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    sectionCard(title: "Temi") {
                        NavigationLink {
                            ProfileThemesView()
                        } label: {
                            settingsRow(
                                icon: "paintpalette.fill",
                                title: "Temi",
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsBackground: some View {
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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func settingsRow(icon: String, title: String, showsChevron: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentCyan)

            Text(title)
                .foregroundColor(.white)
                .font(.subheadline.bold())

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
        }
    }
}

private enum FriendCenterTab: String, CaseIterable, Identifiable {
    case friends = "Amici"
    case received = "Ricevuti"
    case sent = "Inviate"

    var id: String { rawValue }
}

struct ProfileFriendsCenterView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedTab: FriendCenterTab = .friends
    @State private var friendCodeInput = ""
    @State private var feedbackMessage: String?
    @State private var feedbackColor: Color = .gray
    @State private var friends: [FriendUserSummary] = []
    @State private var received: [FriendUserSummary] = []
    @State private var sent: [FriendUserSummary] = []
    @State private var isLoading = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Codice Amico") {
                        HStack {
                            Label("Il tuo codice", systemImage: "number.square.fill")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(authManager.currentUserAccountCode)
                                .foregroundColor(.accentCyan)
                                .font(.subheadline.bold())
                        }
                    }

                    sectionCard(title: "Invia Richiesta") {
                        TextField("Codice amico", text: $friendCodeInput)
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
                            .foregroundColor(.white)
                            .onChange(of: friendCodeInput) { _, newValue in
                                let cleaned = newValue
                                    .uppercased()
                                    .filter { $0.isLetter || $0.isNumber }
                                if cleaned.count > 8 {
                                    friendCodeInput = String(cleaned.prefix(8))
                                } else if cleaned != newValue {
                                    friendCodeInput = cleaned
                                }
                            }

                        Button(action: sendRequest) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                Text("Invia richiesta")
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
                        .disabled(friendCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        .opacity(friendCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? 0.5 : 1.0)

                        if let feedbackMessage {
                            Text(feedbackMessage)
                                .font(.caption)
                                .foregroundColor(feedbackColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    sectionCard(title: "Richieste") {
                        Picker("Sezione amici", selection: $selectedTab) {
                            ForEach(FriendCenterTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    tabContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Amici")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSnapshot)
    }

    @ViewBuilder
    private var tabContent: some View {
        if isLoading {
            sectionCard(title: selectedTab.rawValue) {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.accentCyan)
                    Text("Caricamento in corso...")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
        } else {
            switch selectedTab {
            case .friends:
                sectionCard(title: "Amici") {
                    if friends.isEmpty {
                        emptyState("Non hai ancora amici.")
                    } else {
                        ForEach(friends) { friend in
                            friendRow(friend)
                        }
                    }
                }
            case .received:
                sectionCard(title: "Ricevuti") {
                    if received.isEmpty {
                        emptyState("Non hai richieste ricevute.")
                    } else {
                        ForEach(received) { friend in
                            requestReceivedRow(friend)
                        }
                    }
                }
            case .sent:
                sectionCard(title: "Inviate") {
                    if sent.isEmpty {
                        emptyState("Non hai richieste inviate.")
                    } else {
                        ForEach(sent) { friend in
                            requestSentRow(friend)
                        }
                    }
                }
            }
        }
    }

    private func friendRow(_ friend: FriendUserSummary) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.accentCyan)
                Text(friend.name)
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
                Spacer()
                Text(friend.accountCode)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Divider().background(Color.white.opacity(0.08))
        }
    }

    private func requestReceivedRow(_ friend: FriendUserSummary) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .foregroundColor(.accentCyan)
                Text(friend.name)
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
                Spacer()
                Text(friend.accountCode)
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            HStack(spacing: 10) {
                Button {
                    accept(friend)
                } label: {
                    Text("Accetta")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentCyan)
                        )
                }
                .disabled(isSubmitting)
                .opacity(isSubmitting ? 0.6 : 1)

                Button {
                    decline(friend)
                } label: {
                    Text("Rifiuta")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.red.opacity(0.85))
                        )
                }
                .disabled(isSubmitting)
                .opacity(isSubmitting ? 0.6 : 1)
            }

            Divider().background(Color.white.opacity(0.08))
        }
    }

    private func requestSentRow(_ friend: FriendUserSummary) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "tray.and.arrow.up.fill")
                    .foregroundColor(.accentCyan)
                Text(friend.name)
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
                Spacer()
                Text(friend.accountCode)
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            Button {
                cancel(friend)
            } label: {
                Text("Annulla richiesta")
                    .foregroundColor(.white)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.85))
                    )
            }
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.6 : 1)

            Divider().background(Color.white.opacity(0.08))
        }
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.gray)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsBackground: some View {
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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func loadSnapshot() {
        isLoading = true
        authManager.loadFriendCenterSnapshot { result in
            isLoading = false

            switch result {
            case .success(let snapshot):
                friends = snapshot.friends
                received = snapshot.received
                sent = snapshot.sent
            case .failure(let error):
                feedbackMessage = error.localizedDescription
                feedbackColor = .red
            }
        }
    }

    private func sendRequest() {
        let normalizedCode = friendCodeInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalizedCode.isEmpty else {
            feedbackMessage = "Inserisci un codice amico."
            feedbackColor = .orange
            return
        }

        isSubmitting = true
        feedbackMessage = "Invio richiesta in corso..."
        feedbackColor = .gray

        authManager.sendFriendRequest(byAccountCode: normalizedCode) { result in
            isSubmitting = false

            switch result {
            case .success(let name):
                feedbackMessage = "Richiesta inviata a \(name)."
                feedbackColor = .green
                friendCodeInput = ""
                selectedTab = .sent
                loadSnapshot()
            case .failure(let error):
                feedbackMessage = error.localizedDescription
                feedbackColor = .red
            }
        }
    }

    private func accept(_ friend: FriendUserSummary) {
        isSubmitting = true
        feedbackMessage = "Accettazione richiesta in corso..."
        feedbackColor = .gray

        authManager.acceptFriendRequest(from: friend.id) { result in
            isSubmitting = false

            switch result {
            case .success(let name):
                feedbackMessage = "\(name) aggiunto ai tuoi amici."
                feedbackColor = .green
                selectedTab = .friends
                loadSnapshot()
            case .failure(let error):
                feedbackMessage = error.localizedDescription
                feedbackColor = .red
            }
        }
    }

    private func decline(_ friend: FriendUserSummary) {
        isSubmitting = true
        feedbackMessage = "Rifiuto richiesta in corso..."
        feedbackColor = .gray

        authManager.declineFriendRequest(from: friend.id) { result in
            isSubmitting = false

            switch result {
            case .success:
                feedbackMessage = "Richiesta rifiutata."
                feedbackColor = .green
                loadSnapshot()
            case .failure(let error):
                feedbackMessage = error.localizedDescription
                feedbackColor = .red
            }
        }
    }

    private func cancel(_ friend: FriendUserSummary) {
        isSubmitting = true
        feedbackMessage = "Annullamento richiesta in corso..."
        feedbackColor = .gray

        authManager.cancelSentFriendRequest(to: friend.id) { result in
            isSubmitting = false

            switch result {
            case .success:
                feedbackMessage = "Richiesta annullata."
                feedbackColor = .green
                loadSnapshot()
            case .failure(let error):
                feedbackMessage = error.localizedDescription
                feedbackColor = .red
            }
        }
    }
}

struct ProfilePersonalInfoView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var editableUserName = ""
    @State private var userNameFeedback: String?
    @State private var userNameFeedbackColor: Color = .gray
    @State private var isSavingUserName = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoFeedback: String?
    @State private var photoFeedbackColor: Color = .gray
    @State private var isSavingPhoto = false

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Foto Profilo") {
                        VStack(spacing: 12) {
                            avatarView

                            HStack(spacing: 10) {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo")
                                        Text(profileUIImage == nil ? "Aggiungi foto" : "Cambia foto")
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
                                .disabled(isSavingPhoto)
                                .opacity(isSavingPhoto ? 0.6 : 1)
                                .frame(maxWidth: .infinity)

                                Button(action: removeProfilePhoto) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                        Text("Elimina")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.red.opacity(0.85))
                                    )
                                }
                                .disabled(isSavingPhoto || profileUIImage == nil)
                                .opacity((isSavingPhoto || profileUIImage == nil) ? 0.5 : 1)
                                .frame(maxWidth: .infinity)
                            }

                            if let photoFeedback {
                                Text(photoFeedback)
                                    .font(.caption)
                                    .foregroundColor(photoFeedbackColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    sectionCard(title: "Nome Utente") {
                        TextField("Nome utente", text: $editableUserName)
                            .textInputAutocapitalization(.words)
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
                            .foregroundColor(.white)

                        Button(action: saveUserName) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.pencil")
                                Text("Salva nome utente")
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
                        .disabled(!canSaveUserName || isSavingUserName)
                        .opacity((!canSaveUserName || isSavingUserName) ? 0.5 : 1.0)

                        if let userNameFeedback {
                            Text(userNameFeedback)
                                .font(.caption)
                                .foregroundColor(userNameFeedbackColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Informazioni Personali")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await handlePhotoSelection(item: newItem)
            }
        }
    }

    private var settingsBackground: some View {
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

    private var avatarView: some View {
        Group {
            if let profileImage = profileUIImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentCyan.opacity(0.7), lineWidth: 2)
                    )
                    .shadow(color: Color.accentCyan.opacity(0.35), radius: 12, x: 0, y: 6)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentCyan, Color.blue.opacity(0.7)]),
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
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var canSaveUserName: Bool {
        let trimmedInput = editableUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = (authManager.currentUserName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedInput.isEmpty && trimmedInput != currentName
    }

    private var profileUIImage: UIImage? {
        guard let data = authManager.currentUserProfileImageData else { return nil }
        return UIImage(data: data)
    }

    private func saveUserName() {
        let trimmedName = editableUserName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            userNameFeedback = "Inserisci un nome utente valido."
            userNameFeedbackColor = .orange
            return
        }

        isSavingUserName = true
        userNameFeedback = "Salvataggio nome utente in corso..."
        userNameFeedbackColor = .gray

        authManager.updateUserName(trimmedName) { success in
            isSavingUserName = false

            if success {
                editableUserName = authManager.currentUserName ?? trimmedName
                userNameFeedback = "Nome utente aggiornato."
                userNameFeedbackColor = .green
            } else {
                userNameFeedback = authManager.errorMessage ?? "Errore durante il salvataggio del nome utente."
                userNameFeedbackColor = .red
            }
        }
    }

    @MainActor
    private func handlePhotoSelection(item: PhotosPickerItem) async {
        isSavingPhoto = true
        photoFeedback = "Caricamento foto in corso..."
        photoFeedbackColor = .gray

        do {
            guard let selectedData = try await item.loadTransferable(type: Data.self) else {
                photoFeedback = "Impossibile leggere la foto selezionata."
                photoFeedbackColor = .red
                isSavingPhoto = false
                selectedPhotoItem = nil
                return
            }

            authManager.updateProfileImage(selectedData) { success in
                isSavingPhoto = false
                selectedPhotoItem = nil

                if success {
                    photoFeedback = "Foto profilo aggiornata."
                    photoFeedbackColor = .green
                } else {
                    photoFeedback = authManager.errorMessage ?? "Errore durante il salvataggio della foto."
                    photoFeedbackColor = .red
                }
            }
        } catch {
            photoFeedback = "Errore durante la selezione della foto."
            photoFeedbackColor = .red
            isSavingPhoto = false
            selectedPhotoItem = nil
        }
    }

    private func removeProfilePhoto() {
        guard profileUIImage != nil else { return }

        isSavingPhoto = true
        photoFeedback = "Rimozione foto in corso..."
        photoFeedbackColor = .gray

        authManager.removeProfileImage { success in
            isSavingPhoto = false
            selectedPhotoItem = nil

            if success {
                photoFeedback = "Foto profilo eliminata."
                photoFeedbackColor = .green
            } else {
                photoFeedback = authManager.errorMessage ?? "Errore durante la rimozione della foto."
                photoFeedbackColor = .red
            }
        }
    }
}

struct ProfileRedeemCodesView: View {
    @EnvironmentObject var vm: BettingViewModel

    @State private var promoCodeInput = ""
    @State private var promoFeedback: String?
    @State private var promoFeedbackColor: Color = .gray
    @State private var showRedeemPopup = false
    @State private var redeemedCodeLabel = ""
    @State private var redeemedBonusLabel = ""

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Riscatta Codici") {
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
                            .foregroundColor(.white)

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
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }

            if showRedeemPopup {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                redeemPopup
                    .padding(.horizontal, 28)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("Riscatta Codici")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: showRedeemPopup)
    }

    private var settingsBackground: some View {
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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
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
}

struct ProfileThemesView: View {
    @AppStorage("profileSelectedTheme") private var selectedTheme = "Sistema"
    private let themes = ["Sistema", "Chiaro", "Scuro"]

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Temi") {
                        Text("Scegli il tema da usare nell'app.")
                            .font(.caption)
                            .foregroundColor(.gray)

                        ForEach(themes, id: \.self) { theme in
                            Button {
                                selectedTheme = theme
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundColor(.accentCyan)

                                    Text(theme)
                                        .foregroundColor(.white)
                                        .font(.subheadline.bold())

                                    Spacer()

                                    Image(systemName: selectedTheme == theme ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedTheme == theme ? .accentCyan : .gray)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Temi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsBackground: some View {
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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .environmentObject(BettingViewModel())
}
