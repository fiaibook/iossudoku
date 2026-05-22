//
//  SudokuPuzzles.swift
//  SudokuGame
//


import Foundation

// Sudoku puzzle model
struct SudokuPuzzle: Codable, Identifiable {
    let id: String
    let difficulty: String
    let puzzle: [[Int]]
    let solution: [[Int]]
}

// Puzzle file structure
struct PuzzleFile: Codable {
    let version: String
    let generatedAt: String
    let puzzles: [SudokuPuzzle]
}

// Puzzle manager
class SudokuPuzzleManager {
    static let shared = SudokuPuzzleManager()
    
    private(set) var easyPuzzles: [SudokuPuzzle] = []
    private(set) var mediumPuzzles: [SudokuPuzzle] = []
    private(set) var hardPuzzles: [SudokuPuzzle] = []
    
    private init() {
        loadPuzzles()
    }
    
    private func loadPuzzles() {
        guard let url = Bundle.main.url(forResource: "SudokuPuzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let puzzleFile = try? JSONDecoder().decode(PuzzleFile.self, from: data) else {
            print("❌ Failed to load puzzle file")
            return
        }
        
        for puzzle in puzzleFile.puzzles {
            switch puzzle.difficulty {
            case "easy":
                easyPuzzles.append(puzzle)
            case "medium":
                mediumPuzzles.append(puzzle)
            case "hard":
                hardPuzzles.append(puzzle)
            default:
                break
            }
        }
        
        print("✅ Puzzles loaded successfully:")
        print("   Easy: \(easyPuzzles.count)")
        print("   Medium: \(mediumPuzzles.count)")
        print("   Hard: \(hardPuzzles.count)")
    }
    
    func getRandomPuzzle(difficulty: Difficulty) -> SudokuPuzzle? {
        let puzzles: [SudokuPuzzle]
        switch difficulty {
        case .easy:
            puzzles = easyPuzzles
        case .medium:
            puzzles = mediumPuzzles
        case .hard:
            puzzles = hardPuzzles
        }
        
        guard !puzzles.isEmpty else { return nil }
        return puzzles.randomElement()
    }
}
