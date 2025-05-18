import Foundation
import Combine
import SwiftUI
import AudioToolbox

@MainActor
class NotificacaoViewModel: ObservableObject {
    @Published var medicamentoAtual: Medicamento?
    @Published var horarioAtual: Horario?
    @Published var mostrarTelaConfirmacao: Bool = false
    @Published var dataHorario: Date?

    private var timer: Timer?
    private var vibrationCount = 0
    private let maxVibrationCount = 30
    
    let notificacaoService: NotificacaoService
    private let persistenciaService: PersistenciaService
    private var cancellables = Set<AnyCancellable>()
    
    init(notificacaoService: NotificacaoService, persistenciaService: PersistenciaService) {
        self.notificacaoService = notificacaoService
        self.persistenciaService = persistenciaService

        NotificationCenter.default.publisher(for: Notification.Name("NotificacaoRecebida"))
            .sink { [weak self] notification in
                guard let self = self,
                    let userInfo = notification.userInfo,
                    let medicamentoID = userInfo["medicamentoID"] as? String,
                    let notificacaoID = userInfo["notificacaoID"] as? String,
                    let id = UUID(uuidString: medicamentoID) else {
                        return
                    }
        
        self.processarNotificacao(id: id, notificacaoID: notificacaoID)
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

            iniciarVibracaoContinua()
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

        pararVibracaoContinua()

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

        pararVibracaoContinua()

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

        pararVibracaoContinua()

        resetarEstado()
    }
    
    private func resetarEstado() {
        medicamentoAtual = nil
        horarioAtual = nil
        dataHorario = nil
        mostrarTelaConfirmacao = false
    }

    func iniciarVibracaoContinua() {
    // Parar qualquer timer existente
    pararVibracaoContinua()
    
    // Resetar contador
    vibrationCount = 0
    
    // Vibrar imediatamente
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    
    // Configurar timer para vibrar a cada 2 segundos
    timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
        guard let self = self else { return }
        
        // Usamos Task para voltar ao MainActor e acessar propriedades isoladas
        Task { @MainActor in
            // Verificar se atingimos o limite
            if self.vibrationCount < self.maxVibrationCount {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                self.vibrationCount += 1
            } else {
                // Chamada assíncrona ao método dentro do contexto do MainActor
                await self.pararVibracaoContinua()
            }
        }
    }
}

    @MainActor func pararVibracaoContinua() {
    timer?.invalidate()
    timer = nil
}
}