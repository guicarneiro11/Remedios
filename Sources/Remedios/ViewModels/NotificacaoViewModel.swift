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

    private var timer: Timer?
    private var vibrationCount = 0
    private let maxVibrationCount = 30

    let notificacaoService: NotificacaoService
    private let persistenciaService: PersistenciaService
    private var cancellables = Set<AnyCancellable>()

    init(notificacaoService: NotificacaoService, persistenciaService: PersistenciaService) {
        self.notificacaoService = notificacaoService
        self.persistenciaService = persistenciaService

        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Observador para notificações recebidas
        NotificationCenter.default.publisher(for: Notification.Name("NotificacaoRecebida"))
            .sink { [weak self] notification in
                guard let self = self,
                    let userInfo = notification.userInfo,
                    let medicamentoID = userInfo["medicamentoID"] as? String,
                    let notificacaoID = userInfo["notificacaoID"] as? String,
                    let id = UUID(uuidString: medicamentoID)
                else {
                    return
                }

                print(
                    "NotificacaoViewModel: Notificação recebida para medicamento \(medicamentoID)")
                self.processarNotificacao(id: id, notificacaoID: notificacaoID)
            }
            .store(in: &cancellables)

        // Observadores para ações automáticas
        NotificationCenter.default.publisher(for: Notification.Name("AutoConfirmarMedicamento"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("Auto-confirmando medicamento")
                self.confirmarMedicamentoTomado()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notification.Name("AutoAdiarMedicamento"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("Auto-adiando medicamento")
                self.adiarMedicamento()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notification.Name("AutoIgnorarMedicamento"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("Auto-ignorando medicamento")
                self.ignorarMedicamento()
            }
            .store(in: &cancellables)
    }

    func verificarNotificacoes() {
        print("Verificando notificações pendentes...")
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notificacoes in
            Task { @MainActor in
                guard let self = self else { return }

                if notificacoes.isEmpty {
                    print("Nenhuma notificação entregue encontrada")
                } else {
                    print("Notificações entregues: \(notificacoes.count)")
                    for notificacao in notificacoes {
                        print("Notificação: \(notificacao.request.identifier)")
                        print("UserInfo: \(notificacao.request.content.userInfo)")

                        if let medicamentoID = notificacao.request.content.userInfo["medicamentoID"]
                            as? String,
                            let notificacaoID = notificacao.request.content.userInfo[
                                "notificationID"] as? String,
                            let id = UUID(uuidString: medicamentoID)
                        {
                            print("Processando notificação pendente: \(medicamentoID)")
                            self.processarNotificacao(id: id, notificacaoID: notificacaoID)

                            // Remover a notificação após processá-la
                            UNUserNotificationCenter.current().removeDeliveredNotifications(
                                withIdentifiers: [notificacao.request.identifier])
                        }
                    }
                }
            }
        }

        // Também verificar notificações pendentes (agendadas)
        notificacaoService.imprimirTodasNotificacoes()
    }

    func processarNotificacao(id: UUID, notificacaoID: String) {
        print(
            "Processando notificação para medicamento \(id.uuidString), notificação \(notificacaoID)"
        )

        let medicamentos = persistenciaService.carregarMedicamentos()

        if let medicamento = medicamentos.first(where: { $0.id == id }) {
            print("Medicamento encontrado: \(medicamento.nome)")

            if let horario = medicamento.horarios.first(where: { $0.notificacaoID == notificacaoID }
            ) {
                print("Horário encontrado: \(horario.hora.formatarHora())")

                // Definir as propriedades que controlam a exibição da tela de confirmação
                Task { @MainActor in
                    self.medicamentoAtual = medicamento
                    self.horarioAtual = horario
                    self.dataHorario = Date()

                    // Importante: definir mostrarTelaConfirmacao como true para exibir a tela
                    print("Exibindo tela de confirmação")
                    self.mostrarTelaConfirmacao = true

                    // Iniciar vibração contínua
                    print("Iniciando vibração")
                    self.iniciarVibracaoContinua()
                }
            } else {
                print("Horário não encontrado para notificaçãoID: \(notificacaoID)")
            }
        } else {
            print("Medicamento não encontrado com ID: \(id.uuidString)")
        }
    }

    func confirmarMedicamentoTomado() {
        print("Confirmando medicamento tomado")
        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("Erro: medicamento ou horário não definidos")
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
        print(
            "Registro adicionado ao histórico: \(registro.nomeMedicamento) - \(registro.status.rawValue)"
        )

        Task { @MainActor in
            self.pararVibracaoContinua()
            self.resetarEstado()
        }
    }

    func adiarMedicamento() {
        print("Adiando medicamento")
        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("Erro: medicamento ou horário não definidos")
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
        print("Registro adicionado ao histórico: \(registro.nomeMedicamento) - Adiado")

        Task { @MainActor in
            self.pararVibracaoContinua()
        }

        // Agendar nova notificação para 3 minutos depois
        let tempoAdiamento = 3  // minutos
        let dataLembrete = Date().adicionarMinutos(tempoAdiamento)

        let conteudo = UNMutableNotificationContent()
        conteudo.title = "Lembrete: \(medicamento.nome)"
        conteudo.body = "Não esqueça de tomar seu medicamento"
        conteudo.sound = .default
        conteudo.categoryIdentifier = "MEDICAMENTO"
        conteudo.userInfo = [
            "medicamentoID": medicamento.id.uuidString,
            "notificationID": horario.notificacaoID,
        ]

        let componentes = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: dataLembrete)
        let trigger = UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)

        let lembreteID = "lembrete-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: lembreteID,
            content: conteudo,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { erro in
            if let erro = erro {
                print("Erro ao agendar lembrete: \(erro.localizedDescription)")
            } else {
                print("Lembrete agendado para \(dataLembrete.formatarHora()) com ID \(lembreteID)")
            }
        }

        Task { @MainActor in
            self.resetarEstado()
        }
    }

    func ignorarMedicamento() {
        print("Ignorando medicamento")
        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("Erro: medicamento ou horário não definidos")
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
        print("Registro adicionado ao histórico: \(registro.nomeMedicamento) - Ignorado")

        Task { @MainActor in
            self.pararVibracaoContinua()
            self.resetarEstado()
        }
    }

    private func resetarEstado() {
        print("Resetando estado")
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
        print("Vibração inicial")

        // Configurar timer para vibrar a cada 2 segundos
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Usamos Task para voltar ao MainActor e acessar propriedades isoladas
            Task { @MainActor in
                // Verificar se atingimos o limite
                if self.vibrationCount < self.maxVibrationCount {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    self.vibrationCount += 1
                    print("Vibração \(self.vibrationCount) de \(self.maxVibrationCount)")
                } else {
                    print("Limite de vibrações atingido")
                    await self.pararVibracaoContinua()
                }
            }
        }

        // Registrar o timer no RunLoop principal para garantir que seja executado
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
            print("Timer de vibração iniciado")
        }
    }

    @MainActor func pararVibracaoContinua() {
        if timer != nil {
            print("Parando vibração contínua")
            timer?.invalidate()
            timer = nil
        }
    }
}
