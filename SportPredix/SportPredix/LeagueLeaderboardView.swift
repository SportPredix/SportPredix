import SwiftUI
import FirebaseFirestore
import UIKit

private struct LeagueEntry: Identifiable {
    let id: String
    let name: String
    let balance: Double
    let profileImageData: Data?
}

struct LeagueLeaderboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var entries: [LeagueEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
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
                        fetchLeaderboard()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentCyan)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.accentCyan)
                    Text("Nessun utente in classifica")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("La classifica si popola quando ci sono utenti con saldo salvato su Firebase.")
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
                            leagueRow(
                                rank: index + 1,
                                entry: entry,
                                isCurrentUser: entry.id == authManager.currentUserID
                            )
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
        .onAppear {
            if entries.isEmpty {
                fetchLeaderboard()
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
                Text("#\(rank)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(.accentCyan)
            }

            Text("Saldo: \(balance.formatted(.currency(code: "EUR").locale(Locale(identifier: "it_IT")))) - \(totalUsers) utenti")
                .font(.caption)
                .foregroundColor(.gray)
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
            Text("Il tuo profilo non e ancora presente in classifica.")
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
            Text("#\(rank)")
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
            
            Text(entry.balance.formatted(.currency(code: "EUR").locale(Locale(identifier: "it_IT"))))
                .font(.subheadline.bold())
                .foregroundColor(.accentCyan)
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
    
    private func fetchLeaderboard(showFullScreenLoader: Bool = true, completion: (() -> Void)? = nil) {
        if showFullScreenLoader {
            isLoading = true
        }
        errorMessage = nil
        
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
                    
                    let parsedEntries: [LeagueEntry] = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        let trimmedName = (data["name"] as? String)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let resolvedName = (trimmedName?.isEmpty == false) ? (trimmedName ?? "Utente") : "Utente"
                        let balance = toDouble(data["balance"]) ?? 0
                        let profileImageData = imageData(from: data["profileImageBase64"])
                        return LeagueEntry(
                            id: doc.documentID,
                            name: resolvedName,
                            balance: balance,
                            profileImageData: profileImageData
                        )
                    } ?? []
                    
                    self.entries = parsedEntries
                    self.isLoading = false
                    completion?()
                }
            }
    }

    private func refreshLeaderboard() async {
        await withCheckedContinuation { continuation in
            fetchLeaderboard(showFullScreenLoader: false) {
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
}
