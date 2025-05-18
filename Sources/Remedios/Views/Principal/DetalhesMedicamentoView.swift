import SwiftUI

struct DetalhesMedicamentoView: View {
    let medicamento: Medicamento
    @StateObject private var historicoViewModel: HistoricoViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var medicamentoViewModel: MedicamentoViewModel
    @State private var mostrarAlertaExclusao = false
    @State private var mostrarEdicao = false
    
    init(medicamento: Medicamento) {
        self.medicamento = medicamento
        _historicoViewModel = StateObject(wrappedValue: HistoricoViewModel(persistenciaService: PersistenciaService()))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Image(systemName: iconeMedicamento(tipo: medicamento.tipo))
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text(medicamento.nome)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(medicamento.tipo.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Horários")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(medicamento.horarios) { horario in
                            HorarioDetalheView(horario: horario)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)

                    if let notas = medicamento.notas, !notas.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notas")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(notas)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Histórico recente")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if historicoViewModel.registros.isEmpty {
                            Text("Nenhum registro encontrado para este medicamento")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        } else {
                            ForEach(historicoViewModel.registros.prefix(5)) { registro in
                                RegistroMedicacaoView(registro: registro, viewModel: historicoViewModel)
                            }
                            
                            if historicoViewModel.registros.count > 5 {
                                Button(action: {
                                }) {
                                    Text("Ver todos os registros")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)

                    VStack(spacing: 12) {
                        Button(action: {
                            mostrarEdicao = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.headline)
                                
                                Text("Editar medicamento")
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
                            mostrarAlertaExclusao = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.headline)
                                
                                Text("Excluir medicamento")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
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
                }
                .padding()
            }

            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .alert(isPresented: $mostrarAlertaExclusao) {
            Alert(
                title: Text("Excluir medicamento"),
                message: Text("Tem certeza que deseja excluir \(medicamento.nome)? Esta ação não pode ser desfeita."),
                primaryButton: .destructive(Text("Excluir")) {
                    medicamentoViewModel.excluirMedicamento(medicamento)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
        .sheet(isPresented: $mostrarEdicao) {
            NavigationView {
                Text("Tela de edição - A ser implementada")
                    .navigationTitle("Editar medicamento")
                    .navigationBarItems(trailing: Button("Fechar") {
                        mostrarEdicao = false
                    })
            }
        }
        .onAppear {
            historicoViewModel.filtroMedicamento = medicamento.id
            historicoViewModel.carregarRegistros()
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
}

struct HorarioDetalheView: View {
    let horario: Horario
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatarHorario(horario.hora))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(descricaoFrequencia(horario))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "clock.fill")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func formatarHorario(_ data: Date) -> String {
        return data.formatarHora()
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