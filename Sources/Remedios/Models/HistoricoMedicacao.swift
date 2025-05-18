import Foundation

struct RegistroMedicacao: Identifiable, Codable {
    let id = UUID()
    var medicamentoID: UUID
    var nomeMedicamento: String
    var horarioProgramado: Date
    var horarioTomado: Date?
    var status: StatusMedicacao
    var adiado: Bool
    
    enum StatusMedicacao: String, Codable {
        case tomado = "Tomado"
        case pendente = "Pendente"
        case ignorado = "Ignorado"
    }
}