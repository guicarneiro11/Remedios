import Combine
import SwiftUI

struct NotificacaoObserver: View {
    @State private var mostrarNotificacao = false
    @State private var cancellable: AnyCancellable?
    @State private var medicamentoAtual: Medicamento?
    @State private var horarioAtual: Horario?

    var body: some View {
        ZStack {
            // View vazia que apenas observa as notificações
            EmptyView()

            // Mostrar tela de confirmação quando necessário
            if mostrarNotificacao, let medicamento = medicamentoAtual {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                ConfirmacaoView(medicamento: medicamento)
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }
        }
        .onAppear {
            // Começa a observar mudanças no NotificacaoManager
            setupObserver()
        }
    }

    private func setupObserver() {
        // Observar as mudanças no NotificacaoManager.shared.mostrarTelaConfirmacao
        cancellable = NotificacaoManager.shared.$mostrarTelaConfirmacao
            .combineLatest(
                NotificacaoManager.shared.$medicamentoAtual, NotificacaoManager.shared.$horarioAtual
            )
            .receive(on: DispatchQueue.main)
            .sink { mostrar, medicamento, horario in
                self.mostrarNotificacao = mostrar
                self.medicamentoAtual = medicamento
                self.horarioAtual = horario

                print("NotificacaoObserver: mostrarNotificacao=\(mostrar)")
            }
    }
}

struct ConfirmacaoView: View {
    let medicamento: Medicamento

    var body: some View {
        VStack(spacing: 24) {
            // Cabeçalho
            Image(systemName: "pill.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .scaleEffect(1.2)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: 1.2
                )

            Text("Hora do Medicamento!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Detalhes do medicamento
            VStack(spacing: 12) {
                Text(medicamento.nome)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Tipo: \(medicamento.tipo.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                if let nota = medicamento.notas, !nota.isEmpty {
                    Text("Nota: \(nota)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)

            Spacer()

            // Botões de ação
            VStack(spacing: 16) {
                Button(action: {
                    NotificacaoManager.shared.confirmarMedicamentoTomado()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)

                        Text("Confirmar")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }

                Button(action: {
                    NotificacaoManager.shared.adiarMedicamento()
                }) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.headline)

                        Text("Adiar 3 minutos")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }

                Button(action: {
                    NotificacaoManager.shared.ignorarMedicamento()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)

                        Text("Ignorar")
                            .font(.headline)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .padding(.top, 50)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            // Impedir que a tela se desligue
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // Permitir que a tela se desligue novamente
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
