import SwiftUI

struct HorarioMedicamentoView: View {
    @ObservedObject var viewModel: MedicamentoViewModel
    @State private var mostrarAdicionarHorario = false
    @State private var novoHorario = Date()
    @State private var frequenciaSelecionada: FrequenciaMedicamento = .diaria
    @State private var diasSelecionados: [Int] = []
    @State private var intervaloDias: Int = 1
    @State private var cicloDiasAtivo: Int = 1
    @State private var cicloDiasDescanso: Int = 1
    
    let diasSemana = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quando tomar o medicamento?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            
            if viewModel.horarios.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Nenhum horário configurado")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.horarios) { horario in
                            HorarioItemView(horario: horario) {
                                viewModel.horarios.removeAll { $0.id == horario.id }
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                mostrarAdicionarHorario = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    
                    Text("Adicionar horário")
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
            
            Spacer()
            
            Button(action: {
                viewModel.avancarEtapa()
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            .opacity(viewModel.horarios.isEmpty ? 0.5 : 1.0)
            .disabled(viewModel.horarios.isEmpty)
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
        .sheet(isPresented: $mostrarAdicionarHorario) {
            AdicionarHorarioView(
                isPresented: $mostrarAdicionarHorario,
                horarios: $viewModel.horarios,
                horario: $novoHorario,
                frequencia: $frequenciaSelecionada,
                diasSelecionados: $diasSelecionados,
                intervaloDias: $intervaloDias,
                cicloDiasAtivo: $cicloDiasAtivo,
                cicloDiasDescanso: $cicloDiasDescanso
            )
        }
    }
}

struct HorarioItemView: View {
    let horario: Horario
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatarHorario(horario.hora))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(descricaoFrequencia(horario))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash.fill")
                    .font(.headline)
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding(8)
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

struct AdicionarHorarioView: View {
    @Binding var isPresented: Bool
    @Binding var horarios: [Horario]
    @Binding var horario: Date
    @Binding var frequencia: FrequenciaMedicamento
    @Binding var diasSelecionados: [Int]
    @Binding var intervaloDias: Int
    @Binding var cicloDiasAtivo: Int
    @Binding var cicloDiasDescanso: Int
    
    let diasSemana = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Horário")) {
                    DatePicker("Hora", selection: $horario, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Frequência")) {
                    Picker("Frequência", selection: $frequencia) {
                        ForEach(FrequenciaMedicamento.allCases, id: \.self) { tipo in
                            Text(tipo.rawValue).tag(tipo)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                switch frequencia {
                case .diasEspecificos:
                    Section(header: Text("Selecione os dias")) {
                        ForEach(0..<7) { index in
                            Button(action: {
                                if diasSelecionados.contains(index + 1) {
                                    diasSelecionados.removeAll { $0 == index + 1 }
                                } else {
                                    diasSelecionados.append(index + 1)
                                }
                            }) {
                                HStack {
                                    Text(diasSemana[index])
                                    Spacer()
                                    if diasSelecionados.contains(index + 1) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                case .intervalos:
                    Section(header: Text("Intervalo de dias")) {
                        Stepper("A cada \(intervaloDias) dia(s)", value: $intervaloDias, in: 1...30)
                    }
                case .ciclos:
                    Section(header: Text("Configurar ciclo")) {
                        Stepper("\(cicloDiasAtivo) dia(s) ativos", value: $cicloDiasAtivo, in: 1...90)
                        Stepper("\(cicloDiasDescanso) dia(s) de descanso", value: $cicloDiasDescanso, in: 1...90)
                    }
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Adicionar horário")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let novoHorario = criarHorario()
                        horarios.append(novoHorario)
                        resetarCampos()
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func criarHorario() -> Horario {
        var novoHorario = Horario(hora: horario, frequencia: frequencia, diasSemana: nil, intervaloDias: nil, ciclosDias: nil)
        
        switch frequencia {
        case .diasEspecificos:
            novoHorario.diasSemana = diasSelecionados.isEmpty ? [Calendar.current.component(.weekday, from: Date())] : diasSelecionados
        case .intervalos:
            novoHorario.intervaloDias = intervaloDias
        case .ciclos:
    novoHorario.ciclosDias = CicloMedicamento(ativo: cicloDiasAtivo, descanso: cicloDiasDescanso)
        default:
            break
        }
        
        return novoHorario
    }
    
    private func resetarCampos() {
        diasSelecionados = []
        intervaloDias = 1
        cicloDiasAtivo = 1
        cicloDiasDescanso = 1
    }
}

extension FrequenciaMedicamento: CaseIterable {
    static var allCases: [FrequenciaMedicamento] {
        return [.diaria, .diasEspecificos, .intervalos, .ciclos, .esporadico]
    }
}