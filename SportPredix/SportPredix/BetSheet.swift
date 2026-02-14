import SwiftUI

struct BetSheet: View {
    
    @Binding var picks: [BetPick]
    @Binding var balance: Double
    let totalOdd: Double
    let onConfirm: (Double) -> Void
    
    @State private var stakeText: String = "1"
    @FocusState private var isStakeFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    private var stake: Double {
        Double(stakeText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    private var potentialWin: Double {
        stake * totalOdd
    }
    
    private var isStakeValid: Bool {
        stake > 0 && stake <= balance
    }
    
    var body: some View {
        ZStack {
            background
            
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 54, height: 6)
                    .padding(.top, 6)
                
                Text("Schedina selezionata")
                    .font(.title.bold())
                    .foregroundColor(.accentCyan)
                
                if picks.isEmpty {
                    emptyState
                } else {
                    picksList
                    totalsCard
                    stakeCard
                    confirmButton
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .contentShape(Rectangle())
            .onTapGesture {
                isStakeFieldFocused = false
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 120 || value.translation.width > 120 {
                            dismiss()
                        }
                    }
            )
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
                    Color.accentCyan.opacity(0.22),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 24,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }
    
    private var picksList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(picks) { pick in
                    pickRow(for: pick)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .frame(maxHeight: 280)
    }
    
    private var totalsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quota totale")
                    .foregroundColor(.gray)
                Spacer()
                Text("\(totalOdd, specifier: "%.2f")")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.accentCyan)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            HStack {
                Text("Vincita potenziale")
                    .foregroundColor(.gray)
                Spacer()
                Text(euro(potentialWin))
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.green)
            }
        }
        .font(.subheadline)
        .padding(16)
        .background(glassCard(cornerRadius: 16))
    }
    
    private var stakeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Importo")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Saldo: \(euro(balance))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            TextField("Inserisci importo", text: $stakeText)
                .keyboardType(.decimalPad)
                .focused($isStakeFieldFocused)
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                quickStakeButton(5)
                quickStakeButton(10)
                quickStakeButton(20)
                quickStakeButton(50)
            }
            
            HStack {
                Text("Totale giocato")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(euro(stake))
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.accentCyan)
            }
            
            if stake > balance {
                Text("Importo superiore al saldo disponibile")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(glassCard(cornerRadius: 16))
    }
    
    private var confirmButton: some View {
        Button {
            guard isStakeValid else { return }
            onConfirm(stake)
            dismiss()
        } label: {
            Text("Conferma scommessa")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentCyan,
                                    Color.accentCyan.opacity(0.82)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.accentCyan.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .disabled(!isStakeValid)
        .opacity(isStakeValid ? 1 : 0.45)
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 36))
                .foregroundColor(.accentCyan.opacity(0.8))
            
            Text("Nessun pronostico selezionato")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Torna alle partite e scegli almeno un esito.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 14)
        .background(glassCard(cornerRadius: 16))
    }
    
    private func pickRow(for pick: BetPick) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(pick.match.home) - \(pick.match.away)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    tag(text: "Esito \(pick.outcome.rawValue)", tint: .accentCyan.opacity(0.22), textColor: .accentCyan)
                    tag(text: "Quota \(pick.odd, specifier: "%.2f")", tint: .white.opacity(0.09), textColor: .white)
                }
            }
            
            Spacer()
            
            Button {
                picks.removeAll { $0.id == pick.id }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(glassCard(cornerRadius: 14))
    }
    
    private func quickStakeButton(_ value: Int) -> some View {
        Button {
            stakeText = "\(value)"
            isStakeFieldFocused = false
        } label: {
            Text("€\(value)")
                .font(.caption.bold())
                .foregroundColor(.accentCyan)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.accentCyan.opacity(0.22), lineWidth: 1)
                        )
                )
        }
    }
    
    private func tag(text: String, tint: Color, textColor: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint)
            )
    }
    
    private func glassCard(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.accentCyan.opacity(0.18), lineWidth: 1)
            )
    }
    
    private func euro(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").locale(Locale(identifier: "it_IT")))
    }
}
