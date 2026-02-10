import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack {
            Color(UIColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1.0))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 15) {
                    Text("Profilo")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Gestisci il tuo account")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 25)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar e Nome
                        VStack(spacing: 15) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1.0)),
                                            Color(UIColor(red: 0.1, green: 0.8, blue: 0.5, alpha: 1.0))
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(authManager.currentUserName?.prefix(1) ?? "U").uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)
                                )
                            
                            Text(authManager.currentUserName ?? "Utente")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(authManager.currentUserEmail ?? "")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(15)
                        
                        // Informazioni Account
                        VStack(spacing: 0) {
                            Text("Informazioni Account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 12)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Label("Email", systemImage: "envelope.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(authManager.currentUserEmail ?? "N/A")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                
                                HStack {
                                    Label("ID Utente", systemImage: "person.crop.square.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(authManager.currentUserID?.prefix(8).uppercased() ?? "N/A")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1.0)))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Impostazioni
                        VStack(spacing: 0) {
                            Text("Impostazioni")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 12)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            VStack(spacing: 0) {
                                VStack(spacing: 10) {
                                    HStack {
                                        Label("Notifiche", systemImage: "bell.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: .constant(true))
                                    }
                                    
                                    HStack {
                                        Label("Tema Scuro", systemImage: "moon.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: .constant(true))
                                    }
                                }
                                .padding(12)
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Pulsante Logout
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "door.left.hand.open")
                                Text("Esci")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(0.8),
                                        Color.red.opacity(0.6)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("SportPredix v1.0")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                            
                            Text("© 2026 SportPredix. All rights reserved.")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
        }
        .alert("Conferma Logout", isPresented: $showLogoutAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Esci", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Sei sicuro di voler uscire?")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
}