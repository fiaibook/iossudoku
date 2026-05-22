import SwiftUI

struct GameConfig {
    // MARK: - Color Configuration
    struct Colors {
        // Grid line colors
        static let outerBorder = Color.gray
        static let boxBorder = Color.gray
        static let cellBorder = Color.gray.opacity(0.3)
        
        // Grid line widths
        static let outerBorderWidth: CGFloat = 2.0
        static let boxBorderWidth: CGFloat = 0.5
        static let cellBorderWidth: CGFloat = 0.5
        
        // Cell backgrounds
        static let cellBackground = Color.white
        static let boxAlternateBackground = Color.gray.opacity(0.08)
        
        // Number colors (unified dark brown)
        static let originalNumber = Color.brown
        static let userNumber = Color.brown
        static let hintNumber = Color.brown
        
        // Highlight colors
        static let selectedBackground = Color.orange
        static let selectedNumber = Color.white
        static let highlightRowCol = Color.yellow.opacity(0.3)
        static let highlightBox = Color.yellow.opacity(0.2)
        static let highlightSameNumber = Color.green.opacity(0.4)
        
        // Error colors
        static let errorBackground = Color.red.opacity(0.2)
        static let errorNumber = Color.red
        
        // Button colors
        static let numberButtonEnabled = Color.blue
        static let numberButtonDisabled = Color.gray.opacity(0.3)
        
        // Action buttons
        static let hintButton = Color.orange
        static let clearButton = Color.red
        static let newGameButton = Color.green
    }
    
    // MARK: - Difficulty Configuration
    struct DifficultyConfig {
        let name: String
        let description: String
        let cellsToRemove: Int
        
        static let easy = DifficultyConfig(name: "简单", description: "移除30个格子", cellsToRemove: 30)
        static let medium = DifficultyConfig(name: "中等", description: "移除45个格子", cellsToRemove: 45)
        static let hard = DifficultyConfig(name: "困难", description: "移除55个格子", cellsToRemove: 55)
        
        static func config(for difficulty: Difficulty) -> DifficultyConfig {
            switch difficulty {
            case .easy: return easy
            case .medium: return medium
            case .hard: return hard
            }
        }
    }
    
    // MARK: - Game Settings
    struct Settings {
        static let gridSize = 9
        static let boxSize = 3
        static let maxNumber = 9
        static let maxLives = 3
        
        // Timer configuration
        static let timerInterval: TimeInterval = 1.0
        
        // Local storage keys
        static let recordsKey = "SudokuGameRecords"
        static let userInfoKey = "SudokuGameUserInfo"
    }
}