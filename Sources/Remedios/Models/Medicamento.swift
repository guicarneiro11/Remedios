import Foundation

enum TipoMedicamento: String, CaseIterable, Identifiable, Codable {
    case capsula = "Cápsula"
    case comprimido = "Comprimido"
    case liquido = "Líquido"
    case topico = "Tópico"
    case adesivo = "Adesivo"
    case creme = "Creme"
    case dispositivo = "Dispositivo"
    case espuma = "Espuma"
    case gel = "Gel"
    case gotas = "Gotas"
    case inalador = "Inalador"
    case injecao = "Injeção"
    case locao = "Loção"
    case pomada = "Pomada"
    case po = "Pó"
    case spray = "Spray"
    case supositorio = "Supositório"
    
    var id: String { rawValue }
    
    var categoria: CategoriaMedicamento {
        switch self {
        case .capsula, .comprimido, .liquido, .topico:
            return .comum
        default:
            return .outra
        }
    }
}

enum CategoriaMedicamento: String, Codable {
    case comum = "Formas Comuns"
    case outra = "Outras Formas"
}

enum FrequenciaMedicamento: String, Codable {
    case diaria = "Todos os dias"
    case ciclos = "Ciclos"
    case diasEspecificos = "Dias específicos"
    case intervalos = "Intervalos de dias"
    case esporadico = "Uso esporádico"
}

// Struct para substituir a tupla que estava causando erro de Codable
struct CicloMedicamento: Codable, Equatable {
    var ativo: Int
    var descanso: Int
}

struct Horario: Identifiable, Codable {
    let id = UUID()
    var hora: Date
    var frequencia: FrequenciaMedicamento
    var diasSemana: [Int]? // 1 = Domingo, 2 = Segunda, etc.
    var intervaloDias: Int?
    var ciclosDias: CicloMedicamento?
    
    var notificacaoID: String {
        return id.uuidString
    }
}

struct Medicamento: Identifiable, Codable {
    let id = UUID()
    var nome: String
    var tipo: TipoMedicamento
    var horarios: [Horario]
    var notas: String?
    var nomeTitulo: String? // Nome personalizado para notificação
    var dataCriacao: Date
    var ativo: Bool = true
}