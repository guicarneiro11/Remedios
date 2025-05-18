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
    private let maxVibrationCount = 30  // Máximo de vibrações antes de parar automaticamente

    let notificacaoService: NotificacaoService
    private let persistenciaService: PersistenciaService

    // Constructor com injeção de dependências
    init(notificacaoService: NotificacaoService, persistenciaService: PersistenciaService) {
        self.notificacaoService = notificacaoService
        self.persistenciaService = persistenciaService
        print("NotificacaoViewModel inicializado")
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
                    // Processar apenas a notificação mais recente
                    if let notificacao = notificacoes.last,
                        let medicamentoID = notificacao.request.content.userInfo["medicamentoID"]
                            as? String,
                        let notificacaoID = notificacao.request.content.userInfo["notificationID"]
                            as? String,
                        let id = UUID(uuidString: medicamentoID)
                    {

                        print("Processando notificação pendente: \(medicamentoID)")
                        await self.processarNotificacao(id: id, notificacaoID: notificacaoID)

                        // Remover a notificação após processá-la
                        UNUserNotificationCenter.current().removeDeliveredNotifications(
                            withIdentifiers: [notificacao.request.identifier])
                    }
                }
            }
        }

        // Também verificar notificações pendentes (agendadas)
        notificacaoService.imprimirTodasNotificacoes()
    }

    func processarNotificacao(id: UUID, notificacaoID: String) async {
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
                self.medicamentoAtual = medicamento
                self.horarioAtual = horario
                self.dataHorario = Date()

                // Mostrar a tela de confirmação
                print("Exibindo tela de confirmação")
                self.mostrarTelaConfirmacao = true

                // Iniciar vibração contínua
                iniciarVibracaoContinua()
            } else {
                print("Horário não encontrado para notificacaoID: \(notificacaoID)")
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

        pararVibracaoContinua()
        resetarEstado()
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
                print("Erro ao agendar lembrete: \(erro.localizedDescription)")
            } else {
                print("Lembrete agendado para \(dataLembrete.formatarHora()) com ID \(lembreteID)")
            }
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

        pararVibracaoContinua()
        resetarEstado()
    }

    func resetarEstado() {
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

        print("INICIANDO VIBRAÇÃO CONTÍNUA")

        // Vibrar imediatamente
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        print("Vibração inicial")

        // Configurar timer para vibrar a cada 2 segundos
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Usamos DispatchQueue para garantir que estamos na thread principal
            DispatchQueue.main.async {
                // Verificar se ainda devemos mostrar a tela de confirmação
                if !self.mostrarTelaConfirmacao {
                    self.pararVibracaoContinua()
                    return
                }

                // Verificar se atingimos o limite
                if self.vibrationCount < self.maxVibrationCount {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                    self.vibrationCount += 1
                    print("Vibração \(self.vibrationCount) de \(self.maxVibrationCount)")
                } else {
                    print("Limite de vibrações atingido")
                    self.pararVibracaoContinua()
                }
            }
        }

        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
            print("Timer de vibração iniciado")
        }
    }

    func pararVibracaoContinua() {
        if timer != nil {
            print("Parando vibração contínua")
            timer?.invalidate()
            timer = nil
        }
    }
}
