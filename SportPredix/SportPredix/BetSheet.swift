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
    let onConfirm: (Double) -> Void

    @State private var stakeText: String = "10"
    @FocusState private var isStakeFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var stake: Double {
        Double(stakeText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var potentialWin: Double {
        stake * totalOdd
    }

    private var canConfirm: Bool {
        !picks.isEmpty && stake > 0 && stake <= balance
    }

    private var quickStakeOptions: [Double] {
        [5, 10, 20, 50, 100]
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)

                headerCard

                if picks.isEmpty {
                    emptyState
                } else {
                    picksList
                    summaryCard
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
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

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.04, green: 0.07, blue: 0.10), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [Color.accentCyan.opacity(0.26), Color.clear]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.clear]),
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentCyan.opacity(0.22))
                    .frame(width: 36, height: 36)

                Image(systemName: "checklist")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentCyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Il mio pronostico")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                Text(picks.count == 1 ? "1 selezione" : "\(picks.count) selezioni")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(glassCard(stroke: Color.accentCyan.opacity(0.28)))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 28)

            Image(systemName: "checklist.unchecked")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.accentCyan)

            Text("Nessun pronostico selezionato")
                .font(.headline)
                .foregroundColor(.white)

            Text("Torna alle partite e aggiungi almeno una selezione.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Vai alle partite")
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.accentCyan)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer()
        }
        .padding(16)
        .background(glassCard(stroke: Color.accentCyan.opacity(0.26)))
        .padding(.top, 8)
    }

    private var picksList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(picks) { pick in
                    pickCard(pick)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxHeight: 320)
    }

    private func pickCard(_ pick: BetPick) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(pick.match.home) - \(pick.match.away)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(pick.match.competition, systemImage: "trophy.fill")
                            .font(.caption2)
                            .foregroundColor(.accentCyan.opacity(0.95))
                            .lineLimit(1)

                        Text(pick.match.time)
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        picks.removeAll { $0.id == pick.id }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red.opacity(0.92))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                chip(text: pick.outcome.rawValue, foreground: .black, background: .accentCyan)
                chip(
                    text: "Quota \(pick.odd.formatted(.number.precision(.fractionLength(2))))",
                    foreground: .white,
                    background: Color.white.opacity(0.12)
                )
            }
        }
        .padding(12)
        .background(glassCard(stroke: Color.white.opacity(0.10)))
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                statTile(
                    title: "Quota totale",
                    value: totalOdd.formatted(.number.precision(.fractionLength(2))),
                    valueColor: .accentCyan
                )

                statTile(
                    title: "Saldo",
                    value: balance.formatted(.currency(code: "EUR")),
                    valueColor: .white
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Importo puntata")
                    .font(.caption.bold())
                    .foregroundColor(.gray)

                HStack(spacing: 10) {
                    Text("EUR")
                        .font(.caption.weight(.semibold))
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
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isStakeFieldFocused ? Color.accentCyan.opacity(0.5) : Color.white.opacity(0.14),
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
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(selected ? Color.accentCyan : Color.white.opacity(0.09))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text("Vincita potenziale")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                Text(potentialWin.formatted(.currency(code: "EUR")))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(canConfirm ? .green : .gray)
                    .monospacedDigit()
            }

            if stake > balance {
                Text("Saldo insufficiente per confermare questo importo.")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                guard canConfirm else { return }
                onConfirm(stake)
                dismiss()
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
                .background(canConfirm ? Color.accentCyan : Color.gray.opacity(0.35))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
        }
        .padding(14)
        .background(glassCard(stroke: Color.accentCyan.opacity(0.25)))
    }

    private func chip(text: String, foreground: Color, background: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }

    private func statTile(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func glassCard(stroke: Color) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.28)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

private extension Double {
    var cleanNumberString: String {
        rounded() == self ? String(Int(self)) : String(self)
    }
}
