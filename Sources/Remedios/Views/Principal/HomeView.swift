import SwiftUI

struct HomeView: View {
    @EnvironmentObject var medicamentoViewModel: MedicamentoViewModel
    @EnvironmentObject var notificacaoViewModel: NotificacaoViewModel
    @State private var mostrarConfiguracaoMedicamento = false
    @State private var tabSelecionada = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Conteúdo principal
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

                    HistoricoView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }

            // Barra inferior de navegação
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
                .background(Color.white.opacity(0.1))
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .overlay(
                    RoundedCornerShape(radius: 20, corners: [.topLeft, .topRight])
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            // Tela de confirmação de medicamento
            if notificacaoViewModel.mostrarTelaConfirmacao {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ConfirmacaoMedicamentoView()
                    .transition(.move(edge: .bottom))
                    .zIndex(100)  // Garantir que fique acima de tudo
            }
        }
        .sheet(isPresented: $mostrarConfiguracaoMedicamento) {
            ConfiguracaoMedicamentoView(viewModel: medicamentoViewModel)
        }
        .onChange(of: notificacaoViewModel.mostrarTelaConfirmacao) { novoValor in
            print("mostrarTelaConfirmacao mudou para: \(novoValor)")

            if novoValor {
                // Garantir que a notificação não será sobreposta por outras views
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Verificar se ainda deve mostrar (pode ter mudado durante o delay)
                    if notificacaoViewModel.mostrarTelaConfirmacao {
                        print("Forçando exibição da tela de confirmação")
                        // Nada aqui - apenas para forçar a atualização da view
                    }
                }
            }
        }
        .onAppear {
            // Verificar notificações pendentes ao abrir o app
            print("HomeView apareceu - verificando notificações")
            notificacaoViewModel.verificarNotificacoes()
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
