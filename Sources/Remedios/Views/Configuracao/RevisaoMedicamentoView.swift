import SwiftUI

struct RevisaoMedicamentoView: View {
    @ObservedObject var viewModel: MedicamentoViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Revisão")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 24) {
                    RevisaoItemView(
                        titulo: "Nome",
                        valor: viewModel.nome,
                        icone: "pill.fill"
                    )

                    RevisaoItemView(
                        titulo: "Tipo",
                        valor: viewModel.tipo.rawValue,
                        icone: "cross.case.fill"
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Horários")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack(spacing: 10) {
                            ForEach(viewModel.horarios) { horario in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(formatarHorario(horario.hora))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text(descricaoFrequencia(horario))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                    VStack(spacing: 16) {
                        TextField("Nome para a notificação (opcional)", text: $viewModel.nomeTitulo)
                            .font(.subheadline)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        TextField("Notas adicionais (opcional)", text: $viewModel.notas)
                            .font(.subheadline)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 20)
            }
            
            Button(action: {
                viewModel.salvarMedicamento()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Salvar Medicamento")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func formatarHorario(_ data: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: data)
    }
    
    private func descricaoFrequencia(_ horario: Horario) -> String {
        switch horario.frequencia {
        case .diaria:
            return "Todos os dias"
        case .diasEspecificos:
            guard let dias = horario.diasSemana else { return "Dias específicos" }
            let nomesDias = dias.map { diaDaSemana($0) }.joined(separator: ", ")
            return "Nos dias: \(nomesDias)"
        case .intervalos:
            guard let intervalo = horario.intervaloDias else { return "Intervalos" }
            return "A cada \(intervalo) dia(s)"
        case .ciclos:
            guard let ciclo = horario.ciclosDias else { return "Ciclos" }
            return "\(ciclo.ativo) dia(s) on, \(ciclo.descanso) dia(s) off"
        case .esporadico:
            return "Uso esporádico"
        }
    }
    
    private func diaDaSemana(_ dia: Int) -> String {
        let dias = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
        guard dia >= 1, dia <= 7 else { return "" }
        return dias[dia - 1]
    }
}

struct RevisaoItemView: View {
    let titulo: String
    let valor: String
    let icone: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icone)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(titulo)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(valor)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}