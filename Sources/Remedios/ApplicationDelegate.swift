import SwiftUI
import UserNotifications

@preconcurrency
class ApplicationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @MainActor let notificacaoService = NotificacaoService()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extrair apenas os dados específicos que precisamos
        let userInfo = response.notification.request.content.userInfo
        if let medicamentoID = userInfo["medicamentoID"] as? String,
           let notificacaoID = userInfo["notificationID"] as? String {
            
            // Passar apenas os dados específicos para o MainActor
            Task { @MainActor in
                await self.notificacaoService.processarNotificacaoRecebida(
                    id: UUID(uuidString: medicamentoID) ?? UUID(),
                    notificacaoID: notificacaoID
                )
            }
        }
        
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Mostrar a notificação mesmo quando o app está em primeiro plano
        completionHandler([.banner, .sound, .badge])
        
        // Extrair apenas os dados específicos que precisamos
        let userInfo = notification.request.content.userInfo
        if let medicamentoID = userInfo["medicamentoID"] as? String,
           let notificacaoID = userInfo["notificationID"] as? String {
            
            // Passar apenas os dados específicos para o MainActor
            Task { @MainActor in
                await self.notificacaoService.processarNotificacaoRecebida(
                    id: UUID(uuidString: medicamentoID) ?? UUID(),
                    notificacaoID: notificacaoID
                )
            }
        }
    }
}
