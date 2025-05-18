import SwiftUI

struct NomeMedicamentoView: View {
    @ObservedObject var viewModel: MedicamentoViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Qual o nome do medicamento?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            
            TextField("Nome do medicamento", text: $viewModel.nome)
                .font(.title3)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Spacer()
            
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
            .opacity(viewModel.nome.isEmpty ? 0.5 : 1.0)
            .disabled(viewModel.nome.isEmpty)
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
        .alert(isPresented: $viewModel.mostrarErro) {
            Alert(
                title: Text("Erro"),
                message: Text(viewModel.mensagemErro),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}