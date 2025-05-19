import SwiftUI

struct ListaMedicamentosView: View {
    @EnvironmentObject var medicamentoViewModel: MedicamentoViewModel
    @EnvironmentObject var notificacaoViewModel: NotificacaoViewModel
    @State private var medicamentoSelecionado: Medicamento?
    @State private var mostrarDetalhesMedicamento = false

    var body: some View {
        VStack {
            if medicamentoViewModel.medicamentos.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "pill.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Nenhum medicamento configurado")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Toque no botão + para adicionar um novo medicamento")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
            } else {
                ZStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(medicamentoViewModel.medicamentos) { medicamento in
                                MedicamentoCardView(medicamento: medicamento) {
                                    notificacaoViewModel.mostrarTelaConfirmacao = false

                                    medicamentoSelecionado = medicamento
                                    mostrarDetalhesMedicamento = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }

                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 60)
                            .allowsHitTesting(false)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .fullScreenCover(isPresented: $mostrarDetalhesMedicamento) {
            if let medicamento = medicamentoSelecionado {
                DetalhesMedicamentoView(medicamento: medicamento)
            }
        }
    }
}

struct MedicamentoCardView: View {
    let medicamento: Medicamento
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(medicamento.nome)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: iconeMedicamento(tipo: medicamento.tipo))
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                Text("Próxima dose: \(proximaDoseFormatada())")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text("Tipo: \(medicamento.tipo.rawValue)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack {
                    ForEach(medicamento.horarios.prefix(3)) { horario in
                        Text(formatarHorario(horario.hora))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }

                    if medicamento.horarios.count > 3 {
                        Text("+\(medicamento.horarios.count - 3)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func iconeMedicamento(tipo: TipoMedicamento) -> String {
        switch tipo {
        case .capsula:
            return "pill.fill"
        case .comprimido:
            return "pill"
        case .liquido:
            return "drop.fill"
        case .topico:
            return "hand.raised.fill"
        case .inalador:
            return "lungs.fill"
        case .injecao:
            return "syringe"
        default:
            return "cross.case.fill"
        }
    }

    private func proximaDoseFormatada() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let proximaHora = medicamento.horarios.first?.hora else {
            return "Não definida"
        }

        return formatter.string(from: proximaHora)
    }

    private func formatarHorario(_ data: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: data)
    }
}
