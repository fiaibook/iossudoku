import Foundation

// Sudoku Game Engine
class SudokuEngine {
    
    // Generate a complete Sudoku solution
    static func generateSolution() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = solveSudoku(&grid)
        return grid
    }
    
    // Generate a playable Sudoku puzzle (does not enforce unique solution for speed)
    static func generatePuzzle(difficulty: Difficulty = .medium) -> [[Int]] {
        let solution = generateSolution()
        var puzzle = solution
        
        // Determine number of cells to remove based on difficulty
        let cellsToRemove: Int
        switch difficulty {
        case .easy:
            cellsToRemove = 30
        case .medium:
            cellsToRemove = 45
        case .hard:
            cellsToRemove = 55
        }
        
        // Randomly remove cells
        var remainingCells: [(row: Int, col: Int)] = []
        for r in 0..<9 {
            for c in 0..<9 {
                remainingCells.append((r, c))
            }
        }
        remainingCells.shuffle()
        
        var removedCount = 0
        for (r, c) in remainingCells where removedCount < cellsToRemove {
            puzzle[r][c] = 0
            removedCount += 1
        }
        
        return puzzle
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
    
    // Validate if a number can be placed at a given position
    static func isValid(_ grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Check row
        for i in 0..<9 {
            if grid[row][i] == num {
                return false
            }
        }
        
        // Check column
        for i in 0..<9 {
            if grid[i][col] == num {
                return false
            }
        }
        
        // Check 3x3 box
        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[startRow + i][startCol + j] == num {
                    return false
                }
            }
        }
        
        return true
    }
    
    // Get hint - returns the next number and position to fill
    static func getHint(puzzle: [[Int]], current: [[Int]]) -> (row: Int, col: Int, value: Int)? {
        // Find first empty cell
        for row in 0..<9 {
            for col in 0..<9 {
                if current[row][col] == 0 {
                    // Try to find a unique possible number
                    var possibleNumbers: [Int] = []
                    for num in 1...9 {
                        if isValid(current, row: row, col: col, num: num) {
                            possibleNumbers.append(num)
                        }
                    }
                    
                    // If only one possible number, return it
                    if possibleNumbers.count == 1 {
                        return (row, col, possibleNumbers[0])
                    }
                    
                    // Otherwise, solve the entire puzzle and return the correct answer
                    var gridCopy = current
                    if solveSudoku(&gridCopy) {
                        return (row, col, gridCopy[row][col])
                    }
                }
            }
        }
        return nil
    }
    
    // Check if grid is complete (no empty cells)
    static func isComplete(_ grid: [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    return false
                }
            }
        }
        return true
    }
    
    // Check if grid is correct (valid Sudoku solution)
    static func isCorrect(_ grid: [[Int]]) -> Bool {
        // Check each row
        for row in 0..<9 {
            var seen = Set<Int>()
            for col in 0..<9 {
                let num = grid[row][col]
                if num == 0 || seen.contains(num) {
                    return false
                }
                seen.insert(num)
            }
        }
        
        // Check each column
        for col in 0..<9 {
            var seen = Set<Int>()
            for row in 0..<9 {
                let num = grid[row][col]
                if num == 0 || seen.contains(num) {
                    return false
                }
                seen.insert(num)
            }
        }
        
        // Check each 3x3 box
        for boxRow in 0..<3 {
            for boxCol in 0..<3 {
                var seen = Set<Int>()
                for i in 0..<3 {
                    for j in 0..<3 {
                        let num = grid[boxRow * 3 + i][boxCol * 3 + j]
                        if num == 0 || seen.contains(num) {
                            return false
                        }
                        seen.insert(num)
                    }
                }
            }
        }
        
        return true
    }
}

// Difficulty enum
enum Difficulty: Codable {
    case easy
    case medium
    case hard
}
