import SwiftUI

struct ConfirmacaoMedicamentoView: View {
    @EnvironmentObject var notificacaoViewModel: NotificacaoViewModel
    @State private var animationAmount: Double = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "pill.fill")
                    .font(.system(size: 80))
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

                Text("Hora do Medicamento!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if let medicamento = notificacaoViewModel.medicamentoAtual {
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
                }
                
                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        notificacaoViewModel.confirmarMedicamentoTomado()
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
                        notificacaoViewModel.adiarMedicamento()
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.headline)
                            
                            Text("Adiar 10 minutos")
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
                        notificacaoViewModel.ignorarMedicamento()
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
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}