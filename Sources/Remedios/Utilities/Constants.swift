import Foundation
import SwiftUI

enum AppColors {
    static let primaria = Color.blue
    static let secundaria = Color.purple
    static let fundo = Color.black
    static let textoClaro = Color.white
    static let textoEscuro = Color.black
    static let acento = Color.green
    static let alerta = Color.red
    
    static let fundoCard = Color.white.opacity(0.1)
    static let bordaCard = Color.white.opacity(0.3)
    
    static let gradienteFundo = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
    )
}

enum AppTextos {
    static let nomeApp = "MediReminder"
    static let tituloPrincipal = "Meus Medicamentos"
    static let tituloHistorico = "Histórico"
    static let tituloConfiguracoes = "Configurações"
    
    static let erroPermissaoNotificacao = "É necessário permitir notificações para utilizar este aplicativo."
    static let erroGenerico = "Ocorreu um erro. Tente novamente."
    
    static let botaoAdicionar = "Adicionar"
    static let botaoContinuar = "Continuar"
    static let botaoSalvar = "Salvar"
    static let botaoCancelar = "Cancelar"
    static let botaoConfirmar = "Confirmar"
    static let botaoAdiar = "Adiar"
    static let botaoIgnorar = "Ignorar"
    
    static let estadoVazio = "Nenhum medicamento configurado"
    static let dicaAdicionar = "Toque no botão + para adicionar um novo medicamento"
}

enum AppDefaults {
    static let tempoAtraso = 10
    static let diasHistorico = 30
    static let tamanhoPaginacao = 20
}

enum StorageKeys {
    static let medicamentos = "medicamentos"
    static let historico = "historico"
    static let configuracoes = "configuracoes"
    static let ultimoLogin = "ultimoLogin"
}