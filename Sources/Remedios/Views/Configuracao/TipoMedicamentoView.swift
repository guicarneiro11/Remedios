import SwiftUI

struct TipoMedicamentoView: View {
    @ObservedObject var viewModel: MedicamentoViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Qual o tipo do medicamento?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(CategoriaMedicamento.allCases, id: \.rawValue) { categoria in
                        SectionHeader(titulo: categoria.rawValue)
                        
                        ForEach(TipoMedicamento.allCases.filter { $0.categoria == categoria }) { tipo in
                            Button(action: {
                                viewModel.tipo = tipo
                            }) {
                                HStack {
                                    Text(tipo.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if viewModel.tipo == tipo {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            viewModel.tipo == tipo ? Color.green : Color.white.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            
            Button(action: {
                viewModel.avancarEtapa()
            }) {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct SectionHeader: View {
    let titulo: String
    
    var body: some View {
        HStack {
            Text(titulo)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))
                .padding(.vertical, 8)
            
            Spacer()
        }
    }
}

extension CategoriaMedicamento: CaseIterable {
    static var allCases: [CategoriaMedicamento] {
        return [.comum, .outra]
    }
}