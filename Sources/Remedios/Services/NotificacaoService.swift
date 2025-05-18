import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificacaoService {
    
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
        
        // Configurar o trigger com base na frequência
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
                // Fallback para diário se não houver dias específicos
                return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
            }
            
            // Criar uma notificação para cada dia da semana selecionado
            // Note: Isto é simplificado, na prática você criaria múltiplas notificações
            componentes.weekday = diasSemana[0]
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
            
        case .intervalos:
            // Para intervalos, precisaríamos usar outro método como notificações em lote
            // Simplificado para este exemplo
            let intervalo = horario.intervaloDias ?? 1
            let proximaData = Calendar.current.date(byAdding: .day, value: intervalo, to: Date())!
            componentes = calendario.dateComponents([.year, .month, .day, .hour, .minute], from: proximaData)
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: false)
            
        case .ciclos, .esporadico:
            // Para ciclos e uso esporádico, precisaríamos de lógica mais complexa
            // Simplificado para este exemplo
            return UNCalendarNotificationTrigger(dateMatching: componentes, repeats: true)
        }
    }
}