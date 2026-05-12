import Foundation

enum GridType: String, CaseIterable, Identifiable {

    case none = "No Grid"

    case ruleOfThirdsWithDiagonals = "Rule of Thirds"
    
    case symmetry = "Symmetry"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .none:
            return "square.dashed"
        case .ruleOfThirdsWithDiagonals:
            return "grid.circle"
        case .symmetry:
            return "plus.circle"
        }
    }
    
    /// Cycles to the next grid type in order.
    var next: GridType {
        let all = GridType.allCases
        guard let currentIndex = all.firstIndex(of: self) else { return .none }
        let nextIndex = all.index(after: currentIndex)
        return nextIndex < all.endIndex ? all[nextIndex] : all[all.startIndex]
    }
}
