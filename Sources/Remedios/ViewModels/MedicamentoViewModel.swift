import Foundation
import Combine
import SwiftUI

@MainActor
class MedicamentoViewModel: ObservableObject {
    @Published var nome: String = ""
    @Published var tipo: TipoMedicamento = .comprimido
    @Published var horarios: [Horario] = []
    @Published var notas: String = ""
    @Published var nomeTitulo: String = ""

    @Published var medicamentos: [Medicamento] = []
    @Published var medicamentoSelecionado: Medicamento?

    @Published var etapaConfiguracao: Int = 1
    @Published var mostrarErro: Bool = false
    @Published var mensagemErro: String = ""
    
    private let persistenciaService: PersistenciaService
    private let notificacaoService: NotificacaoService
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenciaService: PersistenciaService, notificacaoService: NotificacaoService) {
        self.persistenciaService = persistenciaService
        self.notificacaoService = notificacaoService
        
        carregarMedicamentos()
    }
    
    func avancarEtapa() {
        if validarEtapaAtual() {
            etapaConfiguracao += 1
        }
    }
    
    func voltarEtapa() {
        if etapaConfiguracao > 1 {
            etapaConfiguracao -= 1
        }
    }
    
    func salvarMedicamento() {
        guard validarTodasEtapas() else { return }
        
        let novoMedicamento = Medicamento(
            nome: nome,
            tipo: tipo,
            horarios: horarios,
            notas: notas.isEmpty ? nil : notas,
            nomeTitulo: nomeTitulo.isEmpty ? nil : nomeTitulo,
            dataCriacao: Date()
        )

        medicamentos.append(novoMedicamento)
        persistenciaService.salvarMedicamentos(medicamentos)

        agendarNotificacoes(para: novoMedicamento)

        resetarFormulario()
    }
    
    func editarMedicamento(_ medicamento: Medicamento) {
        medicamentoSelecionado = medicamento
        nome = medicamento.nome
        tipo = medicamento.tipo
        horarios = medicamento.horarios
        notas = medicamento.notas ?? ""
        nomeTitulo = medicamento.nomeTitulo ?? ""
        etapaConfiguracao = 1
    }
    
    func excluirMedicamento(_ medicamento: Medicamento) {
        for horario in medicamento.horarios {
            notificacaoService.cancelarNotificacao(identificador: horario.notificacaoID)
        }

        medicamentos.removeAll { $0.id == medicamento.id }
        persistenciaService.salvarMedicamentos(medicamentos)
    }

    
    private func validarEtapaAtual() -> Bool {
        switch etapaConfiguracao {
        case 1:
            if nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                mostrarErro = true
                mensagemErro = "Por favor, informe o nome do medicamento."
                return false
            }
        case 2:
            return true
        case 3:
            if horarios.isEmpty {
                mostrarErro = true
                mensagemErro = "Por favor, adicione pelo menos um horário."
                return false
            }
        default:
            break
        }
        
        mostrarErro = false
        return true
    }
    
    private func validarTodasEtapas() -> Bool {
        if nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mostrarErro = true
            mensagemErro = "Por favor, informe o nome do medicamento."
            etapaConfiguracao = 1
            return false
        }
        
        if horarios.isEmpty {
            mostrarErro = true
            mensagemErro = "Por favor, adicione pelo menos um horário."
            etapaConfiguracao = 3
            return false
        }
        
        mostrarErro = false
        return true
    }
    
    private func resetarFormulario() {
        nome = ""
        tipo = .comprimido
        horarios = []
        notas = ""
        nomeTitulo = ""
        etapaConfiguracao = 1
        medicamentoSelecionado = nil
    }
    
    private func carregarMedicamentos() {
        medicamentos = persistenciaService.carregarMedicamentos()
    }
    
    private func agendarNotificacoes(para medicamento: Medicamento) {
        for horario in medicamento.horarios {
            notificacaoService.agendarNotificacao(
                titulo: medicamento.nomeTitulo ?? "Hora de tomar seu medicamento",
                corpo: "Está na hora de tomar \(medicamento.nome)",
                horario: horario,
                medicamentoID: medicamento.id
            )
        }
    }
}