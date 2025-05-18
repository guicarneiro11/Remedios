import Foundation
import Combine
import SwiftUI

@MainActor
class HistoricoViewModel: ObservableObject {
    @Published var registros: [RegistroMedicacao] = []
    @Published var filtroPeriodo: FiltroPeriodo = .semana
    @Published var filtroMedicamento: UUID?
    @Published var dadosEstatisticas: EstatisticasAdesao = EstatisticasAdesao()
    
    private let persistenciaService: PersistenciaService
    private var cancellables = Set<AnyCancellable>()
    
    enum FiltroPeriodo: String, CaseIterable {
        case hoje = "Hoje"
        case semana = "Última semana"
        case mes = "Último mês"
        case todos = "Todos"
    }
    
    struct EstatisticasAdesao {
        var totalMedicamentos: Int = 0
        var medicamentosTomados: Int = 0
        var medicamentosIgnorados: Int = 0
        var medicamentosAdiados: Int = 0
        var taxaAdesao: Double = 0
        
        mutating func calcular(registros: [RegistroMedicacao]) {
            totalMedicamentos = registros.count
            medicamentosTomados = registros.filter { $0.status == .tomado }.count
            medicamentosIgnorados = registros.filter { $0.status == .ignorado }.count
            medicamentosAdiados = registros.filter { $0.status == .pendente && $0.adiado }.count
            
            if totalMedicamentos > 0 {
                taxaAdesao = Double(medicamentosTomados) / Double(totalMedicamentos) * 100
            } else {
                taxaAdesao = 0
            }
        }
    }
    
    init(persistenciaService: PersistenciaService) {
        self.persistenciaService = persistenciaService
        
        carregarRegistros()

        $filtroPeriodo
            .combineLatest($filtroMedicamento)
            .sink { [weak self] (periodo, medicamentoID) in
                self?.aplicarFiltros(periodo: periodo, medicamentoID: medicamentoID)
            }
            .store(in: &cancellables)
    }
    
    func carregarRegistros() {
        aplicarFiltros(periodo: filtroPeriodo, medicamentoID: filtroMedicamento)
    }
    
    private func aplicarFiltros(periodo: FiltroPeriodo, medicamentoID: UUID?) {
        let todosRegistros = persistenciaService.carregarHistorico()
        var registrosFiltrados = todosRegistros

        let hoje = Date()
        let calendar = Calendar.current
        
        switch periodo {
        case .hoje:
            registrosFiltrados = todosRegistros.filter { calendario -> Bool in
                calendar.isDateInToday(calendario.horarioProgramado)
            }
        case .semana:
            if let dataInicioSemana = calendar.date(byAdding: .day, value: -7, to: hoje) {
                registrosFiltrados = todosRegistros.filter { calendario -> Bool in
                    calendario.horarioProgramado >= dataInicioSemana
                }
            }
        case .mes:
            if let dataInicioMes = calendar.date(byAdding: .month, value: -1, to: hoje) {
                registrosFiltrados = todosRegistros.filter { calendario -> Bool in
                    calendario.horarioProgramado >= dataInicioMes
                }
            }
        case .todos:
            break
        }

        if let medicamentoID = medicamentoID {
            registrosFiltrados = registrosFiltrados.filter { $0.medicamentoID == medicamentoID }
        }

        registrosFiltrados.sort { $0.horarioProgramado > $1.horarioProgramado }

        self.registros = registrosFiltrados
        self.dadosEstatisticas.calcular(registros: registrosFiltrados)
    }
    
    func removerRegistro(_ registro: RegistroMedicacao) {
        var todosRegistros = persistenciaService.carregarHistorico()
        todosRegistros.removeAll { $0.id == registro.id }
        persistenciaService.salvarHistorico(todosRegistros)
        carregarRegistros()
    }
    
    func corStatusRegistro(_ status: RegistroMedicacao.StatusMedicacao) -> Color {
        switch status {
        case .tomado:
            return .green
        case .ignorado:
            return .red
        case .pendente:
            return .orange
        }
    }
}