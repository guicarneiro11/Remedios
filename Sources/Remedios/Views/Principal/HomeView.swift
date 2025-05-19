import SwiftUI

struct HomeView: View {
    @EnvironmentObject var medicamentoViewModel: MedicamentoViewModel
    @StateObject private var notificacaoViewModel = NotificacaoViewModel(
        notificacaoService: NotificacaoService(persistenciaService: PersistenciaService()),
        persistenciaService: PersistenciaService()
    )
    @State private var mostrarConfiguracaoMedicamento = false
    @State private var tabSelecionada = 0
    @StateObject private var notificacaoManager = NotificacaoManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Meus Medicamentos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        mostrarConfiguracaoMedicamento = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                TabView(selection: $tabSelecionada) {
                    ListaMedicamentosView()
                        .tag(0)
                        .environmentObject(notificacaoViewModel)

                    HistoricoView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    TabButton(
                        icone: "list.bullet.clipboard",
                        titulo: "Medicamentos",
                        selecionado: tabSelecionada == 0
                    ) {
                        tabSelecionada = 0
                    }

                    Spacer()

                    TabButton(
                        icone: "chart.bar.fill",
                        titulo: "Histórico",
                        selecionado: tabSelecionada == 1
                    ) {
                        tabSelecionada = 1
                    }

                    Spacer()
                }
                .padding(.vertical, 10)
                .background(
                    Color.black.opacity(0.2)
                        .background(
                            Material.ultraThinMaterial
                        )
                )
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .overlay(
                    RoundedCornerShape(radius: 20, corners: [.topLeft, .topRight])
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task {
                notificacaoManager.verificarNotificacoesPendentes()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
            Task {
                notificacaoManager.verificarNotificacoesPendentes()
            }
        }
        .sheet(isPresented: $mostrarConfiguracaoMedicamento) {
            ConfiguracaoMedicamentoView(viewModel: medicamentoViewModel)
        }
        .onAppear {
            Task {
                NotificacaoManager.shared.solicitarPermissao { granted in
                    print("Permissão para notificações: \(granted ? "concedida" : "negada")")
                }

                notificacaoViewModel.verificarNotificacoes()
            }
        }
    }
}

struct TabButton: View {
    let icone: String
    let titulo: String
    let selecionado: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icone)
                    .font(.system(size: 22))

                Text(titulo)
                    .font(.caption)
            }
            .foregroundColor(selecionado ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
    }
}
