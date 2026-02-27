import SwiftUI

struct SportPassOrbitBorder: View {
    var cornerRadius: CGFloat = 16
    var lineWidth: CGFloat = 1.1
    private let trailLength: CGFloat = 18
    private let cycleDuration: TimeInterval = 1.9

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let w = max(1, geometry.size.width)
                let h = max(1, geometry.size.height)
                let r = min(cornerRadius, min(w, h) * 0.5)
                let perimeter = max(1, (2 * (w + h - (2 * r))) + (2 * .pi * r))
                let progress = CGFloat(
                    (timeline.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
                )
                let phase = -progress * (perimeter + trailLength)

                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.22), lineWidth: lineWidth)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.98), Color.accentCyan.opacity(0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [trailLength, perimeter],
                                dashPhase: phase
                            )
                        )
                        .shadow(color: Color.accentCyan.opacity(0.55), radius: 4)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

struct SportPassDetailView: View {
    @EnvironmentObject var vm: BettingViewModel
    @State private var showInfoPopup = false
    @State private var showPointsHistory = false
    @State private var claimingTierLevels: Set<Int> = []
    @State private var claimFeedback: String?
    @State private var claimFeedbackColor: Color = .gray

    var body: some View {
        ZStack {
            passBackground

            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                    rewardsRoadCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("SportPass")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 10) {
                    Button {
                        showPointsHistory = true
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.accentCyan)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.accentCyan.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .accessibilityLabel("Storico punti SportPass")

                    Button {
                        showInfoPopup = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.accentCyan)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.accentCyan.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .accessibilityLabel("Info SportPass")
                }
            }
        }
        .sheet(isPresented: $showPointsHistory) {
            SportPassPointsHistorySheet(receipts: vm.sportPassPointReceipts)
        }
        .alert("Come guadagnare punti SportPass", isPresented: $showInfoPopup) {
            Button("Ho capito", role: .cancel) { }
        } message: {
            Text(
                "I punti SportPass arrivano solo quando una schedina è vinta.\n\n" +
                "Come vengono calcolati:\n" +
                "1) Più la tua quota è alta, più punti ottieni.\n" +
                "2) Quantità di pronostici presenti.\n" +
                "3) L'importo giocato conta poco, quindi chi punta tanto non ha un vantaggio enorme.\n" +
                "4) Se sei costante nel tempo, hai un piccolo bonus extra.\n" +
                "Serve per mantenere il pass equilibrato per tutti.\n\n" +
                "Esempi:\n" +
                "- Schedina a quota bassa = pochi punti.\n" +
                "- Schedina a quota alta = piu punti.\n" +
                "- Due utenti con puntate diverse ma stessa difficolta ottengono punti simili."
            )
        }
    }

    private var passBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.04, green: 0.07, blue: 0.14)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentCyan.opacity(0.24),
                    Color.blue.opacity(0.1),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 40,
                endRadius: 340
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.mint.opacity(0.15),
                    Color.clear
                ]),
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("PASS ROAD")
                        .font(.caption.bold())
                        .tracking(1.2)
                        .foregroundColor(.accentCyan.opacity(0.95))

                    Text("SportPass")
                        .font(.title3.weight(.black))
                        .foregroundColor(.white)
                }

                Spacer()

                Text("LIV \(vm.sportPassCurrentTier)/\(vm.sportPassMaxTier)")
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentCyan)
                    )
            }

            HStack(spacing: 10) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentCyan.opacity(0.9), Color.blue.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                Text("\(sportPassPointsText(vm.sportPassPoints)) punti raccolti")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Spacer()

                if let nextTier = vm.sportPassNextTier {
                    Text("Prossimo L\(nextTier.level)")
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
                        .frame(width: max(12, geometry.size.width * max(0, min(1, vm.sportPassProgressToNextTier))))
                        .animation(.easeInOut(duration: 0.25), value: vm.sportPassProgressToNextTier)
                }
            }
            .frame(height: 10)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.74))
                .overlay(
                    SportPassOrbitBorder(cornerRadius: 16, lineWidth: 1.4)
                )
        )
        .shadow(color: Color.accentCyan.opacity(0.34), radius: 14, x: 0, y: 2)
    }

    private var rewardsRoadCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Road Ricompense")
                    .font(.headline.weight(.black))
                    .foregroundColor(.white)

                Spacer()

                GemIcon(color: .black, lineWidth: 1.7)
                    .frame(width: 14, height: 14)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentCyan)
                    )
            }

            if let claimFeedback {
                Text(claimFeedback)
                    .font(.caption)
                    .foregroundColor(claimFeedbackColor)
            }

            ForEach(Array(vm.sportPassTiers.enumerated()), id: \.element.id) { index, tier in
                rewardRoadRow(tier: tier, isLast: index == vm.sportPassTiers.count - 1)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func rewardRoadRow(tier: SportPassTier, isLast: Bool) -> some View {
        let isUnlocked = vm.sportPassPoints >= tier.requiredPoints
        let isCurrentTarget = vm.sportPassNextTier?.level == tier.level
        let isClaimed = vm.isSportPassTierClaimed(tier)
        let isClaimable = vm.canClaimSportPassTier(tier)
        let isClaiming = claimingTierLevels.contains(tier.level)

        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isClaimed ? Color.white.opacity(0.12) : (isUnlocked ? Color.accentCyan : Color.white.opacity(0.12)))
                        .frame(width: 34, height: 34)

                    Text("L\(tier.level)")
                        .font(.caption.bold())
                        .foregroundColor((isUnlocked && !isClaimed) ? .black : .white)
                }

                if !isLast {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(isClaimed ? Color.white.opacity(0.12) : (isUnlocked ? Color.accentCyan.opacity(0.7) : Color.white.opacity(0.12)))
                        .frame(width: 3, height: 44)
                        .padding(.top, 4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        GemIcon(
                            color: isClaimed ? Color.gray : Color.accentCyan,
                            lineWidth: 1.8
                        )
                        .frame(width: 14, height: 14)

                        Text(rewardAmountText(tier.reward))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text(statusLabel(isUnlocked: isUnlocked, isClaimed: isClaimed, isCurrentTarget: isCurrentTarget))
                        .font(.caption2.bold())
                        .foregroundColor(statusLabelForeground(isUnlocked: isUnlocked, isClaimed: isClaimed))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(statusLabelBackground(isUnlocked: isUnlocked, isClaimed: isClaimed))
                        )
                }

                HStack(spacing: 6) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.accentCyan)
                    Text("Sblocca a \(sportPassPointsText(tier.requiredPoints)) punti")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                if isClaimable {
                    Button {
                        claimTierReward(tier)
                    } label: {
                        HStack(spacing: 6) {
                            if isClaiming {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.black)
                            } else {
                                Image(systemName: "gift.fill")
                                    .font(.caption.bold())
                            }
                            Text(isClaiming ? "Riscatto..." : "Riscatta")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.accentCyan)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isClaiming)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isClaimed
                                ? [Color.white.opacity(0.03), Color.white.opacity(0.015)]
                                : (isUnlocked
                                ? [Color.accentCyan.opacity(0.2), Color.blue.opacity(0.22)]
                                : [Color.white.opacity(0.04), Color.white.opacity(0.02)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isClaimed ? Color.white.opacity(0.08) : (isUnlocked ? Color.accentCyan.opacity(0.45) : Color.white.opacity(0.1)),
                                lineWidth: 1
                            )
                    )
            )
            .opacity(isClaimed ? 0.72 : 1)
            .shadow(color: isClaimed ? Color.clear : (isUnlocked ? Color.accentCyan.opacity(0.2) : Color.clear), radius: 8, x: 0, y: 2)
        }
    }

    private func statusLabel(isUnlocked: Bool, isClaimed: Bool, isCurrentTarget: Bool) -> String {
        if isClaimed {
            return "RISCATTATA"
        }
        if isUnlocked {
            return "DA RISCATTARE"
        }
        if isCurrentTarget {
            return "PROSSIMO"
        }
        return "BLOCCATO"
    }

    private func statusLabelForeground(isUnlocked: Bool, isClaimed: Bool) -> Color {
        if isClaimed {
            return .accentCyan
        }
        if isUnlocked {
            return .black
        }
        return .accentCyan
    }

    private func statusLabelBackground(isUnlocked: Bool, isClaimed: Bool) -> Color {
        if isClaimed {
            return Color.accentCyan.opacity(0.18)
        }
        if isUnlocked {
            return Color.accentCyan
        }
        return Color.white.opacity(0.06)
    }

    private func claimTierReward(_ tier: SportPassTier) {
        guard !claimingTierLevels.contains(tier.level) else { return }
        claimingTierLevels.insert(tier.level)

        vm.claimSportPassReward(tier) { result in
            claimingTierLevels.remove(tier.level)

            switch result {
            case .success(let amount):
                let formatted = GemFormatting.amount(amount)
                claimFeedback = "Ricompensa livello \(tier.level) riscattata: +\(formatted) Gemme."
                claimFeedbackColor = .green
            case .alreadyClaimed:
                claimFeedback = "Ricompensa livello \(tier.level) gia riscattata."
                claimFeedbackColor = .gray
            case .notUnlocked(let requiredPoints):
                claimFeedback = "Livello \(tier.level) bloccato: servono \(sportPassPointsText(requiredPoints)) punti."
                claimFeedbackColor = .orange
            case .authRequired:
                claimFeedback = "Devi essere autenticato per riscattare le ricompense."
                claimFeedbackColor = .orange
            case .invalidTier:
                claimFeedback = "Ricompensa non valida."
                claimFeedbackColor = .red
            }
        }
    }

    private func sportPassPointsText(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    private func rewardAmountText(_ reward: String) -> String {
        reward
            .replacingOccurrences(of: "Gemme", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct SportPassPointsHistorySheet: View {
    let receipts: [SportPassPointReceipt]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.08, blue: 0.12)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if receipts.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundColor(.accentCyan)
                        Text("Nessun accredito punti")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(receipts) { receipt in
                                receiptRow(receipt)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Storico Punti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.accentCyan)
                }
            }
        }
    }

    private func receiptRow(_ receipt: SportPassPointReceipt) -> some View {
        HStack(spacing: 12) {
            Text("+\(receipt.points)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.green)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.note)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
