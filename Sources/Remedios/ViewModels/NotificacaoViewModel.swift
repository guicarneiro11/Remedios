import Foundation
import Combine
import SwiftUI

@MainActor
class NotificacaoViewModel: ObservableObject {
    @Published var medicamentoAtual: Medicamento?
    @Published var horarioAtual: Horario?
    @Published var mostrarTelaConfirmacao: Bool = false
    @Published var dataHorario: Date?
    
    let notificacaoService: NotificacaoService
    private let persistenciaService: PersistenciaService
    private var cancellables = Set<AnyCancellable>()
    
    init(notificacaoService: NotificacaoService, persistenciaService: PersistenciaService) {
        self.notificacaoService = notificacaoService
        self.persistenciaService = persistenciaService

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.verificarNotificacoes()
            }
            .store(in: &cancellables)
    }
    
    func verificarNotificacoes() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notificacoes in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let notificacao = notificacoes.first {
                    if let medicamentoID = notificacao.request.content.userInfo["medicamentoID"] as? String,
                       let id = UUID(uuidString: medicamentoID) {
                        self.processarNotificacao(id: id, notificacaoID: notificacao.request.identifier)
                    }
                }
            }
        }
    }
    
    func processarNotificacao(id: UUID, notificacaoID: String) {
        let medicamentos = persistenciaService.carregarMedicamentos()
        
        if let medicamento = medicamentos.first(where: { $0.id == id }),
           let horario = medicamento.horarios.first(where: { $0.notificacaoID == notificacaoID }) {
            self.medicamentoAtual = medicamento
            self.horarioAtual = horario
            self.dataHorario = Date()
            self.mostrarTelaConfirmacao = true
        }
    }
    
    func confirmarMedicamentoTomado() {
        guard let medicamento = medicamentoAtual,
              let horario = horarioAtual,
              let _ = dataHorario else {
            return
        }

        let registro = RegistroMedicacao(
            medicamentoID: medicamento.id,
            nomeMedicamento: medicamento.nome,
            horarioProgramado: horario.hora,
            horarioTomado: Date(),
            status: .tomado,
            adiado: false
        )
        
        persistenciaService.adicionarRegistro(registro)

        resetarEstado()
    }
    
    func adiarMedicamento() {
        guard let medicamento = medicamentoAtual,
              let horario = horarioAtual,
              let _ = dataHorario else {
            return
        }

        let registro = RegistroMedicacao(
            medicamentoID: medicamento.id,
            nomeMedicamento: medicamento.nome,
            horarioProgramado: horario.hora,
            horarioTomado: nil,
            status: .pendente,
            adiado: true
        )
        
        persistenciaService.adicionarRegistro(registro)

        _ = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
        let conteudo = UNMutableNotificationContent()
        conteudo.title = "Lembrete para tomar seu medicamento"
        conteudo.body = "Não esqueça de tomar \(medicamento.nome)"
        conteudo.sound = .default
        conteudo.userInfo = ["medicamentoID": medicamento.id.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "lembrete-\(UUID().uuidString)",
            content: conteudo,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)

        resetarEstado()
    }
    
    func ignorarMedicamento() {
        guard let medicamento = medicamentoAtual,
              let horario = horarioAtual,
              let _ = dataHorario else {
            return
        }

        let registro = RegistroMedicacao(
            medicamentoID: medicamento.id,
            nomeMedicamento: medicamento.nome,
            horarioProgramado: horario.hora,
            horarioTomado: nil,
            status: .ignorado,
            adiado: false
        )
        
        persistenciaService.adicionarRegistro(registro)

        resetarEstado()
    }
    
    private func resetarEstado() {
        medicamentoAtual = nil
        horarioAtual = nil
        dataHorario = nil
        mostrarTelaConfirmacao = false
    }
}