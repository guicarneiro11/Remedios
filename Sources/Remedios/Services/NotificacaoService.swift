import Foundation
import SwiftUI
import UserNotifications

@MainActor
class NotificacaoService {
    func receberNotificacao(userInfo: [AnyHashable: Any]) {
        if let medicamentoID = userInfo["medicamentoID"] as? String,
            let id = UUID(uuidString: medicamentoID)
        {

            // Obter o notificationID
            if let notificacaoID = userInfo["notificationID"] as? String {
                Task {
                    await processarNotificacaoRecebida(id: id, notificacaoID: notificacaoID)
                }
            }
        }
    }

    @MainActor
    func processarNotificacaoRecebida(id: UUID, notificacaoID: String) {
        // Delegamos para o ViewModel que já tem esta lógica
        NotificationCenter.default.post(
            name: Notification.Name("NotificacaoRecebida"),
            object: nil,
            userInfo: ["medicamentoID": id.uuidString, "notificacaoID": notificacaoID]
        )
    }

    func solicitarPermissao() async -> Bool {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert, .badge, .sound,
            ]) { concedida, erro in
                continuation.resume(returning: concedida)
            }
        }
    }

    // In NotificacaoService.swift, modify the agendarNotificacao method
    func agendarNotificacao(titulo: String, corpo: String, horario: Horario, medicamentoID: UUID) {
        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo
        conteudo.sound = .default
        conteudo.categoryIdentifier = "MEDICAMENTO"
        // Importante: adicionar AMBOS os IDs nos userInfo
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

        // Registrar ações para as notificações
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

        UNUserNotificationCenter.current().add(request) { erro in
            if let erro = erro {
                print("Erro ao agendar notificação: \(erro.localizedDescription)")
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
