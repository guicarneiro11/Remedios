import Combine
import SwiftUI

@main
struct RemediosApp: App {
    @StateObject private var medicamentoViewModel: MedicamentoViewModel
    @StateObject private var notificacaoViewModel = NotificacaoViewModel(
        notificacaoService: NotificacaoService(persistenciaService: PersistenciaService()),
        persistenciaService: PersistenciaService()
    )
    @UIApplicationDelegateAdaptor private var appDelegate: ApplicationDelegate

    init() {
        let persistenciaService = PersistenciaService()

        _medicamentoViewModel = StateObject(
            wrappedValue: MedicamentoViewModel(
                persistenciaService: persistenciaService,
                notificacaoService: NotificacaoService(persistenciaService: persistenciaService)
            ))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .environmentObject(medicamentoViewModel)
                    .preferredColorScheme(.dark)

                NotificacaoOverlay()
            }
            .onAppear {
                NotificacaoManager.shared.verificarNotificacoesPendentes()
            }
        }
    }
}

struct NotificacaoOverlay: View {
    @StateObject private var manager = NotificacaoManager.shared

    var body: some View {
        ZStack {
            if manager.mostrarTelaConfirmacao {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ConfirmacaoMedicamentoView()
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        print("OVERLAY: Tela de confirmação apareceu")

                        if manager.medicamentoAtual != nil {
                            manager.iniciarVibracaoContinua()
                        }
                    }
            }
        }
        .animation(.easeInOut, value: manager.mostrarTelaConfirmacao)
    }
}
