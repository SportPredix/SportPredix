import SwiftUI
import FirebaseFirestore

private struct LeagueEntry: Identifiable {
    let id: String
    let name: String
    let balance: Double
}

struct LeagueLeaderboardView: View {
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
                        ForEach(entries.indices, id: \.self) { index in
                            leagueRow(rank: index + 1, entry: entries[index])
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            if entries.isEmpty {
                fetchLeaderboard()
            }
        }
    }
    
    private func leagueRow(rank: Int, entry: LeagueEntry) -> some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundColor(rankColor(rank))
                .frame(width: 42, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
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
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .accentCyan
        }
    }
    
    private func fetchLeaderboard() {
        isLoading = true
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
                        return
                    }
                    
                    let parsedEntries: [LeagueEntry] = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        let trimmedName = (data["name"] as? String)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let resolvedName = (trimmedName?.isEmpty == false) ? (trimmedName ?? "Utente") : "Utente"
                        let balance = toDouble(data["balance"]) ?? 0
                        return LeagueEntry(id: doc.documentID, name: resolvedName, balance: balance)
                    } ?? []
                    
                    self.entries = parsedEntries
                    self.isLoading = false
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
}
