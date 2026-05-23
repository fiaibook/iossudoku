import SwiftUI
import Combine

struct GameView: View {
    @StateObject private var gameManager = GameManager()
    @StateObject private var recordsManager = GameRecordsManager()
    @State private var selectedCell: CellIndex? = nil
    @State private var showingNewGame = false
    @State private var showingWinAlert = false
    @State private var showingGameOverAlert = false
    @State private var showingRankings = false
    @State private var showingSettings = false
    @State private var previousErrorCells: Set<CellIndex> = []
    @State private var shakeCell: CellIndex?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 游戏信息
                HStack {
                    Text("时间: \(formatTime(gameManager.elapsedTime))")
                        .font(.headline)
                    Spacer()
                    Text("提示: \(gameManager.hintsUsed)")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<GameConfig.Settings.maxLives, id: \.self) { index in
                            Image(systemName: index < gameManager.lives ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(index < gameManager.lives ? .red : .gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 数独网格
                SudokuGridView(
                    grid: gameManager.currentGrid,
                    originalGrid: gameManager.puzzle,
                    selectedCell: $selectedCell,
                    errorCells: gameManager.errorCells,
                    hintCells: gameManager.hintCells,
                    notes: gameManager.notes,
                    shakeCell: shakeCell
                )
                .aspectRatio(1, contentMode: .fit)
                .padding()
                
                // 数字输入按钮
                NumberInputView(
                    onSelect: { number in
                        if let cell = selectedCell {
                            if gameManager.isNoteMode {
                                gameManager.toggleNote(row: cell.row, col: cell.col, number: number)
                            } else {
                                gameManager.setNumber(row: cell.row, col: cell.col, number: number)
                            }
                        }
                    },
                    isNumberComplete: { number in
                        gameManager.isNumberComplete(number)
                    }
                )
                .padding(.horizontal)
                
                // Control buttons - compact style
                HStack(spacing: 12) {
                    ControlButton(
                        icon: "lightbulb",
                        label: "提示",
                        color: GameConfig.Colors.hintButton,
                        action: {
                            if let hint = gameManager.getHint() {
                                selectedCell = CellIndex(row: hint.row, col: hint.col)
                            }
                        }
                    )
                    
                    NoteControlButton(
                        isNoteMode: gameManager.isNoteMode,
                        action: {
                            gameManager.toggleNoteMode()
                        }
                    )
                    
                    ControlButton(
                        icon: "xmark",
                        label: "清除",
                        color: GameConfig.Colors.clearButton,
                        action: {
                            if let cell = selectedCell {
                                gameManager.clearCell(row: cell.row, col: cell.col)
                            }
                        }
                    )
                    
                    ControlButton(
                        icon: "trophy",
                        label: "排行",
                        color: Color.purple,
                        action: {
                            showingRankings = true
                        }
                    )
                }
                
                // 广告区域
                AdBannerView()
            }
            .navigationTitle("数独游戏")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("设置") {
                        showingSettings = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新游戏") {
                        showingNewGame = true
                    }
                }
            }
            .sheet(isPresented: $showingNewGame) {
                NewGameView(difficulty: $gameManager.difficulty) {
                    gameManager.startNewGame()
                    selectedCell = nil
                }
            }
            .sheet(isPresented: $showingRankings) {
                RankingsView(recordsManager: recordsManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(recordsManager: recordsManager)
            }
            .alert("恭喜！", isPresented: $showingWinAlert) {
                Button("新游戏") {
                    showingNewGame = true
                }
                Button("确定", role: .cancel) { }
            } message: {
                Text("你成功完成了数独！\n用时: \(formatTime(gameManager.elapsedTime))\n使用提示: \(gameManager.hintsUsed)次\n剩余生命: \(gameManager.lives)")
            }
            .alert("游戏结束！", isPresented: $showingGameOverAlert) {
                Button("再试一次") {
                    gameManager.retryGame()
                    selectedCell = nil
                }
                Button("新游戏", role: .cancel) {
                    showingNewGame = true
                }
            } message: {
                Text("生命值耗尽了！\n用时: \(formatTime(gameManager.elapsedTime))\n提示次数: \(gameManager.hintsUsed)次")
            }
            .onReceive(gameManager.$isComplete) { complete in
                if complete {
                    let record = GameRecord(
                        difficulty: gameManager.difficulty,
                        errorCount: gameManager.errorCount,
                        hintCount: gameManager.hintsUsed,
                        elapsedTime: gameManager.elapsedTime,
                        date: Date(),
                        puzzleId: gameManager.currentPuzzleId
                    )
                    recordsManager.addRecord(record)
                    showingWinAlert = true
                }
            }
            .onReceive(gameManager.$isGameOver) { gameOver in
                if gameOver {
                    showingGameOverAlert = true
                }
            }
            .onChange(of: gameManager.errorCells) { newErrorCells in
                // 检测是否有新增错误
                let addedErrors = newErrorCells.subtracting(previousErrorCells)
                if let newError = addedErrors.first {
                    shakeCell = newError
                    // 清除后重置，以便下次再次触发
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        shakeCell = nil
                    }
                }
                previousErrorCells = newErrorCells
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// 控制按钮组件
struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// 笔记控制按钮组件
struct NoteControlButton: View {
    let isNoteMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "pencil.tip")
                        .font(.title2)
                        .foregroundColor(isNoteMode ? Color.orange : Color.blue)
                    Text(isNoteMode ? "on" : "off")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isNoteMode ? Color.green : Color.gray.opacity(0.7))
                        .clipShape(Capsule())
                        .offset(x: 10, y: -8)
                }
                Text("笔记")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// 数独网格视图
struct SudokuGridView: View {
    let grid: [[Int]]
    let originalGrid: [[Int]]
    @Binding var selectedCell: CellIndex?
    let errorCells: Set<CellIndex>
    let hintCells: Set<CellIndex>
    let notes: [CellIndex: Set<Int>]
    let shakeCell: CellIndex?
    
    private var selectedValue: Int? {
        guard let cell = selectedCell, grid[cell.row][cell.col] != 0 else {
            return nil
        }
        return grid[cell.row][cell.col]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / 9
            
            ZStack {
                // 背景和单元格层
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                let cellIndex = CellIndex(row: row, col: col)
                                let shouldShake = shakeCell?.row == row && shakeCell?.col == col
                                CellView(
                                    value: grid[row][col],
                                    isOriginal: originalGrid[row][col] != 0,
                                    isHint: hintCells.contains(cellIndex),
                                    isSelected: selectedCell?.row == row && selectedCell?.col == col,
                                    isError: errorCells.contains(cellIndex),
                                    isHighlightedRowCol: selectedCell?.row == row || selectedCell?.col == col,
                                    isHighlightedBox: isInSameBox(row: row, col: col),
                                    isHighlightedSameNumber: selectedValue != nil && grid[row][col] == selectedValue,
                                    notes: notes[cellIndex],
                                    row: row,
                                    col: col,
                                    shouldShake: shouldShake
                                )
                                .frame(width: cellSize, height: cellSize)
                                .onTapGesture {
                                    selectedCell = cellIndex
                                }
                            }
                        }
                    }
                }
                
                // 3x3 box borders layer (drawn separately on top)
                ZStack {
                    // Outer border
                    Rectangle()
                        .stroke(GameConfig.Colors.outerBorder, lineWidth: GameConfig.Colors.outerBorderWidth)
                    
                    // 3x3 box dividers (thicker)
                    Path { path in
                        // Horizontal dividers (below rows 3 and 6)
                        for i in 1...2 {
                            let y = cellSize * CGFloat(3 * i)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        // Vertical dividers (right of columns 3 and 6)
                        for i in 1...2 {
                            let x = cellSize * CGFloat(3 * i)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.width))
                        }
                    }
                    .stroke(GameConfig.Colors.boxBorder, lineWidth: GameConfig.Colors.boxBorderWidth * 2)
                }
            }
        }
    }
    
    private func isInSameBox(row: Int, col: Int) -> Bool {
        guard let selected = selectedCell else { return false }
        let boxRow = row / 3
        let boxCol = col / 3
        let selectedBoxRow = selected.row / 3
        let selectedBoxCol = selected.col / 3
        return boxRow == selectedBoxRow && boxCol == selectedBoxCol
    }
}

// 单元格视图
struct CellView: View {
    let value: Int
    let isOriginal: Bool
    let isHint: Bool
    let isSelected: Bool
    let isError: Bool
    let isHighlightedRowCol: Bool
    let isHighlightedBox: Bool
    let isHighlightedSameNumber: Bool
    let notes: Set<Int>?
    let row: Int
    let col: Int
    let shouldShake: Bool
    
    var body: some View {
        ZStack {
            backgroundColor
            
            // 内部细线边框
            Rectangle()
                .stroke(GameConfig.Colors.cellBorder, lineWidth: GameConfig.Colors.cellBorderWidth)
            
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: 24, weight: isOriginal ? .bold : .regular))
                    .foregroundColor(textColor)
                    .shake(trigger: shouldShake)
            } else if let notes = notes, !notes.isEmpty {
                NoteGridView(notes: notes)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return GameConfig.Colors.selectedBackground
        } else if isError {
            return GameConfig.Colors.errorBackground
        } else if isHighlightedSameNumber && !isSelected {
            return GameConfig.Colors.highlightSameNumber
        } else if isHighlightedRowCol {
            return GameConfig.Colors.highlightRowCol
        } else if isHighlightedBox && !isHighlightedRowCol {
            return GameConfig.Colors.highlightBox
        } else {
            let boxRow = row / 3
            let boxCol = col / 3
            return (boxRow + boxCol) % 2 == 0 ? GameConfig.Colors.cellBackground : GameConfig.Colors.boxAlternateBackground
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return GameConfig.Colors.selectedNumber
        } else if isError {
            return GameConfig.Colors.errorNumber
        } else if isOriginal {
            return GameConfig.Colors.originalNumber
        } else if isHint {
            return GameConfig.Colors.hintNumber
        } else {
            return GameConfig.Colors.userNumber
        }
    }
}

// Note grid view
struct NoteGridView: View {
    let notes: Set<Int>
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { col in
                        let number = row * 3 + col + 1
                        if notes.contains(number) {
                            Text("\(number)")
                                .font(.system(size: 8, weight: .light))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
        .padding(2)
    }
}

// 数字输入视图
struct NumberInputView: View {
    let onSelect: (Int) -> Void
    let isNumberComplete: (Int) -> Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { number in
                if isNumberComplete(number) {
                    // 隐藏但保持相同尺寸的占位符
                    Color.clear
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                } else {
                    Button(action: {
                        onSelect(number)
                    }) {
                        Text("\(number)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.brown)
                    }
                }
            }
        }
    }
}

// 新游戏视图
struct NewGameView: View {
    @Binding var difficulty: Difficulty
    let onStart: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("选择难度")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    DifficultyButton(title: GameConfig.DifficultyConfig.easy.name, 
                                    description: GameConfig.DifficultyConfig.easy.description, 
                                    difficulty: .easy, 
                                    selected: difficulty == .easy) {
                        difficulty = .easy
                    }
                    
                    DifficultyButton(title: GameConfig.DifficultyConfig.medium.name, 
                                    description: GameConfig.DifficultyConfig.medium.description, 
                                    difficulty: .medium, 
                                    selected: difficulty == .medium) {
                        difficulty = .medium
                    }
                    
                    DifficultyButton(title: GameConfig.DifficultyConfig.hard.name, 
                                    description: GameConfig.DifficultyConfig.hard.description, 
                                    difficulty: .hard, 
                                    selected: difficulty == .hard) {
                        difficulty = .hard
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    onStart()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("开始游戏")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(GameConfig.Colors.newGameButton)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("新游戏")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DifficultyButton: View {
    let title: String
    let description: String
    let difficulty: Difficulty
    let selected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(selected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.blue : Color.gray, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 排行榜视图
struct RankingsView: View {
    @ObservedObject var recordsManager: GameRecordsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("排行榜")) {
                    if recordsManager.records.isEmpty {
                        Text("暂无游戏记录")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(recordsManager.getRankings().enumerated()), id: \.element.id) { index, record in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(index < 3 ? Color.yellow : Color.gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(record.difficultyName)")
                                        .font(.headline)
                                    HStack {
                                        Text("用时: \(record.formattedTime)")
                                        Text("提示: \(record.hintCount)")
                                        Text("错误: \(record.errorCount)")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    Text(record.formattedDate)
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text("得分: \(record.score)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("排行榜")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Ad banner view
struct AdBannerView: View {
    @State private var adIndex = 0
    @State private var timer: Timer?
    
    let ads = [
        "下载最新游戏，体验更精彩内容！",
        "关注公众号，获取更多数独技巧！",
        "推荐给朋友，一起享受数独乐趣！",
        "购买完整版，解锁更多高级功能！"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.top, 0)
            
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                
                Text("广告")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(ads[adIndex])
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .transition(.opacity)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.yellow.opacity(0.1))
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    adIndex = (adIndex + 1) % ads.count
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

// Settings view
struct SettingsView: View {
    @ObservedObject var recordsManager: GameRecordsManager
    @State private var newUsername: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0 (1)"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("用户信息")) {
                    HStack {
                        Text("用户名")
                        Spacer()
                        TextField("请输入用户名", text: $newUsername)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                        Button(action: {
                            if !newUsername.isEmpty {
                                recordsManager.updateUsername(newUsername)
                            }
                        }) {
                            Text("保存")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("用户ID")
                        Spacer()
                        Text(recordsManager.userInfo.userId)
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本号")
                        Spacer()
                        Text(appVersion)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("清除数据")) {
                    Button(action: {
                        recordsManager.records.removeAll()
                        if let data = try? JSONEncoder().encode(recordsManager.records) {
                            UserDefaults.standard.set(data, forKey: GameConfig.Settings.recordsKey)
                        }
                    }) {
                        Text("清除所有游戏记录")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                newUsername = recordsManager.userInfo.username
            }
        }
    }
}

// MARK: - Shake animation Modifier
struct Shake: ViewModifier {
    let trigger: Bool
    @State private var shakeTrigger = false
    
    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeTrigger ? 1.0 : 0.0))
            .onChange(of: trigger) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0)) {
                    shakeTrigger = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeTrigger = false
                }
            }
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 2) * 8 * min(animatableData, 1.0)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(Shake(trigger: trigger))
    }
}
