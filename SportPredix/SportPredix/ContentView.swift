//
//  ContentView.swift
//  SportPredix
//

import SwiftUI

struct ContentView: View {

    @StateObject private var vm = BettingViewModel()
    @Namespace private var animationNamespace

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {

                    header

                    if vm.selectedTab == 0 {
                        calendarBar
                        matchList
                    } else if vm.selectedTab == 1 {
                        placedBets
                            .onAppear { vm.evaluateAllSlips() }
                    } else {
                        ProfileView(userName: $vm.userName, balance: $vm.balance)
                            .environmentObject(vm)
                    }

                    bottomBar
                }

                if !vm.currentPicks.isEmpty {
                    floatingButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .sheet(isPresented: $vm.showSheet) {
                BetSheet(
                    picks: $vm.currentPicks,
                    balance: $vm.balance,
                    totalOdd: vm.totalOdd
                ) { stake in vm.confirmSlip(stake: stake) }
            }
            .sheet(item: $vm.showSlipDetail) { SlipDetailView(slip: $0) }
        }
    }

    private var header: some View {
        HStack {
            Text(vm.selectedTab == 0 ? "Calendario" :
                 vm.selectedTab == 1 ? "Piazzate" : "Profilo")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Spacer()

            Text("€\(vm.balance, specifier: "%.2f")")
                .foregroundColor(.accentCyan)
                .bold()
        }
        .padding()
    }

    private var calendarBar: some View {
        HStack(spacing: 16) {
            ForEach(0..<3) { index in
                let date = vm.dateForIndex(index)

                VStack(spacing: 4) {
                    Text(vm.formattedDay(date))
                        .font(.title2.bold())
                    Text(vm.formattedMonth(date))
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(width: 90, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(vm.selectedDayIndex == index ? Color.accentCyan : Color.white.opacity(0.2), lineWidth: 3)
                )
                .onTapGesture { vm.selectedDayIndex = index }
                .animation(.easeInOut, value: vm.selectedDayIndex)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var matchList: some View {
        let groupedMatches = vm.matchesForSelectedDay()
        let isYesterday = vm.selectedDayIndex == 0

        return ScrollView {
            VStack(spacing: 16) {
                ForEach(groupedMatches.keys.sorted(), id: \.self) { time in
                    VStack(spacing: 10) {

                        // ORARIO A SINISTRA
                        HStack {
                            Text(time)
                                .font(.headline)
                                .foregroundColor(.accentCyan)
                            Spacer()
                        }

                        ForEach(groupedMatches[time]!) { match in
                            matchCard(match, disabled: isYesterday)
                        }
                    }
                }
            }
            .padding()
        }
        .id(vm.selectedDayIndex)
        .transition(.opacity)
    }

    private func matchCard(_ match: Match, disabled: Bool) -> some View {
        NavigationLink(destination: MatchDetailView(match: match, vm: vm)) {
            VStack(spacing: 10) {
                HStack {
                    Text(match.home).font(.headline)
                    Spacer()
                    Text(match.away).font(.headline)
                }
                .foregroundColor(disabled ? .gray : .white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(disabled ? Color.gray.opacity(0.1) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(disabled ? Color.gray.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .disabled(disabled)
    }

    private var placedBets: some View {
        ScrollView {
            VStack(spacing: 12) {
                if vm.slips.isEmpty {
                    Text("Nessuna scommessa piazzata")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(vm.slips) { slip in
                        Button { vm.showSlipDetail = slip } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quota \(slip.totalOdd, specifier: "%.2f")")
                                    .foregroundColor(.accentCyan)
                                Text("Puntata €\(slip.stake, specifier: "%.2f")")
                                    .foregroundColor(.white)
                                Text("Vincita potenziale €\(slip.potentialWin, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.caption)

                                if let won = slip.isWon {
                                    Text(won ? "ESITO: VINTA" : "ESITO: PERSA")
                                        .foregroundColor(won ? .green : .red)
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Button { vm.showSheet = true } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.black)
                            .padding(16)
                            .background(Color.accentCyan)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }

                    if !vm.currentPicks.isEmpty {
                        Text("\(vm.currentPicks.count)")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                            .offset(x: 8, y: -8)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
        }
    }

    private var bottomBar: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 70)
                .cornerRadius(26)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.25), radius: 10, y: -2)

            HStack(spacing: 50) {
                bottomItem(icon: "calendar", index: 0)
                bottomItem(icon: "list.bullet", index: 1)
                bottomItem(icon: "person.crop.circle", index: 2)
            }
        }
        .padding(.bottom, 8)
    }

    private func bottomItem(icon: String, index: Int) -> some View {
        let isSelected = vm.selectedTab == index

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                vm.selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentCyan.opacity(0.25))
                            .frame(width: 44, height: 44)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .accentCyan : .white.opacity(0.7))
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }

                if isSelected {
                    Capsule()
                        .fill(Color.accentCyan)
                        .frame(width: 22, height: 4)
                        .matchedGeometryEffect(id: "tabIndicator", in: animationNamespace)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 22, height: 4)
                }
            }
        }
    }
}