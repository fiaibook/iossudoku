import Foundation
import Combine

struct CellIndex: Hashable {
    let row: Int
    let col: Int
}

class GameManager: ObservableObject {
    @Published var puzzle: [[Int]] = []
    @Published var currentGrid: [[Int]] = []
    @Published var solution: [[Int]] = []
    @Published var errorCells: Set<CellIndex> = []
    @Published var hintCells: Set<CellIndex> = []
    @Published var isComplete = false
    @Published var isGameOver = false
    @Published var hintsUsed = 0
    @Published var errorCount = 0
    @Published var lives = GameConfig.Settings.maxLives
    @Published var elapsedTime = 0
    @Published var difficulty: Difficulty = .medium
    @Published var isNoteMode = false
    @Published var notes: [CellIndex: Set<Int>] = [:]
    @Published var currentPuzzleId: String?
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startNewGame()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func startNewGame() {
        // Stop timer
        timer?.invalidate()
        
        // Use pre-generated puzzle with unique solution
        if let pregenPuzzle = SudokuPuzzleManager.shared.getRandomPuzzle(difficulty: difficulty) {
            puzzle = pregenPuzzle.puzzle
            solution = pregenPuzzle.solution
            currentPuzzleId = pregenPuzzle.id
            print("✅ Using pre-generated puzzle: \(pregenPuzzle.id)")
        } else {
            // Fallback to generated puzzle
            puzzle = SudokuEngine.generatePuzzle(difficulty: difficulty)
            solution = puzzle.map { $0.map { $0 } }
            _ = SudokuEngine.solveSudoku(&solution)
            currentPuzzleId = nil
        }
        
        currentGrid = puzzle.map { $0.map { $0 } }
        
        // Reset game state
        errorCells.removeAll()
        hintCells.removeAll()
        isComplete = false
        isGameOver = false
        hintsUsed = 0
        errorCount = 0
        lives = GameConfig.Settings.maxLives
        elapsedTime = 0
        notes.removeAll()
        isNoteMode = false
        
        // Start timer
        startTimer()
    }
    
    func retryGame() {
        // Stop timer
        timer?.invalidate()
        
        // Reset current grid to original puzzle
        currentGrid = puzzle.map { $0.map { $0 } }
        
        // Reset game state
        errorCells.removeAll()
        hintCells.removeAll()
        isComplete = false
        isGameOver = false
        hintsUsed = 0
        errorCount = 0
        lives = GameConfig.Settings.maxLives
        elapsedTime = 0
        notes.removeAll()
        isNoteMode = false
        
        // Start timer
        startTimer()
    }
    
    func setNumber(row: Int, col: Int, number: Int) {
        guard puzzle[row][col] == 0 else { return }
        guard !isGameOver else { return }
        
        // Remove notes for this cell
        let cellIndex = CellIndex(row: row, col: col)
        notes.removeValue(forKey: cellIndex)
        
        currentGrid[row][col] = number
        
        // Check if the number is correct
        if number != solution[row][col] {
            errorCells.insert(CellIndex(row: row, col: col))
            errorCount += 1
            lives -= 1
            
            // Check if game over (no lives left)
            if lives <= 0 {
                isGameOver = true
                timer?.invalidate()
            }
        } else {
            errorCells.remove(CellIndex(row: row, col: col))
            
            // After filling a correct number, remove notes for that number from row, column, and box
            removeNotesForNumber(number: number, row: row, col: col)
        }
        
        // Check if game is complete
        checkCompletion()
    }
    
    // Remove notes for a specific number from row, column, and box
    private func removeNotesForNumber(number: Int, row: Int, col: Int) {
        // Remove notes from the row
        for c in 0..<9 {
            let idx = CellIndex(row: row, col: c)
            if var noteSet = notes[idx] {
                noteSet.remove(number)
                if noteSet.isEmpty {
                    notes.removeValue(forKey: idx)
                } else {
                    notes[idx] = noteSet
                }
            }
        }
        
        // Remove notes from the column
        for r in 0..<9 {
            let idx = CellIndex(row: r, col: col)
            if var noteSet = notes[idx] {
                noteSet.remove(number)
                if noteSet.isEmpty {
                    notes.removeValue(forKey: idx)
                } else {
                    notes[idx] = noteSet
                }
            }
        }
        
        // Remove notes from the box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<boxRow+3 {
            for c in boxCol..<boxCol+3 {
                let idx = CellIndex(row: r, col: c)
                if var noteSet = notes[idx] {
                    noteSet.remove(number)
                    if noteSet.isEmpty {
                        notes.removeValue(forKey: idx)
                    } else {
                        notes[idx] = noteSet
                    }
                }
            }
        }
    }
    
    func toggleNoteMode() {
        isNoteMode.toggle()
    }
    
    func toggleNote(row: Int, col: Int, number: Int) {
        guard puzzle[row][col] == 0 else { return }
        guard currentGrid[row][col] == 0 else { return }
        
        let cellIndex = CellIndex(row: row, col: col)
        
        if notes[cellIndex] == nil {
            notes[cellIndex] = [number]
        } else if notes[cellIndex]!.contains(number) {
            notes[cellIndex]!.remove(number)
        } else {
            notes[cellIndex]!.insert(number)
        }
    }
    
    func clearCell(row: Int, col: Int) {
        guard puzzle[row][col] == 0 else { return }
        
        currentGrid[row][col] = 0
        errorCells.remove(CellIndex(row: row, col: col))
        
        // 清除该格子的笔记
        let cellIndex = CellIndex(row: row, col: col)
        notes.removeValue(forKey: cellIndex)
    }
    
    func getHint() -> (row: Int, col: Int, value: Int)? {
        guard let hint = SudokuEngine.getHint(puzzle: puzzle, current: currentGrid) else {
            return nil
        }
        
        // 直接填入，不要调用setNumber来避免笔记消除逻辑
        let cellIndex = CellIndex(row: hint.row, col: hint.col)
        notes.removeValue(forKey: cellIndex)
        currentGrid[hint.row][hint.col] = hint.value
        
        // 标记为提示单元格
        hintCells.insert(cellIndex)
        errorCells.remove(cellIndex)
        
        hintsUsed += 1
        
        // 填入正确数字后，从该行、该列、该宫格中清除该数字的笔记
        removeNotesForNumber(number: hint.value, row: hint.row, col: hint.col)
        
        // 检查是否完成
        checkCompletion()
        
        return hint
    }
    
    // Check if a number is completely filled in the grid
    func isNumberComplete(_ number: Int) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if currentGrid[row][col] == number {
                    continue
                }
                // If this position should contain the number but is not filled, it's incomplete
                if solution[row][col] == number && currentGrid[row][col] != number {
                    return false
                }
            }
        }
        return true
    }
    
    private func checkCompletion() {
        if SudokuEngine.isComplete(currentGrid) && SudokuEngine.isCorrect(currentGrid) {
            isComplete = true
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: GameConfig.Settings.timerInterval, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
}
