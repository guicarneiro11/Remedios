import SwiftUI

struct HistoricoView: View {
    @EnvironmentObject var medicamentoViewModel: MedicamentoViewModel
    @StateObject private var viewModel: HistoricoViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue: HistoricoViewModel(persistenciaService: PersistenciaService()))
    }

    var body: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HistoricoViewModel.FiltroPeriodo.allCases, id: \.self) { periodo in
                        Button(action: {
                            viewModel.filtroPeriodo = periodo
                        }) {
                            Text(periodo.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.filtroPeriodo == periodo
                                        ? Color.white : Color.white.opacity(0.1)
                                )
                                .foregroundColor(
                                    viewModel.filtroPeriodo == periodo ? .black : .white
                                )
                                .cornerRadius(20)
                        }
                    }

                    Divider()
                        .frame(height: 24)
                        .background(Color.white.opacity(0.3))

                    Menu {
                        Button("Todos os medicamentos") {
                            viewModel.filtroMedicamento = nil
                        }

                        ForEach(medicamentoViewModel.medicamentos) { medicamento in
                            Button(medicamento.nome) {
                                viewModel.filtroMedicamento = medicamento.id
                            }
                        }
                    } label: {
                        HStack {
                            Text(nomeMedicamentoFiltrado())
                                .font(.caption)

                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Taxa de adesão")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(String(format: "%.1f%%", viewModel.dadosEstatisticas.taxaAdesao))
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ProgressBar(value: viewModel.dadosEstatisticas.taxaAdesao / 100)
                    .frame(height: 8)

                HStack(spacing: 16) {
                    EstatisticaItem(
                        valor: viewModel.dadosEstatisticas.medicamentosTomados,
                        label: "Tomados",
                        cor: .green
                    )

                    EstatisticaItem(
                        valor: viewModel.dadosEstatisticas.medicamentosAdiados,
                        label: "Adiados",
                        cor: .orange
                    )

                    EstatisticaItem(
                        valor: viewModel.dadosEstatisticas.medicamentosIgnorados,
                        label: "Ignorados",
                        cor: .red
                    )
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)

            if viewModel.registros.isEmpty {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Nenhum registro encontrado")
                        .font(.title3)
                        .foregroundColor(.white)

                    Text("Os registros aparecerão aqui quando você tomar seus medicamentos")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            } else {
                ZStack {
                    List {
                        ForEach(agruparRegistrosPorData().keys.sorted(by: >), id: \.self) { data in
                            Section(header: Text(formatarDataSecao(data)).foregroundColor(.white)) {
                                ForEach(agruparRegistrosPorData()[data] ?? []) { registro in
                                    RegistroMedicacaoView(registro: registro, viewModel: viewModel)
                                        .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)

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
        .onAppear {
            viewModel.carregarRegistros()
        }
        .padding(.bottom, 60)
    }

    private func nomeMedicamentoFiltrado() -> String {
        if let id = viewModel.filtroMedicamento,
            let medicamento = medicamentoViewModel.medicamentos.first(where: { $0.id == id })
        {
            return medicamento.nome
        }
        return "Todos"
    }

    private func agruparRegistrosPorData() -> [Date: [RegistroMedicacao]] {
        let calendar = Calendar.current
        var registrosPorData: [Date: [RegistroMedicacao]] = [:]

        for registro in viewModel.registros {
            let componentes = calendar.dateComponents(
                [.year, .month, .day], from: registro.horarioProgramado)
            if let data = calendar.date(from: componentes) {
                if registrosPorData[data] == nil {
                    registrosPorData[data] = []
                }
                registrosPorData[data]?.append(registro)
            }
        }

        return registrosPorData
    }

    private func formatarDataSecao(_ data: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(data) {
            return "Hoje"
        } else if calendar.isDateInYesterday(data) {
            return "Ontem"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: data)
        }
    }
}

struct ProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.gray)

                Rectangle()
                    .frame(
                        width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width),
                        height: geometry.size.height
                    )
                    .foregroundColor(corBarraProgresso(value: self.value))
            }
            .cornerRadius(45)
        }
    }

    private func corBarraProgresso(value: Double) -> Color {
        if value < 0.4 {
            return .red
        } else if value < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

struct EstatisticaItem: View {
    var valor: Int
    var label: String
    var cor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(valor)")
                .font(.headline)
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(cor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RegistroMedicacaoView: View {
    let registro: RegistroMedicacao
    @ObservedObject var viewModel: HistoricoViewModel

    var body: some View {
        HStack {
            Circle()
                .frame(width: 12, height: 12)
                .foregroundColor(viewModel.corStatusRegistro(registro.status))

            VStack(alignment: .leading, spacing: 4) {
                Text(registro.nomeMedicamento)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack {
                    Text("Horário: \(registro.horarioProgramado.formatarHora())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    if let horarioTomado = registro.horarioTomado {
                        Text("Tomado: \(horarioTomado.formatarHora())")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            Spacer()

            Text(textoStatus())
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(viewModel.corStatusRegistro(registro.status).opacity(0.2))
                .foregroundColor(viewModel.corStatusRegistro(registro.status))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }

    private func textoStatus() -> String {
        switch registro.status {
        case .tomado:
            return "Tomou"
        case .ignorado:
            return "Ignorou"
        case .pendente:
            return registro.adiado ? "Adiou" : "Pendente"
        }
    }
}
