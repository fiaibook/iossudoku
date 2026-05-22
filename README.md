# Sudoku Game - iOS Version

A native Sudoku game designed for iPhone, developed using SwiftUI.

## Features

### Core Game Features
- ✅ Complete Sudoku game logic
- ✅ Three difficulty levels (Easy, Medium, Hard)
- ✅ Smart hint system
- ✅ Error detection and marking
- ✅ Game timer
- ✅ Beautiful user interface
- ✅ Support for iPhone and iPad

### Smart Assist Features
- ✅ **Hint Mode**: Click a number to highlight its row, column, and 3x3 box
- ✅ **Same Number Highlight**: Same numbers in other boxes show green background
- ✅ **Three-layer Border**: Thick outer border, medium box border, thin cell border
- ✅ **Number Color Differentiation**: Original numbers (dark brown), user input (lighter brown), selected (white + orange background)

### Number Input Optimization
- ✅ **Auto-hide Buttons**: Number buttons automatically hide when all instances of that number are filled

### Game Records and Leaderboard
- ✅ **Record Saving**: Error count, hint count, completion time, difficulty level
- ✅ **Leaderboard System**: Sorted by score, saves last 20 records
- ✅ **User Settings**: Custom username, clear records

## Project Structure

```
SudokuGame/
├── SudokuGame.xcodeproj/          # Xcode project files
├── SudokuGame/                    # Source code
│   ├── SudokuGameApp.swift        # App entry point
│   ├── GameView.swift             # Main game interface
│   ├── SudokuEngine.swift         # Core Sudoku algorithm
│   ├── GameManager.swift          # Game state management
│   ├── GameConfig.swift           # Configuration management (new)
│   ├── GameRecords.swift          # Records and leaderboard (new)
│   └── Info.plist                # App configuration
├── PROJECT_DOCUMENTATION.md       # Complete project documentation
├── PROJECT_SUMMARY.md             # Project summary
├── QUICKSTART.md                  # Quick start guide
└── README.md                      # This document
```

## How to Build and Run

### Method 1: Using Xcode (Recommended)

1. **Install Xcode**
   - Download and install Xcode 15.0 or later from the Mac App Store
   - Ensure Xcode Command Line Tools are installed

2. **Open the project**
   ```bash
   cd SudokuGame
   open SudokuGame.xcodeproj
   ```

3. **Configure Developer Account**
   - In Xcode, select the "SudokuGame" project in the project navigator
   - Go to the "Signing & Capabilities" tab
   - Select your development team
   - If you don't have a developer account, select "Sign to Run Locally"

4. **Select Target Device**
   - In the Xcode toolbar, select the target device
   - You can choose a simulator (e.g., iPhone 17) or a physical device

5. **Build and Run**
   - Click the run button (▶️) or press `Cmd + R`
   - Wait for compilation to complete, the app will launch automatically

### Method 2: Build Using Command Line

```bash
cd SudokuGame
xcodebuild -project SudokuGame.xcodeproj -scheme SudokuGame -configuration Debug build
```

## How to Play

### 1. Start a Game
- A new game starts automatically when you open the app
- Tap "New Game" in the top right corner to select difficulty

### 2. Fill in Numbers
- Tap an empty cell to select it
- Tap a number button at the bottom to fill in a number
- Original numbers (dark brown, bold) cannot be modified

### 3. Use Hints
- Tap the "Hint" button for help
- The system will automatically fill in a correct number
- Hint count is recorded

### 4. Clear Numbers
- Select a cell and tap the "Clear" button
- Only user-filled numbers can be cleared

### 5. Highlight Assist
- Tap any number cell
- The row, column, and 3x3 box containing this number are highlighted (light yellow)
- Same numbers in other boxes show green background
- Selected cell shows orange background with white text

### 6. View Leaderboard
- Tap the "Leaderboard" button to view history records
- Displays score, difficulty, time, and other information

### 7. Settings
- Tap "Settings" to enter the settings page
- Change username
- Clear all game records

### 8. Complete the Game
- The game completes when all cells are correctly filled
- Shows time taken, hint count, and error count
- Automatically saves record to leaderboard

## Technical Details

### Core Algorithms
- **Sudoku Generation**: Uses backtracking algorithm to generate valid Sudoku puzzles
- **Difficulty Control**: Implemented by removing different numbers of cells
- **Hint System**: Intelligently analyzes possible numbers, prioritizes unique solutions
- **Validation System**: Real-time checking of row, column, and box validity

### UI Design
- Declarative UI built with SwiftUI
- Responsive layout that adapts to different screen sizes
- Clear visual feedback (highlight, selection, errors, etc.)

### Data Persistence
- Uses UserDefaults to store game records
- Supports custom usernames
- Saves last 20 records

## Score Calculation

```
Score = Base Score + Time Bonus - Error Penalty - Hint Penalty
```

- **Base Score**: Easy 100 points, Medium 200 points, Hard 300 points
- **Time Bonus**: max(0, 300 - time in seconds), shorter time = more bonus
- **Error Penalty**: Number of errors × 10 points
- **Hint Penalty**: Number of hints × 5 points

## System Requirements

- iOS 15.6 or later
- Xcode 15.0 or later (for development)
- Swift 5.0

## Complete Documentation

For more detailed information, please see:
- [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) - Complete project documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project summary

## License

This project is for learning and personal use only.

## Update History

### v2.0 - 2026-05-03
- ✨ New: Complete game records and leaderboard system
- ✨ New: Smart hint mode (row, column, box, and same number highlighting)
- ✨ New: Three-layer border system and color differentiation
- ✨ New: Auto-hide number buttons
- ✨ New: User settings functionality
- ✨ New: Unified configuration management (GameConfig.swift)
- 🐛 Fixed: All compilation errors and signing issues
- 📝 Improved: Project documentation

### v1.0 - Initial Version
- ✨ Basic Sudoku game functionality