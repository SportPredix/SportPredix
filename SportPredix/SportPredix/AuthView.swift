import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @AppStorage("profileSelectedTheme") private var selectedTheme = "Sistema"
    
    var body: some View {
        ZStack {
            authBackground
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    formCard
                    primaryButton
                    toggleRow
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var preferredColorScheme: ColorScheme? {
        switch selectedTheme {
        case "Chiaro":
            return .light
        case "Scuro":
            return .dark
        default:
            return nil
        }
    }
    
    private var authBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.06, green: 0.07, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentCyan.opacity(0.35),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 20,
                endRadius: 300
            )
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentCyan.opacity(0.25),
                    Color.clear
                ]),
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("SportPredix")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            Text(isLoginMode ? "Accedi al tuo account" : "Crea un nuovo account")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Capsule()
                .fill(Color.accentCyan.opacity(0.6))
                .frame(width: 60, height: 3)
        }
    }
    
    private var formCard: some View {
        VStack(spacing: 14) {
            if !isLoginMode {
                fieldRow(
                    icon: "person.fill",
                    placeholder: "Nome completo",
                    text: $name,
                    contentType: .name,
                    capitalization: .words
                )
            }
            
            fieldRow(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboard: .emailAddress,
                contentType: .emailAddress,
                capitalization: .never
            )
            
            fieldRow(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                contentType: .password,
                capitalization: .never,
                isSecure: true
            )
            
            if !isLoginMode {
                fieldRow(
                    icon: "lock.shield",
                    placeholder: "Conferma password",
                    text: $confirmPassword,
                    contentType: .password,
                    capitalization: .never,
                    isSecure: true
                )
            }
            
            if let error = authManager.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.red.opacity(0.12))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.accentCyan.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 14, x: 0, y: 8)
    }
    
    private var primaryButton: some View {
        Button(action: handlePrimaryAction) {
            HStack(spacing: 8) {
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
            .frame(height: 54)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentCyan,
                        Color.accentCyan.opacity(0.7),
                        Color.blue.opacity(0.6)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.accentCyan.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .disabled(authManager.isLoading)
    }
    
    private var toggleRow: some View {
        HStack(spacing: 6) {
            Text(isLoginMode ? "Non hai un account?" : "Hai gia un account?")
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
                    .foregroundColor(.accentCyan)
                    .fontWeight(.bold)
            }
        }
        .font(.footnote)
    }
    
    private func handlePrimaryAction() {
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
    }
    
    private func fieldRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        capitalization: TextInputAutocapitalization = .sentences,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentCyan)
                .frame(width: 18)
            
            if isSecure {
                SecureField(placeholder, text: text)
                    .textContentType(contentType)
                    .textInputAutocapitalization(capitalization)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .textInputAutocapitalization(capitalization)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.07))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager.shared)
}
