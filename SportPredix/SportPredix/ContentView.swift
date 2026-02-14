//
//  ContentView.swift
//  Sora
//
//  Created by Francesco on 06/01/25.
//

import SwiftUI

<<<<<<< HEAD
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LibraryManager())
            .environmentObject(ModuleManager())
            .environmentObject(Settings())
=======
// MARK: - THEME

extension Color {
    static let accentCyan = Color(red: 68/255, green: 224/255, blue: 203/255)
}

// MARK: - FLOATING GLASS TOOLBAR (NUOVA - SOPRA LE PAGINE)

struct FloatingGlassToolbar: View {
    @Binding var selectedTab: Int
    @Namespace private var animationNamespace
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Barra principale fluttuante
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    FloatingToolbarButton(
                        index: index,
                        selectedTab: $selectedTab,
                        animationNamespace: animationNamespace
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                // Effetto vetro sfocato con riflessi
                FloatingGlassEffect()
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: .black.opacity(0.3),
                radius: 30,
                x: 0,
                y: 10
            )
            .overlay(
                // Bordo luminoso superiore
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .accentCyan.opacity(0.1),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .offset(y: 10) // ABBASSATA
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(true)
        .zIndex(1000) // ALTO Z-INDEX PER STARE SOPRA TUTTO
>>>>>>> parent of 6192e91 (Update ContentView.swift)
    }
}

struct ContentView: View {
    @AppStorage("useNativeTabBar") private var useNativeTabBar: Bool = false
    @State var selectedTab: Int = 0
    @State var lastTab: Int = 0
    @State private var searchQuery: String = ""
    @State private var shouldShowTabBar: Bool = true
    @State private var tabBarOffset: CGFloat = 0
    @State private var tabBarVisible: Bool = true
    @State private var lastHideTime: Date = Date()
    
    let tabs: [TabItem] = [
        TabItem(icon: "calendar", title: NSLocalizedString("LibraryTab", comment: "")),
        TabItem(icon: "dice.fill", title: NSLocalizedString("DownloadsTab", comment: "")),
        TabItem(icon: "list.bullet", title: NSLocalizedString("SettingsTab", comment: "")),
        TabItem(icon: "person.crop.circle", title: NSLocalizedString("SearchTab", comment: ""))
    ]
    
    private func tabView(for index: Int) -> some View {
        switch index {
        case 1: return AnyView(DownloadView())
        case 2: return AnyView(SettingsView())
        case 3: return AnyView(SearchView(searchQuery: $searchQuery))
        default: return AnyView(LibraryView())
        }
    }
    
    var body: some View {
        if #available(iOS 26, *), useNativeTabBar == true {
            TabView {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, item in
                    tabView(for: index)
                        .tabItem {
                            Label(item.title, systemImage: item.icon)
                        }
                }
            }
            //.searchable(text: $searchQuery)
        } else {
            ZStack(alignment: .bottom) {
                ZStack {
                    tabView(for: selectedTab)
                        .id(selectedTab)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
                .onPreferenceChange(TabBarVisibilityKey.self) { shouldShowTabBar = $0 }
                
                if shouldShowTabBar {
                    TabBar(
                        tabs: tabs,
                        selectedTab: $selectedTab
                    )
                    .opacity(shouldShowTabBar && tabBarVisible ? 1 : 0)
                    .offset(y: tabBarVisible ? 0 : 120)
                    .animation(.spring(response: 0.15, dampingFraction: 0.7), value: tabBarVisible)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .padding(.bottom, -20)
            .onAppear {
                setupNotificationObservers()
            }
            .onDisappear {
                removeNotificationObservers()
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .hideTabBar,
            object: nil,
            queue: .main
        ) { _ in
            lastHideTime = Date()
            tabBarVisible = false
        }
        
        NotificationCenter.default.addObserver(
            forName: .showTabBar,
            object: nil,
            queue: .main
        ) { _ in
            let timeSinceHide = Date().timeIntervalSince(lastHideTime)
            if timeSinceHide > 0.2 {
                tabBarVisible = true
            }
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .hideTabBar, object: nil)
        NotificationCenter.default.removeObserver(self, name: .showTabBar, object: nil)
    }
}

struct TabBarVisibilityKey: PreferenceKey {
    static var defaultValue: Bool = true
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

