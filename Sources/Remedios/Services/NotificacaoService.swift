import Foundation
import SwiftUI
import UserNotifications

@MainActor
class NotificacaoService {
    let persistenciaService: PersistenciaService

    init(persistenciaService: PersistenciaService) {
        self.persistenciaService = persistenciaService
    }

    func solicitarPermissao() async -> Bool {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert, .badge, .sound,
            ]) { concedida, erro in
                if let erro = erro {
                    print(
                        "Erro ao solicitar permissão para notificações: \(erro.localizedDescription)"
                    )
                }
                continuation.resume(returning: concedida)
            }
        }
    }

    // Função para encontrar um medicamento pelo ID
    func encontrarMedicamento(id: UUID) async -> Medicamento? {
        let medicamentos = persistenciaService.carregarMedicamentos()
        return medicamentos.first(where: { $0.id == id })
    }

    // Agendar uma notificação
    func agendarNotificacao(titulo: String, corpo: String, horario: Horario, medicamentoID: UUID) {
        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo
        conteudo.sound = .default
        conteudo.categoryIdentifier = "MEDICAMENTO"

        // Adicionar os IDs nos userInfo
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
                print("Erro ao agendar notificação: \(erro.localizedDescription)")
            } else {
                print(
                    "Notificação agendada com sucesso para o medicamento \(medicamentoID.uuidString)"
                )
            }
        }
    }

    func imprimirTodasNotificacoes() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("=== NOTIFICAÇÕES PENDENTES: \(requests.count) ===")
            for request in requests {
                print("ID: \(request.identifier)")
                print("Título: \(request.content.title)")
                print("Conteúdo: \(request.content.body)")
                print("UserInfo: \(request.content.userInfo)")
                print("-------------------")
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
}
