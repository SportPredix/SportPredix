import SwiftUI

struct ProfileView: View {

    @Binding var userName: String
    @Binding var balance: Double

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {

                Text("Profilo Utente")
                    .font(.largeTitle.bold())
                    .foregroundColor(.accentCyan)

                VStack(alignment: .leading, spacing: 12) {

                    Text("Nome utente")
                        .foregroundColor(.white.opacity(0.7))

                    TextField("Inserisci nome", text: $userName)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    Text("Saldo attuale: €\(balance, specifier: "%.2f")")
                        .foregroundColor(.accentCyan)
                        .font(.headline)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer()
            }
            .padding()
        }
    }
}