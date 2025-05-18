import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificacaoService {
    func receberNotificacao(userInfo: [AnyHashable: Any]) {
    if let medicamentoID = userInfo["medicamentoID"] as? String,
        let id = UUID(uuidString: medicamentoID) {
        
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
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { concedida, erro in
                continuation.resume(returning: concedida)
            }
        }
    }
    
    func agendarNotificacao(titulo: String, corpo: String, horario: Horario, medicamentoID: UUID) {
        let conteudo = UNMutableNotificationContent()
        conteudo.title = titulo
        conteudo.body = corpo
        conteudo.sound = .default
        conteudo.userInfo = ["medicamentoID": medicamentoID.uuidString]

        let trigger = criarTrigger(para: horario)
        
        let request = UNNotificationRequest(
            identifier: horario.notificacaoID,
            content: conteudo,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { erro in
            if let erro = erro {
                print("Erro ao agendar notificação: \(erro.localizedDescription)")
            }
        }
    }
    
    func cancelarNotificacao(identificador: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identificador])
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
            componentes = calendario.dateComponents([.year, .month, .day, .hour, .minute], from: proximaData)
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)
            
        case .ciclos, .esporadico:
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
        }
    }
}