import Foundation

class PersistenciaService {
    private let medicamentosKey = "medicamentos"
    private let historicoKey = "historico"
    
    func salvarMedicamentos(_ medicamentos: [Medicamento]) {
        if let encoded = try? JSONEncoder().encode(medicamentos) {
            UserDefaults.standard.set(encoded, forKey: medicamentosKey)
        }
    }
    
    func carregarMedicamentos() -> [Medicamento] {
        if let data = UserDefaults.standard.data(forKey: medicamentosKey),
           let medicamentos = try? JSONDecoder().decode([Medicamento].self, from: data) {
            return medicamentos
        }
        return []
    }
    
    func salvarHistorico(_ registros: [RegistroMedicacao]) {
        if let encoded = try? JSONEncoder().encode(registros) {
            UserDefaults.standard.set(encoded, forKey: historicoKey)
        }
    }
    
    func carregarHistorico() -> [RegistroMedicacao] {
        if let data = UserDefaults.standard.data(forKey: historicoKey),
           let registros = try? JSONDecoder().decode([RegistroMedicacao].self, from: data) {
            return registros
        }
        return []
    }
    
    func adicionarRegistro(_ registro: RegistroMedicacao) {
        var historico = carregarHistorico()
        historico.append(registro)
        salvarHistorico(historico)
    }
}