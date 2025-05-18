import Combine
import SwiftUI

@main
struct RemediosApp: App {
    @StateObject private var medicamentoViewModel: MedicamentoViewModel
    @UIApplicationDelegateAdaptor private var appDelegate: ApplicationDelegate

    init() {
        let persistenciaService = PersistenciaService()

        // Usamos diretamente o NotificacaoManager.shared
        _medicamentoViewModel = StateObject(
            wrappedValue: MedicamentoViewModel(
                persistenciaService: persistenciaService,
                notificacaoService: NotificacaoService(persistenciaService: persistenciaService)
            ))
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(medicamentoViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
