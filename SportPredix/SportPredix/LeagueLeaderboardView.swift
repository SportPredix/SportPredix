import SwiftUI
import FirebaseFirestore
import UIKit
import ImageIO

private struct LeagueEntry: Identifiable {
    let id: String
    let name: String
    let balance: Double
    let profileImageData: Data?
}

private enum LeaderboardScope: String, CaseIterable, Identifiable {
    case global = "Globale"
    case friends = "Amici"

    var id: String { rawValue }

    var emptyTitle: String {
        switch self {
        case .global:
            return "Nessun utente in classifica"
        case .friends:
            return "Nessun amico in classifica"
        }
    }

    var emptySubtitle: String {
        switch self {
        case .global:
            return "La classifica si popola quando ci sono utenti con saldo salvato su Firebase."
        case .friends:
            return "Aggiungi amici dalla pagina profilo per vedere la classifica dedicata."
        }
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

struct LeagueLeaderboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var entries: [LeagueEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedScope: LeaderboardScope = .global

    var body: some View {
        VStack(spacing: 10) {
            scopePicker
            contentView
        }
        .onAppear {
            if entries.isEmpty {
                fetchLeaderboard(for: selectedScope)
            }
        }
        .onChange(of: selectedScope) { _, newScope in
            fetchLeaderboard(for: newScope)
        }
    }

    private var scopePicker: some View {
        Picker("Classifica", selection: $selectedScope) {
            ForEach(LeaderboardScope.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            VStack(spacing: 10) {
                ProgressView()
                    .tint(.accentCyan)
                Text("Caricamento classifica...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.orange)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Button("Riprova") {
                    fetchLeaderboard(for: selectedScope)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentCyan)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if entries.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: selectedScope == .global ? "person.3.fill" : "person.2.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.accentCyan)
                Text(selectedScope.emptyTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(selectedScope.emptySubtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if let rank = currentUserRank, let entry = currentUserEntry {
                        userRankCard(rank: rank, totalUsers: entries.count, balance: entry.balance)
                    } else if authManager.currentUserID != nil {
                        userNotRankedCard
                    }

                    ForEach(entries.indices, id: \.self) { index in
                        let entry = entries[index]
                        NavigationLink {
                            UserPublicProfileView(
                                userID: entry.id,
                                initialName: entry.name,
                                initialProfileImageData: entry.profileImageData,
                                initialBalance: entry.balance
                            )
                        } label: {
                            leagueRow(
                                rank: index + 1,
                                entry: entry,
                                isCurrentUser: entry.id == authManager.currentUserID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
            .refreshable {
                await refreshLeaderboard()
            }
        }
    }

    private var currentUserRank: Int? {
        guard let currentUserID = authManager.currentUserID else { return nil }
        guard let index = entries.firstIndex(where: { $0.id == currentUserID }) else { return nil }
        return index + 1
    }

    private var currentUserEntry: LeagueEntry? {
        guard let currentUserID = authManager.currentUserID else { return nil }
        return entries.first(where: { $0.id == currentUserID })
    }

    private func userRankCard(rank: Int, totalUsers: Int, balance: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("La tua posizione")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("\(rank)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(.accentCyan)
            }

            HStack(spacing: 6) {
                Text("Saldo")
                    .font(.caption)
                    .foregroundColor(.gray)

                GemIcon(color: .accentCyan, lineWidth: 1.2)
                    .frame(width: 12, height: 12)

                Text(compactBalance(balance))
                    .font(.caption.bold())
                    .foregroundColor(.accentCyan)

                Text("• \(totalUsers) utenti")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.accentCyan.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.45), lineWidth: 1)
                )
        )
    }

    private var userNotRankedCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.orange)
            Text("Il tuo profilo non e ancora presente in questa classifica.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func leagueRow(rank: Int, entry: LeagueEntry, isCurrentUser: Bool) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundColor(isCurrentUser ? .accentCyan : rankColor(rank))
                .frame(width: 42, alignment: .leading)

            profileAvatar(for: entry)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    if isCurrentUser {
                        Text("TU")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.accentCyan)
                            )
                    }
                }
                Text(entry.id.prefix(8).uppercased())
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 5) {
                GemIcon(color: .accentCyan, lineWidth: 1.2)
                    .frame(width: 13, height: 13)

                Text(compactBalance(entry.balance))
                    .font(.subheadline.bold())
                    .foregroundColor(.accentCyan)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrentUser ? Color.accentCyan.opacity(0.14) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isCurrentUser ? Color.accentCyan.opacity(0.55) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }

    @ViewBuilder
    private func profileAvatar(for entry: LeagueEntry) -> some View {
        if let data = entry.profileImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        } else {
            Circle()
                .fill(Color.accentCyan.opacity(0.25))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(entry.name.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.accentCyan)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .accentCyan
        }
    }

    private func fetchLeaderboard(for scope: LeaderboardScope, showFullScreenLoader: Bool = true, completion: (() -> Void)? = nil) {
        if showFullScreenLoader {
            isLoading = true
        }
        errorMessage = nil

        switch scope {
        case .global:
            fetchGlobalLeaderboard(completion: completion)
        case .friends:
            fetchFriendsLeaderboard(completion: completion)
        }
    }

    private func fetchGlobalLeaderboard(completion: (() -> Void)?) {
        Firestore.firestore()
            .collection("users")
            .order(by: "balance", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Errore nel caricamento: \(error.localizedDescription)"
                        self.isLoading = false
                        completion?()
                        return
                    }

                    let parsedEntries = (snapshot?.documents ?? []).compactMap(self.makeEntry(from:))
                        .sorted(by: { $0.balance > $1.balance })

                    self.entries = parsedEntries
                    self.isLoading = false
                    completion?()
                }
            }
    }

    private func fetchFriendsLeaderboard(completion: (() -> Void)?) {
        guard let currentUserID = authManager.currentUserID else {
            entries = []
            isLoading = false
            completion?()
            return
        }

        let usersRef = Firestore.firestore().collection("users")
        usersRef.document(currentUserID).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Errore nel caricamento amici: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?()
                    return
                }

                let data = snapshot?.data() ?? [:]
                let friendIDs = self.friendIDs(from: data)
                let idsToLoad = Array(Set(friendIDs + [currentUserID]))

                if idsToLoad.isEmpty {
                    self.entries = []
                    self.isLoading = false
                    completion?()
                    return
                }

                self.fetchUsers(byIDs: idsToLoad) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let loadedEntries):
                            self.entries = loadedEntries.sorted(by: { $0.balance > $1.balance })
                        case .failure(let error):
                            self.errorMessage = "Errore nel caricamento classifica amici: \(error.localizedDescription)"
                        }

                        self.isLoading = false
                        completion?()
                    }
                }
            }
        }
    }

    private func fetchUsers(byIDs ids: [String], completion: @escaping (Result<[LeagueEntry], Error>) -> Void) {
        let chunks = ids.chunked(into: 10)
        fetchUsersChunked(chunks, index: 0, accumulated: [], completion: completion)
    }

    private func fetchUsersChunked(
        _ chunks: [[String]],
        index: Int,
        accumulated: [LeagueEntry],
        completion: @escaping (Result<[LeagueEntry], Error>) -> Void
    ) {
        guard index < chunks.count else {
            completion(.success(accumulated))
            return
        }

        let currentChunk = chunks[index]
        guard !currentChunk.isEmpty else {
            fetchUsersChunked(chunks, index: index + 1, accumulated: accumulated, completion: completion)
            return
        }

        Firestore.firestore()
            .collection("users")
            .whereField(FieldPath.documentID(), in: currentChunk)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let newEntries = (snapshot?.documents ?? []).compactMap(self.makeEntry(from:))
                fetchUsersChunked(
                    chunks,
                    index: index + 1,
                    accumulated: accumulated + newEntries,
                    completion: completion
                )
            }
    }

    private func makeEntry(from doc: QueryDocumentSnapshot) -> LeagueEntry? {
        let data = doc.data()
        let trimmedName = (data["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = (trimmedName?.isEmpty == false) ? (trimmedName ?? "Utente") : "Utente"
        let balance = toDouble(data["balance"]) ?? 0
        let profileImageData = imageData(from: data["profileImageBase64"])

        return LeagueEntry(
            id: doc.documentID,
            name: resolvedName,
            balance: balance,
            profileImageData: profileImageData
        )
    }

    private func refreshLeaderboard() async {
        await withCheckedContinuation { continuation in
            fetchLeaderboard(for: selectedScope, showFullScreenLoader: false) {
                continuation.resume()
            }
        }
    }

    private func toDouble(_ raw: Any?) -> Double? {
        switch raw {
        case let value as Double:
            return value
        case let value as Float:
            return Double(value)
        case let value as Int:
            return Double(value)
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private func imageData(from raw: Any?) -> Data? {
        guard let base64 = raw as? String else { return nil }
        return Data(base64Encoded: base64)
    }

    private func friendIDs(from data: [String: Any]) -> [String] {
        let candidateKeys = ["friends", "friendIDs", "friendsIDs", "friendIds", "amici"]

        for key in candidateKeys {
            if let ids = data[key] as? [String] {
                return ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }

            if let ids = data[key] as? [Any] {
                return ids
                    .compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        }

        return []
    }

    private func compactBalance(_ value: Double) -> String {
        let absoluteValue = abs(value)
        let prefix = value < 0 ? "-" : ""

        if absoluteValue >= 1_000_000_000 {
            return "\(prefix)\(shortValue(absoluteValue / 1_000_000_000))B"
        }
        if absoluteValue >= 1_000_000 {
            return "\(prefix)\(shortValue(absoluteValue / 1_000_000))M"
        }
        if absoluteValue >= 1_000 {
            return "\(prefix)\(shortValue(absoluteValue / 1_000))K"
        }

        return "\(prefix)\(Int(absoluteValue.rounded()))"
    }

    private func shortValue(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }
}

struct UserPublicProfileView: View {
    @EnvironmentObject private var authManager: AuthManager

    let userID: String
    let initialName: String?
    let initialAccountCode: String?
    let initialProfileImageData: Data?
    let initialBalance: Double?

    @State private var name: String
    @State private var accountCode: String
    @State private var profileImageData: Data?
    @State private var balance: Double?
    @State private var streakDays: Int?
    @State private var totalBetsCount: Int?
    @State private var totalWins: Int?
    @State private var totalLosses: Int?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isFriend = false
    @State private var hasPendingRequest = false
    @State private var isPerformingFriendAction = false
    @State private var friendshipMessage: String?
    @State private var friendshipMessageColor: Color = .gray
    @State private var showRemoveFriendshipAlert = false
    @State private var isDeveloperBadgeAnimating = false
    private let streakFireGIFURL = URL(string: "https://fonts.gstatic.com/s/e/notoemoji/latest/1f525/512.gif")

    private static let developerAccountCodes: Set<String> = [
        "ZD0HBGEQ",
        "8K4AKMTL",
        "RFE6F1Y3"
    ]

    init(
        userID: String,
        initialName: String? = nil,
        initialAccountCode: String? = nil,
        initialProfileImageData: Data? = nil,
        initialBalance: Double? = nil
    ) {
        self.userID = userID
        self.initialName = initialName
        self.initialAccountCode = initialAccountCode
        self.initialProfileImageData = initialProfileImageData
        self.initialBalance = initialBalance

        let trimmedInitialName = initialName?.trimmingCharacters(in: .whitespacesAndNewlines)
        _name = State(initialValue: (trimmedInitialName?.isEmpty == false) ? (trimmedInitialName ?? "Utente") : "Utente")
        _accountCode = State(initialValue: UserPublicProfileView.normalizedAccountCode(initialAccountCode, userID: userID))
        _profileImageData = State(initialValue: initialProfileImageData)
        _balance = State(initialValue: initialBalance)
        _streakDays = State(initialValue: nil)
        _totalBetsCount = State(initialValue: nil)
        _totalWins = State(initialValue: nil)
        _totalLosses = State(initialValue: nil)
    }

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

            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    statsCard
                    if shouldShowFriendshipAction {
                        friendshipActionCard
                    }

                    if let friendshipMessage {
                        Text(friendshipMessage)
                            .font(.caption)
                            .foregroundColor(friendshipMessageColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }

            if isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(.accentCyan)
                    Text("Caricamento profilo...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.accentCyan.opacity(0.22), lineWidth: 1)
                        )
                )
            }
        }
        .navigationTitle("Profilo")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserProfile()
            refreshFriendshipState()
        }
        .alert("Conferma rimozione", isPresented: $showRemoveFriendshipAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Rimuovi", role: .destructive) {
                removeFriendship()
            }
        } message: {
            Text("Vuoi eliminare l'amicizia con \(name)?")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            avatarWithStreak

            HStack(spacing: 6) {
                Text(name)
                    .font(.title3.bold())
                    .foregroundColor(.white)

                if isDeveloperProfile {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentCyan)
                }
            }

            if isDeveloperProfile {
                developerBadge
            }

            Text("Codice: \(accountCode)")
                .font(.caption)
                .foregroundColor(isDeveloperProfile ? .accentCyan : .gray)

            if let balance {
                HStack(spacing: 8) {
                    Text("Saldo")
                        .font(.caption)
                        .foregroundColor(.gray)

                    GemAmountLabel(
                        amount: balance,
                        color: .accentCyan,
                        font: .subheadline,
                        weight: .bold,
                        iconSize: 14
                    )
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.accentCyan.opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDeveloperProfile ? Color.accentCyan.opacity(0.09) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isDeveloperProfile ? Color.accentCyan.opacity(0.65) : Color.accentCyan.opacity(0.18),
                            lineWidth: isDeveloperProfile ? 1.5 : 1
                        )
                )
        )
        .shadow(
            color: isDeveloperProfile ? Color.accentCyan.opacity(0.28) : Color.clear,
            radius: isDeveloperProfile ? 16 : 0,
            x: 0,
            y: 8
        )
    }

    private var isDeveloperProfile: Bool {
        Self.developerAccountCodes.contains(accountCode.uppercased())
    }

    private var developerBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "hammer.fill")
            Text("Sviluppatore SportPredix")
        }
        .font(.caption.bold())
        .foregroundColor(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentCyan,
                    Color.mint
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .scaleEffect(isDeveloperBadgeAnimating ? 1.02 : 0.98)
        .shadow(
            color: Color.accentCyan.opacity(isDeveloperBadgeAnimating ? 0.42 : 0.24),
            radius: isDeveloperBadgeAnimating ? 12 : 7,
            x: 0,
            y: 5
        )
        .animation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true), value: isDeveloperBadgeAnimating)
        .onAppear {
            isDeveloperBadgeAnimating = true
        }
        .onDisappear {
            isDeveloperBadgeAnimating = false
        }
    }

    private var statsCard: some View {
        HStack(spacing: 10) {
            statItem(title: "Puntate", value: "\(totalBetsCount ?? 0)", color: .accentCyan)
            statItem(title: "Vinte", value: "\(totalWins ?? 0)", color: .green)
            statItem(title: "Perse", value: "\(totalLosses ?? 0)", color: .red)
        }
    }

    private var shouldShowFriendshipAction: Bool {
        guard let currentUserID = authManager.currentUserID else { return false }
        return currentUserID != userID
    }

    @ViewBuilder
    private var friendshipActionCard: some View {
        if hasPendingRequest && !isFriend {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                Text("Richiesta in sospeso")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        } else {
            Button(action: performFriendshipAction) {
                HStack(spacing: 8) {
                    Image(systemName: isFriend ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
                    Text(isFriend ? "Elimina amicizia" : "Aggiungi agli amici")
                        .font(.subheadline.bold())
                }
                .foregroundColor(isFriend ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isFriend ? Color.red.opacity(0.85) : Color.accentCyan)
                )
            }
            .buttonStyle(.plain)
            .disabled(isPerformingFriendAction)
            .opacity(isPerformingFriendAction ? 0.6 : 1)
        }
    }

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var avatarWithStreak: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarView

            if let streakDays, streakDays > 0 {
                ZStack(alignment: .bottom) {
                    if let streakFireGIFURL {
                        RemoteGIFImageView(url: streakFireGIFURL)
                            .frame(width: 18, height: 18)
                            .clipped()
                    }

                    Text("\(streakDays)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .frame(minWidth: 22, minHeight: 15)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.86))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.orange.opacity(0.55), lineWidth: 1)
                                )
                        )
                        .offset(y: 4)
                }
                .frame(width: 24, height: 34)
                .offset(x: 6, y: 8)
            }
        }
        .padding(.bottom, (streakDays ?? 0) > 0 ? 6 : 0)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let profileImageData, let image = UIImage(data: profileImageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.accentCyan.opacity(0.65), lineWidth: 2)
                )
        } else {
            Circle()
                .fill(Color.accentCyan.opacity(0.25))
                .frame(width: 84, height: 84)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.accentCyan)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private func loadUserProfile() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Firestore.firestore().collection("users").document(userID).getDocument { snapshot, error in
            DispatchQueue.main.async {
                defer { isLoading = false }

                if let error {
                    errorMessage = "Errore nel caricamento profilo: \(error.localizedDescription)"
                    return
                }

                guard let data = snapshot?.data() else {
                    errorMessage = "Profilo non disponibile."
                    return
                }

                if let rawName = data["name"] as? String {
                    let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        name = trimmedName
                    }
                }

                accountCode = Self.normalizedAccountCode(data["accountCode"] as? String, userID: userID)
                balance = toDouble(data["balance"]) ?? balance
                streakDays = toInt(data["streakDays"]) ?? streakDays ?? 0
                totalBetsCount = toInt(data["totalBetsCount"]) ?? totalBetsCount ?? 0
                totalWins = toInt(data["totalWins"]) ?? totalWins ?? 0
                totalLosses = toInt(data["totalLosses"]) ?? totalLosses ?? 0

                if let base64 = data["profileImageBase64"] as? String,
                   let decoded = Data(base64Encoded: base64) {
                    profileImageData = decoded
                }
            }
        }
    }

    private func refreshFriendshipState() {
        guard shouldShowFriendshipAction else { return }

        authManager.loadFriendCenterSnapshot { result in
            switch result {
            case .success(let snapshot):
                isFriend = snapshot.friends.contains(where: { $0.id == userID })
                let hasSentRequest = snapshot.sent.contains(where: { $0.id == userID })
                let hasReceivedRequest = snapshot.received.contains(where: { $0.id == userID })
                hasPendingRequest = !isFriend && (hasSentRequest || hasReceivedRequest)
            case .failure:
                break
            }
        }
    }

    private func performFriendshipAction() {
        guard !isPerformingFriendAction, !hasPendingRequest else { return }
        if isFriend {
            showRemoveFriendshipAlert = true
        } else {
            addFriend()
        }
    }

    private func addFriend() {
        isPerformingFriendAction = true
        friendshipMessage = nil

        authManager.sendFriendRequest(byAccountCode: accountCode) { result in
            isPerformingFriendAction = false

            switch result {
            case .success(let resolvedName):
                friendshipMessage = "Richiesta inviata a \(resolvedName)."
                friendshipMessageColor = .green
                hasPendingRequest = true
            case .failure(let error):
                if case .alreadyFriend = error {
                    isFriend = true
                    hasPendingRequest = false
                    friendshipMessage = "Siete gia amici."
                    friendshipMessageColor = .green
                } else {
                    friendshipMessage = error.localizedDescription
                    friendshipMessageColor = .orange
                }
            }

            refreshFriendshipState()
        }
    }

    private func removeFriendship() {
        isPerformingFriendAction = true
        friendshipMessage = nil

        authManager.removeFriend(userID: userID) { result in
            isPerformingFriendAction = false

            switch result {
            case .success:
                isFriend = false
                hasPendingRequest = false
                friendshipMessage = "Amicizia rimossa."
                friendshipMessageColor = .green
            case .failure(let error):
                friendshipMessage = error.localizedDescription
                friendshipMessageColor = .orange
            }

            refreshFriendshipState()
        }
    }

    private func compactBalance(_ value: Double) -> String {
        let absoluteValue = abs(value)
        let prefix = value < 0 ? "-" : ""

        if absoluteValue >= 1_000_000_000 {
            return "\(prefix)\(shortValue(absoluteValue / 1_000_000_000))B"
        }
        if absoluteValue >= 1_000_000 {
            return "\(prefix)\(shortValue(absoluteValue / 1_000_000))M"
        }
        if absoluteValue >= 1_000 {
            return "\(prefix)\(shortValue(absoluteValue / 1_000))K"
        }

        return "\(prefix)\(Int(absoluteValue.rounded()))"
    }

    private func shortValue(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }

    private func toDouble(_ raw: Any?) -> Double? {
        switch raw {
        case let value as Double:
            return value
        case let value as Float:
            return Double(value)
        case let value as Int:
            return Double(value)
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private func toInt(_ raw: Any?) -> Int? {
        switch raw {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as Double:
            return Int(value)
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    private static func normalizedAccountCode(_ raw: String?, userID: String) -> String {
        if let raw {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return String(userID.prefix(8)).uppercased()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var chunks: [[Element]] = []
        var index = startIndex

        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(Array(self[index..<end]))
            index = end
        }

        return chunks
    }
}
