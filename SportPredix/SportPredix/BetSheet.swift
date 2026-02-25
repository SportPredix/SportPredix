//
//  BetSheet.swift
//  SportPredix
//
//  Created by Francesco on 16/01/26.
//

import SwiftUI

struct BetSheet: View {
    @Binding var picks: [BetPick]
    @Binding var balance: Double
    let totalOdd: Double
    let onConfirm: (Double) -> Bool

    @State private var stakeText: String = "10"
    @FocusState private var isStakeFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var stake: Double {
        Double(stakeText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var potentialWin: Double {
        stake * totalOdd
    }

    private var hasLockedPick: Bool {
        picks.contains { $0.match.status.uppercased() != "SCHEDULED" }
    }

    private var canConfirm: Bool {
        !picks.isEmpty && !hasLockedPick && stake > 0 && stake <= balance
    }

    private var quickStakeOptions: [Double] {
        [5, 10, 20, 50, 100]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if picks.isEmpty {
                            emptyState
                        } else {
                            picksSection
                            summaryCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
        }
        .onTapGesture {
            isStakeFieldFocused = false
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        dismiss()
                    }
                }
        )
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Il mio pronostico")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text(picks.count == 1 ? "1 selezione" : "\(picks.count) selezioni")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "eurosign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentCyan)

                    Text(balance.formatted(.currency(code: "EUR")))
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundColor(.accentCyan)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.accentCyan.opacity(0.30), lineWidth: 1)
                        )
                )

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.accentCyan)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.accentCyan.opacity(0.30), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Color.black.opacity(0.3)
                    .background(.ultraThinMaterial.opacity(0.7))
                    .ignoresSafeArea(edges: .top)
            )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .accentCyan.opacity(0.3),
                            .blue.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .blur(radius: 0.5)
                .padding(.horizontal, 20)
        }
    }

    private var picksSection: some View {
        VStack(spacing: 10) {
            ForEach(picks) { pick in
                pickCard(pick)
            }
        }
    }

    private func pickCard(_ pick: BetPick) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(pick.match.home) - \(pick.match.away)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(pick.match.competition)
                        .font(.caption2)
                        .foregroundColor(.accentCyan)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(pick.match.time)
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.gray)

                    Text(pick.match.status)
                        .font(.caption2)
                        .foregroundColor(statusColor(for: pick.match.status))
                }
            }

            HStack(spacing: 0) {
                selectionCell(
                    title: "Esito",
                    value: pick.outcome.rawValue,
                    valueColor: .accentCyan
                )

                Divider()
                    .frame(height: 34)
                    .background(Color.gray.opacity(0.30))

                selectionCell(
                    title: "Quota",
                    value: pick.odd.formatted(.number.precision(.fractionLength(2))),
                    valueColor: .white
                )

                Divider()
                    .frame(height: 34)
                    .background(Color.gray.opacity(0.30))

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        picks.removeAll { $0.id == pick.id }
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .bold))
                        Text("Rimuovi")
                            .font(.caption2)
                    }
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
        }
        .padding()
        .background(cardBackground())
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 28)

            Image(systemName: "checklist")
                .font(.system(size: 56))
                .foregroundColor(.accentCyan)

            Text("Nessun pronostico selezionato")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Torna alla sezione Sport e aggiungi almeno una selezione.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                dismiss()
            } label: {
                Text("Vai alla sezione Sport")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentCyan)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(16)
        .background(cardBackground(stroke: Color.white.opacity(0.12)))
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                summaryStat(
                    title: "Quota totale",
                    value: totalOdd.formatted(.number.precision(.fractionLength(2))),
                    color: .accentCyan
                )

                summaryStat(
                    title: "Vincita potenziale",
                    value: potentialWin.formatted(.currency(code: "EUR")),
                    color: canConfirm ? .green : .gray
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Importo puntata")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gray)

                HStack(spacing: 10) {
                    Text("EUR")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.accentCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.accentCyan.opacity(0.14))
                        .clipShape(Capsule())

                    TextField("Inserisci importo", text: $stakeText)
                        .keyboardType(.decimalPad)
                        .focused($isStakeFieldFocused)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isStakeFieldFocused ? Color.accentCyan.opacity(0.5) : Color.white.opacity(0.24),
                                    lineWidth: 1
                                )
                        )
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(quickStakeOptions, id: \.self) { amount in
                        let selected = abs(stake - amount) < 0.001
                        Button {
                            stakeText = amount.cleanNumberString
                        } label: {
                            Text(amount.formatted(.currency(code: "EUR")))
                                .font(.caption.bold())
                                .foregroundColor(selected ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selected ? Color.accentCyan : Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(
                                                    selected ? Color.accentCyan : Color.white.opacity(0.24),
                                                    lineWidth: 1.2
                                                )
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            summaryStat(
                title: "Saldo disponibile",
                value: balance.formatted(.currency(code: "EUR")),
                color: .white
            )

            if stake > balance {
                Text("Saldo insufficiente per confermare questo importo.")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if hasLockedPick {
                Text("Una o piu partite sono iniziate: aggiorna le selezioni prima di confermare.")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                guard canConfirm else { return }
                if onConfirm(stake) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Conferma pronostico")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(canConfirm ? Color.accentCyan : Color.gray.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
        }
        .padding(14)
        .background(cardBackground(stroke: Color.white.opacity(0.12)))
    }

    private func summaryStat(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private func selectionCell(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(.body, design: .monospaced).bold())
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
    }

    private func cardBackground(stroke: Color = Color.white.opacity(0.10)) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }

    private func statusColor(for status: String) -> Color {
        switch status.uppercased() {
        case "FINISHED":
            return .green
        case "LIVE":
            return .red
        default:
            return .orange
        }
    }
}

private extension Double {
    var cleanNumberString: String {
        rounded() == self ? String(Int(self)) : String(self)
    }
}
