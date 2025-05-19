import AudioToolbox
import Combine
import Foundation
import SwiftUI

@MainActor
class NotificacaoViewModel: ObservableObject {
    @Published var medicamentoAtual: Medicamento?
    @Published var horarioAtual: Horario?
    @Published var mostrarTelaConfirmacao: Bool = false
    @Published var dataHorario: Date?

    private var cancellables = Set<AnyCancellable>()

    let notificacaoService: NotificacaoService
    private let persistenciaService: PersistenciaService

    init(notificacaoService: NotificacaoService, persistenciaService: PersistenciaService) {
        self.notificacaoService = notificacaoService
        self.persistenciaService = persistenciaService
        print("NotificacaoViewModel inicializado")

        setupObservers()
    }

    private func setupObservers() {
        NotificacaoManager.shared.$medicamentoAtual
            .assign(to: &$medicamentoAtual)

        NotificacaoManager.shared.$horarioAtual
            .assign(to: &$horarioAtual)

        NotificacaoManager.shared.$mostrarTelaConfirmacao
            .assign(to: &$mostrarTelaConfirmacao)
    }

    func verificarNotificacoes() {
        print("Verificando notificações pendentes...")
        NotificacaoManager.shared.verificarNotificacoesPendentes()
    }

    func confirmarMedicamentoTomado() {
        NotificacaoManager.shared.confirmarMedicamentoTomado()
    }

    func adiarMedicamento() {
        NotificacaoManager.shared.adiarMedicamento()
    }

    func ignorarMedicamento() {
        NotificacaoManager.shared.ignorarMedicamento()
    }
}
