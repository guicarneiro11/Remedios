import SwiftUI
import UserNotifications

@preconcurrency
class ApplicationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @MainActor let notificacaoService = NotificacaoService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Configure categorias e ações
        configureNotificationActions()

        // Verificar se o app foi aberto por uma notificação
        if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification]
            as? [String: AnyObject]
        {
            if let medicamentoID = notification["medicamentoID"] as? String,
                let notificacaoID = notification["notificationID"] as? String
            {

                Task { @MainActor in
                    await self.notificacaoService.processarNotificacaoRecebida(
                        id: UUID(uuidString: medicamentoID) ?? UUID(),
                        notificacaoID: notificacaoID
                    )
                }
            }
        }

        return true
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
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Log para debug
        print("Notificação recebida: \(response.notification.request.identifier)")
        print("User info: \(response.notification.request.content.userInfo)")

        let userInfo = response.notification.request.content.userInfo
        if let medicamentoID = userInfo["medicamentoID"] as? String {
            print("MedicamentoID encontrado: \(medicamentoID)")

            // Processar ações específicas
            switch response.actionIdentifier {
            case "TOMAR_ACTION":
                print("Ação TOMAR selecionada")
                processarTomar(
                    medicamentoID: medicamentoID,
                    notificacaoID: userInfo["notificationID"] as? String)
            case "ADIAR_ACTION":
                print("Ação ADIAR selecionada")
                processarAdiar(
                    medicamentoID: medicamentoID,
                    notificacaoID: userInfo["notificationID"] as? String)
            case "IGNORAR_ACTION":
                print("Ação IGNORAR selecionada")
                processarIgnorar(
                    medicamentoID: medicamentoID,
                    notificacaoID: userInfo["notificationID"] as? String)
            default:
                // Abrir o app normalmente
                print("Notificação aberta (sem ação específica)")
                processarNotificacaoRecebida(
                    medicamentoID: medicamentoID,
                    notificacaoID: userInfo["notificationID"] as? String)
            }
        }

        completionHandler()
    }

    private nonisolated func processarTomar(medicamentoID: String, notificacaoID: String?) {
        Task { @MainActor in
            if let id = UUID(uuidString: medicamentoID),
                let notificacaoID = notificacaoID
            {
                await self.notificacaoService.processarNotificacaoRecebida(
                    id: id, notificacaoID: notificacaoID)
                // Aqui adicionaremos a lógica para automaticamente marcar como tomado
                // após a tela de confirmação ser mostrada
                NotificationCenter.default.post(
                    name: Notification.Name("AutoConfirmarMedicamento"),
                    object: nil
                )
            }
        }
    }

    private nonisolated func processarAdiar(medicamentoID: String, notificacaoID: String?) {
        Task { @MainActor in
            if let id = UUID(uuidString: medicamentoID),
                let notificacaoID = notificacaoID
            {
                await self.notificacaoService.processarNotificacaoRecebida(
                    id: id, notificacaoID: notificacaoID)
                // Aqui adicionaremos a lógica para automaticamente adiar
                NotificationCenter.default.post(
                    name: Notification.Name("AutoAdiarMedicamento"),
                    object: nil
                )
            }
        }
    }

    private nonisolated func processarIgnorar(medicamentoID: String, notificacaoID: String?) {
        Task { @MainActor in
            if let id = UUID(uuidString: medicamentoID),
                let notificacaoID = notificacaoID
            {
                await self.notificacaoService.processarNotificacaoRecebida(
                    id: id, notificacaoID: notificacaoID)
                // Aqui adicionaremos a lógica para automaticamente ignorar
                NotificationCenter.default.post(
                    name: Notification.Name("AutoIgnorarMedicamento"),
                    object: nil
                )
            }
        }
    }

    private nonisolated func processarNotificacaoRecebida(
        medicamentoID: String, notificacaoID: String?
    ) {
        Task { @MainActor in
            if let id = UUID(uuidString: medicamentoID),
                let notificacaoID = notificacaoID
            {
                await self.notificacaoService.processarNotificacaoRecebida(
                    id: id, notificacaoID: notificacaoID)
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        // Mostrar a notificação mesmo quando o app está em primeiro plano
        completionHandler([.banner, .sound, .badge])

        // Extrair apenas os dados específicos que precisamos
        let userInfo = notification.request.content.userInfo
        if let medicamentoID = userInfo["medicamentoID"] as? String,
            let notificacaoID = userInfo["notificationID"] as? String
        {

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
