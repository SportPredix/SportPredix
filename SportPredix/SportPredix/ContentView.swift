//
//  ContentView.swift
//  SportPredix
//
//  Created by Formatiks Team on 12/01/26.
//


import SwiftUI

// MARK: - MODELS

struct Match: Identifiable {
    let id = UUID()
    let home: String
    let away: String
    let time: String
}

struct League: Identifiable {
    let id = UUID()
    let name: String
    let country: String
}

// MARK: - MAIN VIEW

struct ContentView: View {

    @State private var selectedDay: Int = 0

    private let days = [
        ("LIVE", "•"),
        ("MAR", "13 Gen"),
        ("OGGI", "14 Gen"),
        ("GIO", "15 Gen"),
        ("VEN", "16 Gen")
    ]

    private let matches: [Match] = [
        Match(home: "Napoli", away: "Parma", time: "18:30"),
        Match(home: "Inter", away: "Lecce", time: "20:45"),
        Match(home: "Albacete", away: "Real Madrid", time: "21:00"),
        Match(home: "Colonia", away: "Bayern Monaco", time: "20:30")
    ]

    private let leagues: [League] = [
        League(name: "Serie A", country: "Italia"),
        League(name: "EFL Trophy", country: "Inghilterra"),
        League(name: "Copa Del Rey", country: "Spagna")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {

                header

                daySelector

                ScrollView {
                    VStack(spacing: 24) {

                        favouriteMatchesSection

                        allMatchesSection
                    }
                    .padding(.horizontal)
                }

                bottomTab
            }
        }
    }

    // MARK: - HEADER

    private var header: some View {
        HStack {
            Text("Calendario")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "magnifyingglass")
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())

            Text("1,7K")
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
    }

    // MARK: - DAY SELECTOR

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days.indices, id: \.self) { index in
                    let day = days[index]

                    VStack {
                        Text(day.0)
                            .fontWeight(.bold)
                        Text(day.1)
                            .font(.caption)
                    }
                    .foregroundColor(selectedDay == index ? .black : .white)
                    .padding()
                    .background(
                        selectedDay == index
                        ? Color.green
                        : Color.white.opacity(0.1)
                    )
                    .cornerRadius(14)
                    .onTapGesture {
                        selectedDay = index
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - MATCH PREFERITI

    private var favouriteMatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Label("Match preferiti", systemImage: "star.fill")
                    .foregroundColor(.white)
                Spacer()
                Text("Vedi tutti ›")
                    .foregroundColor(.gray)
            }

            VStack(spacing: 16) {
                ForEach(matches) { match in
                    matchRow(match)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
        }
    }

    private func matchRow(_ match: Match) -> some View {
        HStack {
            Text(match.home)
                .foregroundColor(.white)

            Spacer()

            Text(match.time)
                .foregroundColor(.white)
                .fontWeight(.bold)

            Spacer()

            Text(match.away)
                .foregroundColor(.white)
        }
        .padding(.vertical, 6)
    }

    // MARK: - ALL MATCHES

    private var allMatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            Label("Tutte le partite", systemImage: "soccerball")
                .foregroundColor(.white)

            ForEach(leagues) { league in
                HStack {
                    VStack(alignment: .leading) {
                        Text(league.name)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text(league.country)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(18)
            }
        }
    }

    // MARK: - BOTTOM TAB

    private var bottomTab: some View {
        HStack {

            tabItem(icon: "calendar", title: "Calendario", selected: true)

            Spacer()

            tabItem(icon: "list.bullet.rectangle", title: "Palinsesto")

            Spacer()

            Circle()
                .fill(Color.green)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.black)
                )

            Spacer()

            tabItem(icon: "trophy", title: "Leghe")

            Spacer()

            tabItem(icon: "person", title: "Profilo")
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func tabItem(icon: String, title: String, selected: Bool = false) -> some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(selected ? .green : .white)
            Text(title)
                .font(.caption)
                .foregroundColor(selected ? .green : .white)
        }
    }
}

// MARK: - PREVIEW

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
