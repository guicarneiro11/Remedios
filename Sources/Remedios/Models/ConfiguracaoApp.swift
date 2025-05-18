import Foundation
import SwiftUI

struct ConfiguracaoApp: Codable {
    var tema: TemaApp = .escuro
    var notificacoesCriticas: Bool = true
    var somNotificacao: SomNotificacao = .padrao
    var vibracao: Bool = true
    var mostrarHistoricoCompleto: Bool = true
    var diasHistoricoExibidos: Int = 30
    var atrasoNotificacaoReminder: Int = 10
    
    enum TemaApp: String, Codable, CaseIterable {
        case claro = "Claro"
        case escuro = "Escuro"
        case sistema = "Sistema"
    }
    
    enum SomNotificacao: String, Codable, CaseIterable {
        case padrao = "Padrão"
        case suave = "Suave"
        case urgente = "Urgente"
        case silencioso = "Silencioso"
    }
}