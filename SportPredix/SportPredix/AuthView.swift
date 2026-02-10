import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        ZStack {
            Color(UIColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1.0))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("SportPredix")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(isLoginMode ? "Accedi al tuo account" : "Crea un nuovo account")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Form
                VStack(spacing: 15) {
                    // Nome (solo per registrazione)
                    if !isLoginMode {
                        TextField("Nome completo", text: $name)
                            .textContentType(.name)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // Email
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    // Password
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    // Conferma Password (solo per registrazione)
                    if !isLoginMode {
                        SecureField("Conferma Password", text: $confirmPassword)
                            .textContentType(.password)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    // Messaggio di errore
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Pulsante principale
                Button(action: {
                    if isLoginMode {
                        authManager.login(email: email, password: password) { success in
                            if success {
                                email = ""
                                password = ""
                            }
                        }
                    } else {
                        if password != confirmPassword {
                            authManager.errorMessage = "Le password non coincidono"
                            return
                        }
                        if password.count < 6 {
                            authManager.errorMessage = "La password deve avere almeno 6 caratteri"
                            return
                        }
                        authManager.register(email: email, password: password, name: name) { success in
                            if success {
                                email = ""
                                password = ""
                                name = ""
                                confirmPassword = ""
                            }
                        }
                    }
                }) {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text(isLoginMode ? "Accedi" : "Registrati")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1.0)))
                .cornerRadius(10)
                .disabled(authManager.isLoading)
                .padding(.horizontal)
                
                // Toggle tra Login e Registrazione
                HStack(spacing: 5) {
                    Text(isLoginMode ? "Non hai un account?" : "Hai già un account?")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        isLoginMode.toggle()
                        authManager.errorMessage = nil
                        email = ""
                        password = ""
                        name = ""
                        confirmPassword = ""
                    }) {
                        Text(isLoginMode ? "Registrati" : "Accedi")
                            .foregroundColor(Color(UIColor(red: 0.2, green: 1.0, blue: 0.6, alpha: 1.0)))
                            .fontWeight(.bold)
                    }
                }
                .font(.system(size: 14))
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

#Preview {
    AuthView()
}