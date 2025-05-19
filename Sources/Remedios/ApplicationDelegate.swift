import SwiftUI
import UserNotifications

class ApplicationDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("ApplicationDelegate: didFinishLaunchingWithOptions")

        _ = NotificacaoManager.shared

        if let notificationOption = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            print("App aberto a partir de notificação: \(notificationOption)")
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("ApplicationDelegate: applicationWillEnterForeground")

        Task { @MainActor in
            NotificacaoManager.shared.verificarNotificacoesPendentes()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("ApplicationDelegate: applicationDidBecomeActive")

        Task { @MainActor in
            NotificacaoManager.shared.verificarNotificacoesPendentes()
        }
    }
}
