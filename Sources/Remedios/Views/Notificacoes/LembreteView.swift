import SwiftUI

struct LembreteView: View {
    let titulo: String
    let mensagem: String
    let icone: String
    let acaoPrimaria: () -> Void
    let acaoSecundaria: (() -> Void)?
    let textoBotaoPrimario: String
    let textoBotaoSecundario: String?
    @State private var animationAmount: Double = 1.0
    
    init(
        titulo: String,
        mensagem: String,
        icone: String = "bell.fill",
        textoBotaoPrimario: String = "OK",
        textoBotaoSecundario: String? = nil,
        acaoPrimaria: @escaping () -> Void = {},
        acaoSecundaria: (() -> Void)? = nil
    ) {
        self.titulo = titulo
        self.mensagem = mensagem
        self.icone = icone
        self.textoBotaoPrimario = textoBotaoPrimario
        self.textoBotaoSecundario = textoBotaoSecundario
        self.acaoPrimaria = acaoPrimaria
        self.acaoSecundaria = acaoSecundaria
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icone)
                .font(.system(size: 50))
                .foregroundColor(.white)
                .scaleEffect(animationAmount)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: animationAmount
                )
                .onAppear {
                    animationAmount = 1.2
                }

            Text(titulo)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(mensagem)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                if let textoBotaoSecundario = textoBotaoSecundario, let acaoSecundaria = acaoSecundaria {
                    Button(action: acaoSecundaria) {
                        Text(textoBotaoSecundario)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                Button(action: acaoPrimaria) {
                    Text(textoBotaoPrimario)
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding()
    }
}