import SwiftUI
import Combine

@main
struct RemediosApp: App {
    // Inicialização dos ViewModels
    @StateObject private var medicamentoViewModel: MedicamentoViewModel
    @StateObject private var notificacaoViewModel: NotificacaoViewModel
    
    init() {
        // Criar os serviços e ViewModels
        let persistenciaService = PersistenciaService()
        let notificacaoService = NotificacaoService()
        
        _medicamentoViewModel = StateObject(wrappedValue: MedicamentoViewModel(
            persistenciaService: persistenciaService, 
            notificacaoService: notificacaoService
        ))
        
        _notificacaoViewModel = StateObject(wrappedValue: NotificacaoViewModel(
            notificacaoService: notificacaoService,
            persistenciaService: persistenciaService
        ))
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(medicamentoViewModel)
                .environmentObject(notificacaoViewModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Solicitar permissão para notificações
                    Task {
                        let _ = await notificacaoViewModel.notificacaoService.solicitarPermissao()
                    }
                }
        }
    }
}