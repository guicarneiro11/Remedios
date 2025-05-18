import SwiftUI
import Combine

struct ConfiguracaoMedicamentoView: View {
    @ObservedObject var viewModel: MedicamentoViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                ProgressoBarraView(etapaAtual: viewModel.etapaConfiguracao, totalEtapas: 4)
                    .padding(.top)

                switch viewModel.etapaConfiguracao {
                case 1:
                    NomeMedicamentoView(viewModel: viewModel)
                case 2:
                    TipoMedicamentoView(viewModel: viewModel)
                case 3:
                    HorarioMedicamentoView(viewModel: viewModel)
                case 4:
                    RevisaoMedicamentoView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }

            VStack {
                HStack {
                    Button(action: {
                        if viewModel.etapaConfiguracao > 1 {
                            viewModel.voltarEtapa()
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct ProgressoBarraView: View {
    let etapaAtual: Int
    let totalEtapas: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalEtapas, id: \.self) { etapa in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(etapa <= etapaAtual ? .white : .white.opacity(0.3))
                
                if etapa < totalEtapas {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(etapa < etapaAtual ? .white : .white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 40)
    }
}