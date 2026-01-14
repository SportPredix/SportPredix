//
//  ContentView.swift
//  SportPredix
//
//  Created by Formatiks Team on 12/01/26.
//


import SwiftUI
import PhotosUI

// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

// MARK: - MODELS

enum MatchOutcome: String, Codable {
    case home = "1"
    case draw = "X"
    case away = "2"
}

struct Match: Identifiable, Codable {
    let id = UUID()
    let home: String
    let away: String
    let time: String
    let odds: [Double]
}

struct BetPick: Identifiable, Codable {
    let id = UUID()
    let match: Match
    let outcome: MatchOutcome
    let odd: Double
}

struct BetSlip: Identifiable, Codable {
    let id = UUID()
    let picks: [BetPick]
    let stake: Double
    let totalOdd: Double
    let potentialWin: Double
    let date: Date
}

// MARK: - STORAGE

final class Storage {
    static func save<T: Codable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load<T: Codable>(key: String, defaultValue: T) -> T {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let value = try? JSONDecoder().decode(T.self, from: data)
        else { return defaultValue }
        return value
    }
}

// MARK: - MAIN VIEW

struct ContentView: View {

    // Tabs
    @State private var selectedTab = 0

    // Betting
    @State private var showSheet = false
    @State private var currentPicks: [BetPick] = []

    @State private var slips: [BetSlip] =
        Storage.load(key: "slips", defaultValue: [])

    // Balance
    @State private var balance: Double =
        UserDefaults.standard.double(forKey: "balance") == 0 ? 1000 :
        UserDefaults.standard.double(forKey: "balance")

    // Calendar
    @State private var selectedDate = Date()

    // Profile
    @AppStorage("profileName") private var profileName = ""
    @State private var profileImage: UIImage? =
        Storage.load(key: "profileImage", defaultValue: UIImage())

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if selectedTab == 0 {
                    calendar
                    matchList
                }
                if selectedTab == 1 {
                    placedBets
                }
                if selectedTab == 2 {
                    profile
                }

                bottomBar
            }

            if !currentPicks.isEmpty && selectedTab == 0 {
                floatingButton
            }
        }
        .sheet(isPresented: $showSheet) {
            BetSheet(
                picks: $currentPicks,
                balance: $balance
            ) { slip in
                slips.insert(slip, at: 0)
                Storage.save(slips, key: "slips")
            }
        }
        .onChange(of: balance) {
            UserDefaults.standard.set($0, forKey: "balance")
        }
    }

    // MARK: HEADER

    private var header: some View {
        HStack {
            Text(["Calendario", "Piazzate", "Profilo"][selectedTab])
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Spacer()
            Text("€\(balance, specifier: "%.2f")")
                .foregroundColor(.accentCyan)
        }
        .padding()
    }

    // MARK: SMALL CALENDAR

    private var calendar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(-1...5, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                    VStack {
                        Text(date, format: .dateTime.day())
                        Text(date, format: .dateTime.month(.abbreviated))
                    }
                    .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .black : .white)
                    .frame(width: 60, height: 50)
                    .background(Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                ? Color.accentCyan
                                : Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .onTapGesture { selectedDate = date }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: MATCHES (AUTO)

    private var matchList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(generateMatches(for: selectedDate)) { match in
                    VStack {
                        HStack {
                            Text(match.home)
                            Spacer()
                            Text(match.time).bold()
                            Spacer()
                            Text(match.away)
                        }
                        .foregroundColor(.white)

                        HStack {
                            pickButton("1", match, .home)
                            pickButton("X", match, .draw)
                            pickButton("2", match, .away)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                }
            }
            .padding()
        }
    }

    private func pickButton(_ label: String, _ match: Match, _ outcome: MatchOutcome) -> some View {
        let odd = match.odds[outcome == .home ? 0 : outcome == .draw ? 1 : 2]
        return Button {
            if !currentPicks.contains(where: { $0.match.id == match.id }) {
                currentPicks.append(BetPick(match: match, outcome: outcome, odd: odd))
            }
        } label: {
            VStack {
                Text(label).bold()
                Text(String(format: "%.2f", odd)).font(.caption)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.accentCyan)
            .cornerRadius(10)
        }
    }

    // MARK: FLOATING BUTTON

    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.black)
                        .padding(16)
                        .background(Color.accentCyan)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
        }
    }

    // MARK: PLACED BETS

    private var placedBets: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(slips) { slip in
                    NavigationLink {
                        SlipDetailView(slip: slip)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Quota \(slip.totalOdd, specifier: "%.2f")")
                                .foregroundColor(.accentCyan)
                            Text("Puntata €\(slip.stake, specifier: "%.2f")")
                                .foregroundColor(.white)
                            Text("€\(slip.potentialWin, specifier: "%.2f")")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: PROFILE

    private var profile: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: Binding(
                get: { nil },
                set: {
                    guard let item = $0 else { return }
                    item.loadTransferable(type: Data.self) { result in
                        if let data = try? result.get(),
                           let img = UIImage(data: data) {
                            profileImage = img
                            Storage.save(img, key: "profileImage")
                        }
                    }
                }
            )) {
                if let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle().fill(Color.gray).frame(width: 100, height: 100)
                }
            }

            TextField("Il tuo nome", text: $profileName)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
        .padding()
    }

    // MARK: BOTTOM BAR

    private var bottomBar: some View {
        HStack {
            bottomItem("calendar", "Calendario", 0)
            Spacer()
            bottomItem("list.bullet", "Piazzate", 1)
            Spacer()
            bottomItem("person", "Profilo", 2)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(26)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func bottomItem(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack {
                Image(systemName: icon)
                Text(title).font(.caption)
            }
            .foregroundColor(selectedTab == index ? .accentCyan : .white)
        }
    }

    // MARK: MATCH GENERATOR

    private func generateMatches(for date: Date) -> [Match] {
        let teams = ["Napoli","Roma","Inter","Milan","Juventus","Atalanta","Lazio"]
        return (0..<3).map { i in
            Match(
                home: teams[i],
                away: teams.reversed()[i],
                time: ["18:30","20:45","21:00"][i],
                odds: [1.4, 3.8, 5.6]
            )
        }
    }
}

// MARK: - BET SHEET

struct BetSheet: View {

    @Binding var picks: [BetPick]
    @Binding var balance: Double
    let onConfirm: (BetSlip) -> Void

    @State private var stake: Double = 1

    private var totalOdd: Double {
        picks.map { $0.odd }.reduce(1, *)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                ForEach(picks) { pick in
                    Text("\(pick.match.home) - \(pick.match.away) | \(pick.outcome.rawValue)")
                        .foregroundColor(.white)
                }

                Slider(value: $stake, in: 1...min(balance, 500), step: 1)

                Button("Conferma selezione") {
                    let slip = BetSlip(
                        picks: picks,
                        stake: stake,
                        totalOdd: totalOdd,
                        potentialWin: stake * totalOdd,
                        date: Date()
                    )
                    balance -= stake
                    picks.removeAll()
                    onConfirm(slip)
                }
                .background(Color.green)
                .cornerRadius(14)
            }
            .padding()
        }
    }
}

// MARK: - DETAIL

struct SlipDetailView: View {
    let slip: BetSlip

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                ForEach(slip.picks) { pick in
                    Text("\(pick.match.home) - \(pick.match.away) | \(pick.outcome.rawValue)")
                }
                Text("Quota \(slip.totalOdd)")
                Text("Puntata €\(slip.stake)")
                Text("Possibile €\(slip.potentialWin)")
            }
            .foregroundColor(.accentCyan)
        }
    }
}
