import SwiftUI
import UserNotifications

class ApplicationDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("ApplicationDelegate: didFinishLaunchingWithOptions")

        // O NotificacaoManager é um singleton e já configura o delegate de notificações
        _ = NotificacaoManager.shared

        return true
    }
}
