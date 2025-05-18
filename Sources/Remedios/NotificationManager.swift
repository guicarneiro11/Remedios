import AudioToolbox
import SwiftUI
import UserNotifications

// Singleton para gerenciar notificações - marcado como MainActor para garantir segurança de concorrência
@MainActor
class NotificacaoManager: NSObject, UNUserNotificationCenterDelegate {
    // Singleton
    static let shared = NotificacaoManager()

    // Estado atual da notificação
    @Published var medicamentoAtual: Medicamento?
    @Published var horarioAtual: Horario?
    @Published var mostrarTelaConfirmacao = false

    // Persistência
    let persistenciaService = PersistenciaService()

    // Vibração
    private var timer: Timer?
    private var vibrationCount = 0
    private let maxVibrationCount = 30

    private override init() {
        super.init()

        print("NotificacaoManager: Inicializando...")

        // Definir self como o delegate de notificações
        UNUserNotificationCenter.current().delegate = self

        // Configurar ações de notificação
        configureNotificationActions()

        print("NotificacaoManager: Inicializado com sucesso!")
    }

    func solicitarPermissao(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            if let error = error {
                print("Erro ao solicitar permissão: \(error.localizedDescription)")
            }

            print("Permissão de notificação: \(granted ? "CONCEDIDA" : "NEGADA")")
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

    // Agendar uma notificação
    func agendarNotificacao(titulo: String, corpo: String, horario: Horario, medicamentoID: UUID) {
        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo
        conteudo.sound = .default
        conteudo.categoryIdentifier = "MEDICAMENTO"
        conteudo.userInfo = [
            "medicamentoID": medicamentoID.uuidString,
            "notificationID": horario.notificacaoID,
        ]

        let trigger = criarTrigger(para: horario)
        let request = UNNotificationRequest(
            identifier: horario.notificacaoID,
            content: conteudo,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { erro in
            if let erro = erro {
                print("❌ Erro ao agendar notificação: \(erro.localizedDescription)")
            } else {
                print("✅ Notificação agendada com sucesso: \(horario.notificacaoID)")
            }
        }
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

    func cancelarNotificacao(identificador: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identificador
        ])
        print("Notificação cancelada: \(identificador)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Quando o usuário interage com uma notificação
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("Notificação tocada: \(response.notification.request.identifier)")

        // Extrair os dados necessários
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        if let medicamentoID = userInfo["medicamentoID"] as? String,
            let notificacaoID = userInfo["notificationID"] as? String,
            let id = UUID(uuidString: medicamentoID)
        {

            print(
                "Processando notificação para medicamento \(medicamentoID), notificação \(notificacaoID)"
            )

            // Precisamos entrar no contexto MainActor para acessar o singleton
            Task { @MainActor in
                print("Iniciando processamento @MainActor")

                // Carregar medicamentos
                let medicamentos = self.persistenciaService.carregarMedicamentos()

                // Encontrar medicamento e horário correspondentes
                guard let medicamento = medicamentos.first(where: { $0.id == id }),
                    let horario = medicamento.horarios.first(where: {
                        $0.notificacaoID == notificacaoID
                    })
                else {
                    print("❌ Medicamento ou horário não encontrado")
                    return
                }

                print("✅ Medicamento encontrado: \(medicamento.nome)")

                // Configurar o estado atual
                self.medicamentoAtual = medicamento
                self.horarioAtual = horario
                self.mostrarTelaConfirmacao = true

                // Iniciar vibração
                print("Iniciando vibração...")
                self.iniciarVibracaoContinua()

                // Se uma ação específica foi selecionada, executá-la após um pequeno atraso
                switch actionIdentifier {
                case "TOMAR_ACTION":
                    print("Ação TOMAR selecionada - aguardando para executar...")
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 segundos
                    print("Executando ação TOMAR")
                    self.confirmarMedicamentoTomado()

                case "ADIAR_ACTION":
                    print("Ação ADIAR selecionada - aguardando para executar...")
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 segundos
                    print("Executando ação ADIAR")
                    self.adiarMedicamento()

                case "IGNORAR_ACTION":
                    print("Ação IGNORAR selecionada - aguardando para executar...")
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 segundos
                    print("Executando ação IGNORAR")
                    self.ignorarMedicamento()

                default:
                    print("Nenhuma ação específica selecionada - apenas mostrando a tela")
                }
            }
        }

        completionHandler()
    }

    // Quando uma notificação chega com o app em primeiro plano
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        // Mostrar a notificação mesmo quando o app está em primeiro plano
        completionHandler([.banner, .sound, .badge])

        // Extrair os dados necessários
        let userInfo = notification.request.content.userInfo

        if let medicamentoID = userInfo["medicamentoID"] as? String,
            let notificacaoID = userInfo["notificationID"] as? String,
            let id = UUID(uuidString: medicamentoID)
        {

            print("Notificação em primeiro plano: \(medicamentoID), \(notificacaoID)")

            // Acessar o singleton em contexto MainActor
            Task { @MainActor in
                // Carregar medicamentos
                let medicamentos = self.persistenciaService.carregarMedicamentos()

                // Encontrar medicamento e horário correspondentes
                guard let medicamento = medicamentos.first(where: { $0.id == id }),
                    let horario = medicamento.horarios.first(where: {
                        $0.notificacaoID == notificacaoID
                    })
                else {
                    print("❌ Medicamento ou horário não encontrado (willPresent)")
                    return
                }

                print("✅ Medicamento encontrado (willPresent): \(medicamento.nome)")

                // Configurar o estado atual
                self.medicamentoAtual = medicamento
                self.horarioAtual = horario
                self.mostrarTelaConfirmacao = true

                // Iniciar vibração
                print("Iniciando vibração (willPresent)...")
                self.iniciarVibracaoContinua()
            }
        }
    }

    // MARK: - Ações de medicamentos

    func confirmarMedicamentoTomado() {
        print("Confirmando medicamento tomado")
        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("❌ Erro: medicamento ou horário não definidos")
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
        print("✅ Registro adicionado: \(medicamento.nome) - Tomado")

        pararVibracaoContinua()
        resetarEstado()
    }

    func adiarMedicamento() {
        print("Adiando medicamento")
        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("❌ Erro: medicamento ou horário não definidos")
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
        print("✅ Registro adicionado: \(medicamento.nome) - Adiado")

        pararVibracaoContinua()
        resetarEstado()

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
                print("❌ Erro ao agendar lembrete: \(erro.localizedDescription)")
            } else {
                print("✅ Lembrete agendado para daqui a \(tempoAdiamento) minutos")
            }
        }
    }

    func ignorarMedicamento() {
        print("Ignorando medicamento")
        guard let medicamento = medicamentoAtual,
            let horario = horarioAtual
        else {
            print("❌ Erro: medicamento ou horário não definidos")
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
        print("✅ Registro adicionado: \(medicamento.nome) - Ignorado")

        pararVibracaoContinua()
        resetarEstado()
    }

    func resetarEstado() {
        print("Resetando estado")
        medicamentoAtual = nil
        horarioAtual = nil
        mostrarTelaConfirmacao = false
    }

    // MARK: - Vibração

    func iniciarVibracaoContinua() {
        // Parar qualquer timer existente
        pararVibracaoContinua()

        // Resetar contador
        vibrationCount = 0

        print("⚡ INICIANDO VIBRAÇÃO CONTÍNUA")

        // Vibrar imediatamente
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        // Configurar timer para vibrar a cada 2 segundos - usando um timer que roda na thread principal
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            // Usamos DispatchQueue.main para garantir que estamos na thread principal
            DispatchQueue.main.async {
                guard let self = self else { return }

                // Agora estamos no contexto do MainActor, então podemos acessar as propriedades com segurança
                if self.mostrarTelaConfirmacao {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    self.vibrationCount += 1
                    print("Vibração \(self.vibrationCount)")

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

        RunLoop.main.add(timer!, forMode: .common)
    }

    func pararVibracaoContinua() {
        if timer != nil {
            print("Parando vibração contínua")
            timer?.invalidate()
            timer = nil
        }
    }
}
