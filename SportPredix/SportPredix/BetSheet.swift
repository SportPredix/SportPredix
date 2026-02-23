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
    @Environment(\.presentationMode) private var presentationMode

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
        [5, 10, 20, 50]
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)

                header

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
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.08, blue: 0.11), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [Color.accentCyan.opacity(0.20), Color.clear]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Il mio pronostico")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("\(picks.count) selezioni")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                presentationMode.wrappedValue.dismiss()
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
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 30)

            Image(systemName: "checklist.unchecked")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.accentCyan)

            Text("Nessun pronostico selezionato")
                .font(.headline)
                .foregroundColor(.white)

            Text("Torna alle partite e seleziona almeno un esito.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Chiudi")
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
        .background(cardBackground(stroke: Color.accentCyan.opacity(0.20)))
        .padding(.top, 8)
    }

    private var picksList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(picks) { pick in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(pick.match.home) - \(pick.match.away)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .lineLimit(2)

                                Text("\(pick.match.competition)  |  \(pick.match.time)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button {
                                picks.removeAll { $0.id == pick.id }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red.opacity(0.95))
                                    .frame(width: 28, height: 28)
                                    .background(Color.red.opacity(0.14))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 8) {
                            Text(pick.outcome.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.accentCyan)
                                .clipShape(Capsule())

                            Text("Quota \(pick.odd, specifier: "%.2f")")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(12)
                    .background(cardBackground(stroke: Color.white.opacity(0.08)))
                }
            }
            .padding(.top, 2)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                summaryLabel("Quota totale")
                Spacer()
                summaryValue(
                    totalOdd.formatted(.number.precision(.fractionLength(2))),
                    color: .accentCyan
                )
            }

            HStack {
                summaryLabel("Saldo disponibile")
                Spacer()
                summaryValue(balance.formatted(.currency(code: "EUR")), color: .white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Importo")
                    .font(.caption.bold())
                    .foregroundColor(.gray)

                TextField("Inserisci importo", text: $stakeText)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    ForEach(quickStakeOptions, id: \.self) { amount in
                        Button {
                            stakeText = amount.cleanNumberString
                        } label: {
                            Text(amount.formatted(.currency(code: "EUR")))
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.95))
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(9)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                summaryLabel("Vincita potenziale")
                Spacer()
                summaryValue(
                    potentialWin.formatted(.currency(code: "EUR")),
                    color: canConfirm ? .green : .gray
                )
            }

            Button {
                guard canConfirm else { return }
                onConfirm(stake)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Conferma pronostico")
                    .font(.subheadline.bold())
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
        .background(cardBackground(stroke: Color.accentCyan.opacity(0.20)))
    }

    private func summaryLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.gray)
    }

    private func summaryValue(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(color)
            .monospacedDigit()
    }

    private func cardBackground(stroke: Color) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

private extension Double {
    var cleanNumberString: String {
        rounded() == self ? String(Int(self)) : String(self)
    }
}
