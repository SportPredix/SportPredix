import SwiftUI
import PhotosUI
import UIKit
import ImageIO

private struct AppToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.accentCyan)

            Text(message)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

private struct RemoteGIFImageView: UIViewRepresentable {
    let url: URL
    var contentMode: UIView.ContentMode = .scaleAspectFit

    final class GIFContainerView: UIView {
        let imageView = UIImageView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            clipsToBounds = true

            imageView.frame = bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.backgroundColor = .clear
            imageView.clipsToBounds = true
            addSubview(imageView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    func makeUIView(context: Context) -> GIFContainerView {
        let view = GIFContainerView()
        view.imageView.contentMode = contentMode
        context.coordinator.load(url: url, into: view.imageView)
        return view
    }

    func updateUIView(_ uiView: GIFContainerView, context: Context) {
        uiView.imageView.contentMode = contentMode
        uiView.imageView.clipsToBounds = true
        uiView.clipsToBounds = true
        context.coordinator.load(url: url, into: uiView.imageView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private static let cache = NSCache<NSURL, UIImage>()
        private var currentURL: URL?
        private var task: URLSessionDataTask?

        deinit {
            task?.cancel()
        }

        func load(url: URL, into imageView: UIImageView) {
            if currentURL == url, imageView.image != nil {
                return
            }
            currentURL = url

            if let cached = Self.cache.object(forKey: url as NSURL) {
                DispatchQueue.main.async {
                    imageView.image = cached
                    imageView.startAnimating()
                }
                return
            }

            task?.cancel()
            task = URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let animatedImage = Self.makeAnimatedImage(from: data) else {
                    return
                }

                Self.cache.setObject(animatedImage, forKey: url as NSURL)

                DispatchQueue.main.async {
                    guard self.currentURL == url else { return }
                    imageView.image = animatedImage
                    imageView.startAnimating()
                }
            }
            task?.resume()
        }

        private static func makeAnimatedImage(from data: Data) -> UIImage? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return nil
            }

            let frameCount = CGImageSourceGetCount(source)
            guard frameCount > 0 else {
                return nil
            }

            var frames: [UIImage] = []
            var totalDuration: Double = 0

            for index in 0..<frameCount {
                guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }

                let duration = frameDuration(source: source, index: index)
                totalDuration += duration
                frames.append(UIImage(cgImage: frame, scale: UIScreen.main.scale, orientation: .up))
            }

            guard !frames.isEmpty else { return nil }
            if totalDuration <= 0 {
                totalDuration = Double(frames.count) * 0.08
            }

            return UIImage.animatedImage(with: frames, duration: totalDuration)
        }

        private static func frameDuration(source: CGImageSource, index: Int) -> Double {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
                  let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
                return 0.08
            }

            let unclamped = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? Double
            let clamped = gifInfo[kCGImagePropertyGIFDelayTime] as? Double
            let value = unclamped ?? clamped ?? 0.08
            return value < 0.02 ? 0.08 : value
        }
    }
}

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
    @State private var showCopyToast = false
    @State private var showSportPassDetail = false
    @State private var copyToastHideWorkItem: DispatchWorkItem?
    private let streakFireGIFURL = URL(string: "https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif")

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 20) {
                    userCard
                    statsRow
                    sportPassCard
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

            if showCopyToast {
                VStack {
                    Spacer()

                    AppToastView(message: "Codice amico copiato")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 108)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopyToast)
        .alert("Conferma Logout", isPresented: $showLogoutAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Esci", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Sei sicuro di voler uscire?")
        }
        .sheet(isPresented: $showSportPassDetail) {
            SportPassDetailView()
                .environmentObject(vm)
        }
        .onAppear {
            authManager.refreshUnreadFriendRequestsStatus()
        }
        .onDisappear {
            copyToastHideWorkItem?.cancel()
            copyToastHideWorkItem = nil
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
            avatarWithStreak

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

    private var avatarWithStreak: some View {
        ZStack(alignment: .bottomTrailing) {
            profileAvatar

            if vm.streakDays > 0 {
                ZStack(alignment: .bottom) {
                    if let streakFireGIFURL {
                        RemoteGIFImageView(url: streakFireGIFURL)
                            .frame(width: 34, height: 34)
                            .offset(y: -4)
                    }

                    Text("\(vm.streakDays)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .frame(minWidth: 24, minHeight: 16)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.86))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.orange.opacity(0.55), lineWidth: 1)
                                )
                        )
                        .offset(y: 5)
                }
                .frame(width: 42, height: 56)
                .offset(x: 6, y: 8)
            }
        }
        .padding(.bottom, vm.streakDays > 0 ? 6 : 0)
    }

    private var profileAvatar: some View {
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
        }
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

    private var sportPassCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SportPass")
                    .font(.headline.weight(.black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.accentCyan, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                HStack(spacing: 8) {
                    Text("NEON")
                        .font(.caption2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.accentCyan)
                        )

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.accentCyan.opacity(0.9))
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Livello \(vm.sportPassCurrentTier)/\(vm.sportPassMaxTier)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if let nextTier = vm.sportPassNextTier {
                        Text("Prossima soglia: Livello \(nextTier.level) - \(nextTier.reward)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Pass completato: tutte le 20 soglie sbloccate.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.accentCyan.opacity(0.95),
                                    Color.blue.opacity(0.7),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 6,
                                endRadius: 36
                            )
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(sportPassPointsText(vm.sportPassPoints)) punti")
                        .font(.caption.bold())
                        .foregroundColor(.accentCyan)

                    Spacer()

                    if let nextTier = vm.sportPassNextTier {
                        Text("Target \(sportPassPointsText(nextTier.requiredPoints))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        Text("Target MAX")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.08))

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentCyan, Color.mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, geometry.size.width * max(0, min(1, vm.sportPassProgressToNextTier))))
                            .animation(.easeInOut(duration: 0.25), value: vm.sportPassProgressToNextTier)
                    }
                }
                .frame(height: 8)
            }

            HStack(spacing: 8) {
                sportPassPill(systemImage: "list.bullet.rectangle.fill", label: "Solo schedine vinte")
                sportPassPill(systemImage: "nosign", label: "No slot e promo")
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.72))

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.accentCyan.opacity(0.95),
                                Color.blue.opacity(0.8),
                                Color.mint.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            }
        )
        .shadow(color: Color.accentCyan.opacity(0.4), radius: 14, x: 0, y: 0)
        .shadow(color: Color.blue.opacity(0.28), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            showSportPassDetail = true
        }
    }
    private var friendsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Amici")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 10) {
                NavigationLink {
                    ProfileFriendsCenterView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.accentCyan)

                        Text("Apri sezione amici")
                            .foregroundColor(.white)
                            .font(.subheadline.bold())

                        if authManager.hasUnreadFriendRequests {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)
                .frame(height: 40)

                HStack(spacing: 8) {
                    Image(systemName: "number.square.fill")
                        .font(.caption.bold())
                        .foregroundColor(.gray)

                    Text("Codice")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Text(authManager.currentUserAccountCode)
                        .font(.caption.bold())
                        .foregroundColor(.accentCyan)
                        .lineLimit(1)

                    Button(action: copyCurrentUserFriendCode) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption.bold())
                            .foregroundColor(.accentCyan)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(glassCard(cornerRadius: 14))
        }
    }

    private func sportPassPill(systemImage: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.bold())
            Text(label)
                .font(.caption2.bold())
                .lineLimit(1)
        }
        .foregroundColor(.accentCyan)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func sportPassPointsText(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        return "\(rounded)"
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
            DispatchQueue.main.async {
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
                    let bonusText = GemFormatting.tagged(promoCode.bonus)
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

    private func accountRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .white,
        showsCopyButton: Bool = false,
        copyAction: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(valueColor)
                    .lineLimit(1)

                if showsCopyButton, let copyAction = copyAction {
                    Button(action: copyAction) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption.bold())
                            .foregroundColor(.accentCyan)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func copyCurrentUserFriendCode() {
        UIPasteboard.general.string = authManager.currentUserAccountCode
        showCopyToastMessage()
    }

    private func showCopyToastMessage() {
        copyToastHideWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopyToast = true
        }

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyToast = false
            }
        }
        copyToastHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
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

private struct SportPassDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vm: BettingViewModel

    var body: some View {
        NavigationStack {
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

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        tiersCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("SportPass")
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

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progressi Pass")
                    .font(.headline.weight(.black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.accentCyan, Color.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                Text("LIV \(vm.sportPassCurrentTier)/\(vm.sportPassMaxTier)")
                    .font(.caption2.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentCyan)
                    )
            }

            HStack {
                Text("\(sportPassPointsText(vm.sportPassPoints)) punti")
                    .font(.subheadline.bold())
                    .foregroundColor(.accentCyan)

                Spacer()

                if let nextTier = vm.sportPassNextTier {
                    Text("Prossimo: L\(nextTier.level)")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("Completato")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentCyan, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, geometry.size.width * max(0, min(1, vm.sportPassProgressToNextTier))))
                        .animation(.easeInOut(duration: 0.25), value: vm.sportPassProgressToNextTier)
                }
            }
            .frame(height: 9)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.accentCyan.opacity(0.95),
                                    Color.blue.opacity(0.8),
                                    Color.mint.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                )
        )
        .shadow(color: Color.accentCyan.opacity(0.35), radius: 12, x: 0, y: 0)
    }

    private var tiersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Soglie e Ricompense")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(vm.sportPassTiers) { tier in
                let isUnlocked = vm.sportPassPoints >= tier.requiredPoints
                HStack(spacing: 10) {
                    Text("L\(tier.level)")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .frame(width: 34, height: 24)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isUnlocked ? Color.accentCyan : Color.gray.opacity(0.3))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.reward)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Richiesti \(sportPassPointsText(tier.requiredPoints)) punti")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: isUnlocked ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isUnlocked ? .accentCyan : .gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isUnlocked ? Color.accentCyan.opacity(0.35) : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func sportPassPointsText(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }
}

struct ProfileSettingsRootView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: BettingViewModel

    var body: some View {
        NavigationStack {
            ProfileSettingsView(vm: vm)
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
    @ObservedObject var vm: BettingViewModel

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    settingsItemCard(icon: "person.crop.circle.fill", title: "Informazioni personali") {
                        ProfilePersonalInfoView()
                    }

                    settingsItemCard(icon: "trophy.fill", title: "Campionati principali") {
                        ProfileMainLeaguesSettingsView(vm: vm)
                    }

                    settingsItemCard(icon: "paintpalette.fill", title: "Temi") {
                        ProfileThemesView()
                    }

                    settingsItemCard(icon: "bell.fill", title: "Notifiche") {
                        ProfileNotificationsView()
                    }

                    settingsItemCard(icon: "checkmark.seal.fill", title: "Riscatta Codici") {
                        ProfileRedeemCodesView(vm: vm)
                    }

                    settingsItemCard(icon: "info.circle.fill", title: "Informazioni") {
                        ProfileInformationView()
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

    private func settingsItemCard<Destination: View>(
        icon: String,
        title: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.accentCyan)

                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline.bold())

                Spacer()
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
        .buttonStyle(.plain)
    }
}

struct ProfileNotificationsView: View {
    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Notifiche") {
                        Text("In arrivo con il prossimo aggiornamento...")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Notifiche")
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

struct ProfileMainLeaguesSettingsView: View {
    @ObservedObject var vm: BettingViewModel
    @State private var searchText = ""

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Campionati principali") {
                        Text("Seleziona i campionati da mostrare come principali nella sezione Sport.")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        searchField

                        VStack(spacing: 10) {
                            ForEach(filteredLeagues, id: \.self) { league in
                                leagueSelectionRow(league)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Campionati principali")
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

    private var filteredLeagues: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return vm.allAvailableMainLeagues }

        return vm.allAvailableMainLeagues.filter { league in
            league.localizedCaseInsensitiveContains(query)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Cerca campionato", text: $searchText)
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func leagueSelectionRow(_ league: String) -> some View {
        let isSelected = vm.isMainLeagueSelected(league)

        return Button {
            vm.toggleMainLeagueSelection(league)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.accentCyan)

                Text(league)
                    .foregroundColor(.white)
                    .font(.subheadline.bold())

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentCyan : .gray)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Color.accentCyan : Color.white.opacity(0.1), lineWidth: isSelected ? 1.2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileInformationView: View {
    private let members = ["enribocco", "cranci", "SuperFico2100"]

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    teamHeader

                    sectionCard(title: "Membri") {
                        VStack(spacing: 10) {
                            ForEach(members, id: \.self) { member in
                                memberRow(member)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Informazioni")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var teamHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentCyan.opacity(0.2))
                        .frame(width: 38, height: 38)

                    Image(systemName: "sparkles")
                        .foregroundColor(.accentCyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Formatiks")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Gruppo creatore di SportPredix")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func memberRow(_ member: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 34, height: 34)

                Image(systemName: "person.fill")
                    .foregroundColor(.accentCyan)
                    .font(.caption.bold())
            }

            Text(member)
                .foregroundColor(.white)
                .font(.subheadline.bold())

            Spacer()

            Text("Sviluppatore")
                .font(.caption2.bold())
                .foregroundColor(.accentCyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.accentCyan.opacity(0.12))
                )
        }
        .padding(.horizontal, 4)
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
    @State private var showRemoveFriendAlert = false
    @State private var pendingFriendRemoval: FriendUserSummary?
    @State private var showCopyToast = false
    @State private var copyToastHideWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Codice Amico") {
                        HStack(spacing: 10) {
                            Label("Il tuo codice", systemImage: "number.square.fill")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(authManager.currentUserAccountCode)
                                .foregroundColor(.accentCyan)
                                .font(.subheadline.bold())

                            Button(action: copyCurrentUserFriendCode) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption.bold())
                                    .foregroundColor(.accentCyan)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
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

                    requestsCenterCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }

            if showCopyToast {
                VStack {
                    Spacer()

                    AppToastView(message: "Codice amico copiato")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopyToast)
        .navigationTitle("Amici")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSnapshot)
        .onChange(of: selectedTab) { _, newTab in
            guard newTab == .received else { return }
            markReceivedRequestsAsSeen()
        }
        .alert("Conferma rimozione", isPresented: $showRemoveFriendAlert) {
            Button("Annulla", role: .cancel) {
                pendingFriendRemoval = nil
            }
            Button("Rimuovi", role: .destructive) {
                guard let friend = pendingFriendRemoval else { return }
                pendingFriendRemoval = nil
                remove(friend)
            }
        } message: {
            if let friend = pendingFriendRemoval {
                Text("Vuoi rimuovere \(friend.name) dai tuoi amici?")
            } else {
                Text("Vuoi rimuovere questo amico?")
            }
        }
        .onDisappear {
            copyToastHideWorkItem?.cancel()
            copyToastHideWorkItem = nil
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if isLoading {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.accentCyan)
                Text("Caricamento in corso...")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            switch selectedTab {
            case .friends:
                if friends.isEmpty {
                    emptyState("Non hai ancora amici.")
                } else {
                    ForEach(friends) { friend in
                        friendRow(friend)
                    }
                }
            case .received:
                if received.isEmpty {
                    emptyState("Non hai richieste ricevute.")
                } else {
                    ForEach(received) { friend in
                        requestReceivedRow(friend)
                    }
                }
            case .sent:
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

    private var requestsTabSelector: some View {
        Picker("Classifica", selection: $selectedTab) {
            ForEach(FriendCenterTab.allCases) { tab in
                if tab == .received && authManager.hasUnreadFriendRequests {
                    Text("\(tab.rawValue) ï¿½").tag(tab)
                } else {
                    Text(tab.rawValue).tag(tab)
                }
            }
        }
        .pickerStyle(.segmented)
    }

    private var requestsCenterCard: some View {
        VStack(spacing: 14) {
            requestsTabSelector

            Divider()
                .background(Color.white.opacity(0.12))

            tabContent
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

    private func friendRow(_ friend: FriendUserSummary) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink {
                    UserPublicProfileView(
                        userID: friend.id,
                        initialName: friend.name,
                        initialAccountCode: friend.accountCode,
                        initialProfileImageData: friend.profileImageData
                    )
                } label: {
                    HStack(spacing: 10) {
                        friendAvatar(for: friend)

                        Text(friend.name)
                            .foregroundColor(.white)
                            .font(.subheadline.bold())

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    pendingFriendRemoval = friend
                    showRemoveFriendAlert = true
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red.opacity(0.9))
                        .font(.subheadline)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .disabled(isSubmitting)
                .opacity(isSubmitting ? 0.6 : 1)
            }
            Divider().background(Color.white.opacity(0.08))
        }
    }

    private func requestReceivedRow(_ friend: FriendUserSummary) -> some View {
        VStack(spacing: 10) {
            NavigationLink {
                UserPublicProfileView(
                    userID: friend.id,
                    initialName: friend.name,
                    initialAccountCode: friend.accountCode,
                    initialProfileImageData: friend.profileImageData
                )
            } label: {
                HStack(spacing: 10) {
                    friendAvatar(for: friend)

                    Text(friend.name)
                        .foregroundColor(.white)
                        .font(.subheadline.bold())

                    Spacer()

                    Text(friend.accountCode)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
            NavigationLink {
                UserPublicProfileView(
                    userID: friend.id,
                    initialName: friend.name,
                    initialAccountCode: friend.accountCode,
                    initialProfileImageData: friend.profileImageData
                )
            } label: {
                HStack(spacing: 10) {
                    friendAvatar(for: friend)

                    Text(friend.name)
                        .foregroundColor(.white)
                        .font(.subheadline.bold())

                    Spacer()

                    Text(friend.accountCode)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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

    private func friendAvatar(for friend: FriendUserSummary, size: CGFloat = 34) -> some View {
        Group {
            if let imageData = friend.profileImageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.accentCyan.opacity(0.25))
                        .frame(width: size, height: size)

                    Text(String(friend.name.prefix(1)).uppercased())
                        .foregroundColor(.accentCyan)
                        .font(.caption.bold())
                }
            }
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
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

    private func copyCurrentUserFriendCode() {
        UIPasteboard.general.string = authManager.currentUserAccountCode
        showCopyToastMessage()
    }

    private func showCopyToastMessage() {
        copyToastHideWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopyToast = true
        }

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopyToast = false
            }
        }
        copyToastHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }

    private func markReceivedRequestsAsSeen() {
        guard !received.isEmpty else { return }
        authManager.markFriendRequestsAsSeen(received.map(\.id))
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
                if selectedTab == .received {
                    markReceivedRequestsAsSeen()
                }
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

    private func remove(_ friend: FriendUserSummary) {
        isSubmitting = true
        feedbackMessage = "Rimozione amico in corso..."
        feedbackColor = .gray

        authManager.removeFriend(userID: friend.id) { result in
            isSubmitting = false

            switch result {
            case .success:
                feedbackMessage = "\(friend.name) rimosso dai tuoi amici."
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
    @ObservedObject var vm: BettingViewModel

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
            DispatchQueue.main.async {
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
                    let bonusText = GemFormatting.tagged(promoCode.bonus)
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
}

struct ProfileThemesView: View {
    @AppStorage("profileSelectedTheme") private var selectedTheme = "Scuro"
    private let themes = ["Scuro"]

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
