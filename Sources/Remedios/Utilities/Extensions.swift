import Foundation
import SwiftUI

extension Date {
    func formatarHora() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    func formatarData() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self)
    }
    
    func formatarCompleto() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: self)
    }
    
    func mesmoHorario(que data: Date) -> Bool {
        let calendar = Calendar.current
        let componentes1 = calendar.dateComponents([.hour, .minute], from: self)
        let componentes2 = calendar.dateComponents([.hour, .minute], from: data)
        
        return componentes1.hour == componentes2.hour && componentes1.minute == componentes2.minute
    }
    
    func mesmoDia(que data: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: data)
    }
    
    func adicionarMinutos(_ minutos: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutos, to: self) ?? self
    }
}

extension String {
    var primeiraLetraMaiuscula: String {
        return prefix(1).capitalized + dropFirst()
    }
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(AppColors.fundoCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.bordaCard, lineWidth: 1)
            )
    }
    
    func bordaAnimada() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .animation(
                    Animation.linear(duration: 2)
                        .repeatForever(autoreverses: false),
                    value: UUID()
                )
        )
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension Color {
    static func aleatorio() -> Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
    
    func clareado(_ quantidade: Double = 0.2) -> Color {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color(
            red: min(r + CGFloat(quantidade), 1.0),
            green: min(g + CGFloat(quantidade), 1.0),
            blue: min(b + CGFloat(quantidade), 1.0)
        )
    }
}

extension Array where Element: Identifiable {
    mutating func remover(_ element: Element) {
        self.removeAll { $0.id == element.id }
    }
    
    func encontrar(id: Element.ID) -> Element? {
        return self.first { $0.id == id }
    }
}