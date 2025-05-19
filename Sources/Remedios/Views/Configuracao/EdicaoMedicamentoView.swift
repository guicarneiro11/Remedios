import SwiftUI

struct EdicaoMedicamentoView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var medicamentoViewModel: MedicamentoViewModel
    @State private var nome: String
    @State private var tipo: TipoMedicamento
    @State private var horarios: [Horario]
    @State private var notas: String
    @State private var nomeTitulo: String
    private let medicamentoID: UUID

    init(medicamento: Medicamento) {
        self.medicamentoID = medicamento.id
        _nome = State(initialValue: medicamento.nome)
        _tipo = State(initialValue: medicamento.tipo)
        _horarios = State(initialValue: medicamento.horarios)
        _notas = State(initialValue: medicamento.notas ?? "")
        _nomeTitulo = State(initialValue: medicamento.nomeTitulo ?? "")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text("Editar Medicamento")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        salvarAlteracoes()
                    }) {
                        Text("Salvar")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nome do medicamento")
                                .font(.headline)
                                .foregroundColor(.white)

                            TextField("", text: $nome)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tipo do medicamento")
                                .font(.headline)
                                .foregroundColor(.white)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TipoMedicamento.allCases) { tipoItem in
                                        TipoMedicamentoButton(
                                            tipo: tipoItem,
                                            selecionado: tipo == tipoItem,
                                            action: { tipo = tipoItem }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Horários")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            ForEach(horarios) { horario in
                                HorarioEditItem(horario: horario) {
                                    self.horarios.removeAll { $0.id == horario.id }
                                }
                                .padding(.horizontal)
                            }

                            Button(action: {
                                adicionarNovoHorario()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Adicionar horário")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detalhes adicionais")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nome para notificação (opcional)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("", text: $nomeTitulo)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notas (opcional)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))

                                TextEditor(text: $notas)
                                    .frame(minHeight: 100)
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
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .alert(isPresented: $medicamentoViewModel.mostrarErro) {
            Alert(
                title: Text("Erro"),
                message: Text(medicamentoViewModel.mensagemErro),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func salvarAlteracoes() {
        if nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            medicamentoViewModel.mostrarErro = true
            medicamentoViewModel.mensagemErro = "O nome do medicamento não pode ficar em branco."
            return
        }

        if horarios.isEmpty {
            medicamentoViewModel.mostrarErro = true
            medicamentoViewModel.mensagemErro = "Adicione pelo menos um horário."
            return
        }

        if var medicamento = medicamentoViewModel.medicamentos.first(where: {
            $0.id == medicamentoID
        }) {
            medicamento.nome = nome
            medicamento.tipo = tipo
            medicamento.horarios = horarios
            medicamento.notas = notas.isEmpty ? nil : notas
            medicamento.nomeTitulo = nomeTitulo.isEmpty ? nil : nomeTitulo

            medicamentoViewModel.atualizarMedicamento(medicamento)
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func adicionarNovoHorario() {
        let novoHorario = Horario(
            hora: Date(),
            frequencia: .diaria,
            diasSemana: nil,
            intervaloDias: nil,
            ciclosDias: nil
        )
        horarios.append(novoHorario)
    }
}

struct TipoMedicamentoButton: View {
    let tipo: TipoMedicamento
    let selecionado: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconeTipo(tipo))
                    .font(.title2)

                Text(tipo.rawValue)
                    .font(.caption)
            }
            .padding()
            .frame(minWidth: 100)
            .background(selecionado ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(10)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selecionado ? Color.white : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func iconeTipo(_ tipo: TipoMedicamento) -> String {
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
        case .po:
            return "powerplugs.fill"
        default:
            return "cross.case.fill"
        }
    }
}

struct HorarioEditItem: View {
    let horario: Horario
    let onRemove: () -> Void
    @State private var showingDatePicker = false
    @State private var selectedTime = Date()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    selectedTime = horario.hora
                    showingDatePicker.toggle()
                }) {
                    Text(formatarHorario(horario.hora))
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text(descricaoFrequencia(horario))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red.opacity(0.8))
                    .padding(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker(
                    "Selecione o horário",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()

                Button("Confirmar") {
                    showingDatePicker = false
                }
                .padding()
            }
        }
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
