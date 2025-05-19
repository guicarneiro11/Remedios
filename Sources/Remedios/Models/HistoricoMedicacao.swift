import Foundation

struct RegistroMedicacao: Identifiable, Codable {
    var id = UUID()
    var medicamentoID: UUID
    var nomeMedicamento: String
    var horarioProgramado: Date
    var horarioTomado: Date?
    var status: StatusMedicacao
    var adiado: Bool

    enum StatusMedicacao: String, Codable {
        case tomado = "Tomou"
        case pendente = "Pendente"
        case ignorado = "Ignorou"
    }
}
