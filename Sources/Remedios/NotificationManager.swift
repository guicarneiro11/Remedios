import AudioToolbox
import SwiftUI
import UIKit
import UserNotifications

@MainActor
class NotificacaoManager: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificacaoManager()

    @Published var medicamentoAtual: Medicamento?
    @Published var horarioAtual: Horario?
    @Published var mostrarTelaConfirmacao = false

    let persistenciaService = PersistenciaService()

    private var timer: Timer?
    private var vibrationCount = 0
    private let maxVibrationCount = 30

    private override init() {
        super.init()
        print("NotificacaoManager: Inicializando...")

        UNUserNotificationCenter.current().delegate = self

        configureNotificationActions()

        print("NotificacaoManager: Inicializado com sucesso!")
    }

    func solicitarPermissao(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            if let error = error {
                print("Erro ao solicitar permissão: \(error.localizedDescription)")
            }
            print("Permissão para notificações: \(granted ? "CONCEDIDA" : "NEGADA")")
            completion(granted)
        }
    }

    private func configureNotificationActions() {
        let tomarAction = UNNotificationAction(
            identifier: "TOMAR_ACTION",
            title: "Tomei",
            options: .foreground
        )

        let adiarAction = UNNotificationAction(
            identifier: "ADIAR_ACTION",
            title: "Adiar",
            options: .foreground
        )

        let ignorarAction = UNNotificationAction(
            identifier: "IGNORAR_ACTION",
            title: "Ignorar",
            options: .foreground
        )

        let category = UNNotificationCategory(
            identifier: "MEDICAMENTO",
            actions: [tomarAction, adiarAction, ignorarAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("Categorias e ações de notificação configuradas")
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("EVENTO: Usuário tocou na notificação: \(response.notification.request.identifier)")

        let medicamentoIDString =
            response.notification.request.content.userInfo["medicamentoID"] as? String
        let notificacaoIDString =
            response.notification.request.content.userInfo["notificationID"] as? String
        let actionID = response.actionIdentifier

        completionHandler()

        if let medicamentoIDString = medicamentoIDString,
            let notificacaoIDString = notificacaoIDString,
            let id = UUID(uuidString: medicamentoIDString)
        {

            Task { @MainActor in
                print(
                    "PROCESSANDO notificação: medicamento=\(medicamentoIDString), notificacao=\(notificacaoIDString)"
                )

                let medicamentos = self.persistenciaService.carregarMedicamentos()

                guard let medicamento = medicamentos.first(where: { $0.id == id }),
                    let horario = medicamento.horarios.first(where: {
                        $0.notificacaoID == notificacaoIDString
                    })
                else {
                    print("ERRO: Medicamento ou horário não encontrado")
                    return
                }

                print("SUCESSO: Medicamento encontrado: \(medicamento.nome)")

                self.medicamentoAtual = medicamento
                self.horarioAtual = horario
                self.mostrarTelaConfirmacao = true

                self.iniciarVibracaoContinua()

                switch actionID {
                case "TOMAR_ACTION":
                    self.confirmarMedicamentoTomado()
                case "ADIAR_ACTION":
                    self.adiarMedicamento()
                case "IGNORAR_ACTION":
                    self.ignorarMedicamento()
                default:
                    break
                }
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        print("EVENTO: Notificação recebida em primeiro plano")

        let medicamentoIDString = notification.request.content.userInfo["medicamentoID"] as? String
        let notificacaoIDString = notification.request.content.userInfo["notificationID"] as? String

        completionHandler([.banner, .sound, .badge])

        if let medicamentoIDString = medicamentoIDString,
            let notificacaoIDString = notificacaoIDString,
            let id = UUID(uuidString: medicamentoIDString)
        {

            Task { @MainActor in
                print(
                    "PROCESSANDO notificação em primeiro plano: medicamento=\(medicamentoIDString), notificacao=\(notificacaoIDString)"
                )

                let medicamentos = self.persistenciaService.carregarMedicamentos()

                guard let medicamento = medicamentos.first(where: { $0.id == id }),
                    let horario = medicamento.horarios.first(where: {
                        $0.notificacaoID == notificacaoIDString
                    })
                else {
                    print("ERRO: Medicamento ou horário não encontrado")
                    return
                }

                print("SUCESSO: Medicamento encontrado: \(medicamento.nome)")

                self.medicamentoAtual = medicamento
                self.horarioAtual = horario
                self.mostrarTelaConfirmacao = true

                self.iniciarVibracaoContinua()
            }
        }
    }

    func agendarNotificacao(titulo: String, corpo: String, horario: Horario, medicamentoID: UUID) {
        print("Agendando notificação para \(titulo)")

        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo

        conteudo.sound = UNNotificationSound.defaultCritical

        conteudo.categoryIdentifier = "MEDICAMENTO"
        conteudo.userInfo = [
            "medicamentoID": medicamentoID.uuidString,
            "notificationID": horario.notificacaoID,
        ]

        conteudo.threadIdentifier = "medicacao-importante"
        conteudo.relevanceScore = 1.0

        let trigger = criarTrigger(para: horario)
        let request = UNNotificationRequest(
            identifier: horario.notificacaoID,
            content: conteudo,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { erro in
            if let erro = erro {
                print("ERRO ao agendar notificação: \(erro.localizedDescription)")
            } else {
                print("Notificação agendada com sucesso: \(horario.notificacaoID)")
            }
        }
    }

    func cancelarNotificacao(identificador: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identificador
        ])
        print("Notificação cancelada: \(identificador)")
    }

    private func criarTrigger(para horario: Horario) -> UNNotificationTrigger {
        let calendario = Calendar.current
        var componentes = calendario.dateComponents([.hour, .minute], from: horario.hora)

        switch horario.frequencia {
        case .diaria:
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)

        case .diasEspecificos:
            guard let diasSemana = horario.diasSemana, !diasSemana.isEmpty else {
                return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
            }
            componentes.weekday = diasSemana[0]
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)

        case .intervalos:
            let intervalo = horario.intervaloDias ?? 1
            let proximaData = Calendar.current.date(byAdding: .day, value: intervalo, to: Date())!
            componentes = calendario.dateComponents(
                [.year, .month, .day, .hour, .minute], from: proximaData)
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)

        case .ciclos, .esporadico:
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
        }
    }

    func confirmarMedicamentoTomado() {
        print("AÇÃO: Confirmar medicamento tomado")

        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("ERRO: Medicamento ou horário não definidos")
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
        print("Registro adicionado: \(medicamento.nome) - Tomado")

        pararVibracaoContinua()
        resetarEstado()
    }

    func adiarMedicamento() {
        print("AÇÃO: Adiar medicamento")

        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("ERRO: Medicamento ou horário não definidos")
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
        print("Registro adicionado: \(medicamento.nome) - Adiado")

        pararVibracaoContinua()
        resetarEstado()

        let tempoAdiamento = 5
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
                print("ERRO ao agendar lembrete: \(erro.localizedDescription)")
            } else {
                print("Lembrete agendado para daqui a \(tempoAdiamento) minutos")
            }
        }
    }

    func ignorarMedicamento() {
        print("AÇÃO: Ignorar medicamento")

        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("ERRO: Medicamento ou horário não definidos")
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
        print("Registro adicionado: \(medicamento.nome) - Ignorado")

        pararVibracaoContinua()
        resetarEstado()
    }

    func resetarEstado() {
        print("Resetando estado")
        medicamentoAtual = nil
        horarioAtual = nil
        mostrarTelaConfirmacao = false
    }

    func iniciarVibracaoContinua() {
        pararVibracaoContinua()

        vibrationCount = 0

        print("⚡ INICIANDO VIBRAÇÃO CONTÍNUA")

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
                [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if self.mostrarTelaConfirmacao {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                        feedbackGenerator.prepare()
                        feedbackGenerator.impactOccurred()

                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

                        self.vibrationCount += 1
                        print("Vibração \(self.vibrationCount) de \(self.maxVibrationCount)")

                        if self.vibrationCount >= self.maxVibrationCount {
                            print("Limite de vibrações atingido")
                            self.pararVibracaoContinua()
                        }
                    } else {
                        print("Tela não está mais visível - parando vibração")
                        self.pararVibracaoContinua()
                    }
                }
            }

            if let timer = self.timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    func pararVibracaoContinua() {
        if timer != nil {
            print("Parando vibração contínua")
            timer?.invalidate()
            timer = nil
        }
    }

    func verificarNotificacoesPendentes() {
        print("Verificando notificações pendentes e entregues...")

        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notificacoes in
            Task { @MainActor in
                guard let self = self else { return }

                if !notificacoes.isEmpty {
                    print("Notificações entregues: \(notificacoes.count)")
                    self.processarNotificacaoMaisRecente(notificacoes)
                } else {
                    print("Nenhuma notificação entregue")

                    self.verificarNotificacoesPendentesAtivas()
                }
            }
        }
    }

    private func verificarNotificacoesPendentesAtivas() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] pendentes in
            Task { @MainActor in
                guard let self = self else { return }

                let agora = Date()
                print("Notificações pendentes: \(pendentes.count)")

                let notificacoesFiltradas = pendentes.compactMap {
                    requisicao -> UNNotificationRequest? in
                    if let trigger = requisicao.trigger as? UNCalendarNotificationTrigger,
                        let dateMatching = trigger.dateComponents.date,
                        dateMatching <= agora
                    {
                        return requisicao
                    }
                    return nil
                }

                if !notificacoesFiltradas.isEmpty {
                    print("Notificações pendentes ativas: \(notificacoesFiltradas.count)")

                    if let notificacao = notificacoesFiltradas.last,
                        let medicamentoID = notificacao.content.userInfo["medicamentoID"]
                            as? String,
                        let notificacaoID = notificacao.content.userInfo["notificationID"]
                            as? String,
                        let id = UUID(uuidString: medicamentoID)
                    {

                        self.processarNotificacaoAtiva(
                            medicamentoID: medicamentoID, notificacaoID: notificacaoID, id: id)
                    }
                } else {
                    print("Nenhuma notificação pendente ativa")
                }
            }
        }
    }

    private func processarNotificacaoMaisRecente(_ notificacoes: [UNNotification]) {
        if let notificacao = notificacoes.last,
            let medicamentoID = notificacao.request.content.userInfo["medicamentoID"] as? String,
            let notificacaoID = notificacao.request.content.userInfo["notificationID"] as? String,
            let id = UUID(uuidString: medicamentoID)
        {

            print("Processando notificação entregue: \(medicamentoID)")

            processarNotificacaoAtiva(
                medicamentoID: medicamentoID, notificacaoID: notificacaoID, id: id)

            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: [notificacao.request.identifier])
        }
    }

    private func processarNotificacaoAtiva(medicamentoID: String, notificacaoID: String, id: UUID) {
        let medicamentos = self.persistenciaService.carregarMedicamentos()

        if let medicamento = medicamentos.first(where: { $0.id == id }),
            let horario = medicamento.horarios.first(where: { $0.notificacaoID == notificacaoID })
        {

            print("SUCESSO: Medicamento encontrado: \(medicamento.nome)")

            self.medicamentoAtual = medicamento
            self.horarioAtual = horario
            self.mostrarTelaConfirmacao = true

            print("Iniciando vibração para notificação...")
            self.iniciarVibracaoContinua()
        } else {
            print("ERRO: Medicamento ou horário não encontrado")
        }
    }
}
