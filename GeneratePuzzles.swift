#!/usr/bin/env swift
import Foundation

// Difficulty enum
enum Difficulty: String, Codable {
    case easy
    case medium
    case hard
}

// Sudoku puzzle structure
struct SudokuPuzzle: Codable, Identifiable {
    let id: String
    let difficulty: Difficulty
    let puzzle: [[Int]]
    let solution: [[Int]]
}

// Sudoku generator engine
class SudokuGenerator {
    
    // Generate a complete Sudoku solution
    static func generateSolution() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = solveSudoku(&grid)
        return grid
    }
    
    // Solve Sudoku using backtracking algorithm
    static func solveSudoku(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    let numbers = (1...9).shuffled()
                    for num in numbers {
                        if isValid(grid, row: row, col: col, num: num) {
                            grid[row][col] = num
                            if solveSudoku(&grid) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    // 验证数字是否有效
    static func isValid(_ grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        for i in 0..<9 {
            if grid[row][i] == num { return false }
        }
        for i in 0..<9 {
            if grid[i][col] == num { return false }
        }
        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[startRow + i][startCol + j] == num { return false }
            }
        }
        return true
    }
    
    // 检查谜题是否有唯一解
    static func hasUniqueSolution(_ puzzle: [[Int]]) -> Bool {
        var solutionCount = 0
        var grid = puzzle
        countSolutions(&grid, solutionCount: &solutionCount, maxSolutions: 2)
        return solutionCount == 1
    }
    
    // 计算解的数量（有上限优化）
    private static func countSolutions(_ grid: inout [[Int]], solutionCount: inout Int, maxSolutions: Int) {
        if solutionCount >= maxSolutions { return }
        
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    for num in 1...9 {
                        if isValid(grid, row: row, col: col, num: num) {
                            grid[row][col] = num
                            countSolutions(&grid, solutionCount: &solutionCount, maxSolutions: maxSolutions)
                            grid[row][col] = 0
                            if solutionCount >= maxSolutions { return }
                        }
                    }
                    return
                }
            }
        }
        solutionCount += 1
    }
    
    // 生成一个有唯一解的谜题
    static func generateUniquePuzzle(difficulty: Difficulty) -> SudokuPuzzle? {
        let cellsToRemove: Int
        switch difficulty {
        case .easy: cellsToRemove = 30
        case .medium: cellsToRemove = 45
        case .hard: cellsToRemove = 55
        }
        
        var attempts = 0
        while attempts < 100 {
            attempts += 1
            
            let solution = generateSolution()
            var puzzle = solution
            
            var remainingCells: [(row: Int, col: Int)] = []
            for r in 0..<9 {
                for c in 0..<9 {
                    remainingCells.append((r, c))
                }
            }
            remainingCells.shuffle()
            
            var removedCount = 0
            var puzzleCopy = puzzle
            
            for (r, c) in remainingCells where removedCount < cellsToRemove {
                let originalValue = puzzleCopy[r][c]
                puzzleCopy[r][c] = 0
                
                if hasUniqueSolution(puzzleCopy) {
                    puzzle[r][c] = 0
                    removedCount += 1
                } else {
                    puzzleCopy[r][c] = originalValue
                }
            }
            
            if removedCount >= cellsToRemove / 2 {
                let id = UUID().uuidString
                return SudokuPuzzle(id: id, difficulty: difficulty, puzzle: puzzle, solution: solution)
            }
        }
        return nil
    }
}

// MARK: - Main Program
print("🚀 Starting to pre-generate Sudoku puzzles...")

let puzzlesPerDifficulty = 5 // Test mode: generate 5 puzzles per difficulty
var allPuzzles: [SudokuPuzzle] = []

let difficulties: [Difficulty] = [.easy, .medium, .hard]

for difficulty in difficulties {
    print("📊 正在生成 \(difficulty.rawValue) 难度的谜题 (\(puzzlesPerDifficulty)个)...")
    
    var generated = 0
    var startTime = Date()
    
    while generated < puzzlesPerDifficulty {
        if let puzzle = SudokuGenerator.generateUniquePuzzle(difficulty: difficulty) {
            allPuzzles.append(puzzle)
            generated += 1
            
            if generated % 10 == 0 {
                let elapsed = Date().timeIntervalSince(startTime)
                print("  ✅ 已完成 \(generated)/\(puzzlesPerDifficulty) (\(String(format: "%.1f", elapsed))s)")
            }
        }
    }
    
    let totalTime = Date().timeIntervalSince(startTime)
    print("🎉 \(difficulty.rawValue) 难度完成！共耗时 \(String(format: "%.1f", totalTime))s")
}

// 保存到文件
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

if let data = try? encoder.encode(allPuzzles) {
    let fileManager = FileManager.default
    let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let outputFile = currentDir.appendingPathComponent("SudokuPuzzles.json")
    
    try? data.write(to: outputFile)
    print("\n💾 谜题已保存到: \(outputFile.path)")
    print("📦 总计生成 \(allPuzzles.count) 个谜题")
    print("📊 各难度统计:")
    for difficulty in difficulties {
        let count = allPuzzles.filter { $0.difficulty == difficulty }.count
        print("   \(difficulty.rawValue): \(count) 个")
    }
}
