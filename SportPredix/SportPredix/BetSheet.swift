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
            backgroundLayer

            VStack(spacing: 0) {
                handle
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if picks.isEmpty {
                            emptyState
                        } else {
                            ticketList
                            financialCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
        }
        .onTapGesture { isStakeFieldFocused = false }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 90 || value.translation.height > 120 {
                        dismiss()
                    }
                }
        )
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.04),
                    Color(red: 0.06, green: 0.08, blue: 0.11),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentCyan.opacity(0.10))
                    .frame(height: 130)
                    .blur(radius: 55)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.35))
            .frame(width: 52, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ticket Pronostici")
                    .font(.custom("AvenirNextCondensed-Bold", size: 25))
                    .foregroundColor(.white)

                Text(picks.count == 1 ? "1 selezione attiva" : "\(picks.count) selezioni attive")
                    .font(.custom("AvenirNext-Medium", size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 30, height: 30)
                    .background(Color.accentCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.72))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 28)

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 54))
                .foregroundColor(.accentCyan)

            Text("Nessuna quota selezionata")
                .font(.custom("AvenirNextCondensed-Bold", size: 28))
                .foregroundColor(.white)

            Text("Apri una partita e tocca una quota per creare il ticket.")
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)

            Button {
                dismiss()
            } label: {
                Text("Vai alle partite")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.accentCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer().frame(height: 10)
        }
        .padding(16)
        .background(cardSurface(0.12))
    }

    private var ticketList: some View {
        VStack(spacing: 10) {
            ForEach(picks) { pick in
                selectionRow(pick)
            }
        }
    }

    private func selectionRow(_ pick: BetPick) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(pick.match.home) - \(pick.match.away)")
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(pick.match.competition)
                        .font(.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(pick.match.time)
                        .font(.custom("Menlo-Bold", size: 12))
                        .foregroundColor(.accentCyan)

                    Text(pick.match.status)
                        .font(.custom("AvenirNext-Medium", size: 11))
                        .foregroundColor(statusColor(for: pick.match.status))
                }
            }

            HStack(spacing: 8) {
                dataChip("Esito \(pick.outcome.rawValue)", fill: Color.accentCyan, text: .black)
                dataChip(
                    "Quota \(pick.odd.formatted(.number.precision(.fractionLength(2))))",
                    fill: Color.white.opacity(0.14),
                    text: .white
                )

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        picks.removeAll { $0.id == pick.id }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red.opacity(0.95))
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(cardSurface(0.10))
    }

    private var financialCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                statBlock(
                    title: "Quota totale",
                    value: totalOdd.formatted(.number.precision(.fractionLength(2))),
                    color: .accentCyan
                )
                statBlock(
                    title: "Vincita",
                    value: potentialWin.formatted(.currency(code: "EUR")),
                    color: canConfirm ? .green : .gray
                )
            }

            statBlock(
                title: "Saldo disponibile",
                value: balance.formatted(.currency(code: "EUR")),
                color: .white
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Importo puntata")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(.gray)

                HStack(spacing: 10) {
                    Text("EUR")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.accentCyan)
                        .clipShape(Capsule())

                    TextField("Inserisci importo", text: $stakeText)
                        .keyboardType(.decimalPad)
                        .focused($isStakeFieldFocused)
                        .foregroundColor(.white)
                        .font(.custom("Menlo-Bold", size: 13))
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(quickStakeOptions, id: \.self) { amount in
                        let selected = abs(stake - amount) < 0.001
                        Button {
                            stakeText = amount.cleanNumberString
                        } label: {
                            Text(amount.formatted(.currency(code: "EUR")))
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundColor(selected ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(selected ? Color.accentCyan : Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if stake > balance {
                warningLabel("Saldo insufficiente per confermare questo importo.", color: .red)
            }

            if hasLockedPick {
                warningLabel("Una o piu partite sono iniziate: aggiorna le selezioni.", color: .orange)
            }

            Button {
                guard canConfirm else { return }
                if onConfirm(stake) {
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Conferma ticket")
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(canConfirm ? Color.accentCyan : Color.gray.opacity(0.40))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
        }
        .padding(14)
        .background(cardSurface(0.12))
    }

    private func statBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(.gray)

            Text(value)
                .font(.custom("Menlo-Bold", size: 13))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func warningLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("AvenirNext-Medium", size: 12))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dataChip(_ text: String, fill: Color, text color: Color) -> some View {
        Text(text)
            .font(.custom("AvenirNext-DemiBold", size: 12))
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(fill)
            .clipShape(Capsule())
    }

    private func cardSurface(_ opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(opacity))
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
