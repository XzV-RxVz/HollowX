import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(const SxCGamesApp());

class SxCGamesApp extends StatelessWidget {
  const SxCGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SxC Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C3AED),
        scaffoldBackgroundColor: const Color(0xFF0F0D1A),
        fontFamily: 'Poppins',
      ),
      home: const GameHubPage(),
    );
  }
}

// ==================== GAME HUB PAGE ====================
class GameHubPage extends StatelessWidget {
  const GameHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text(
          '𝗦𝗫𝗖 𝗚𝗔𝗠𝗘𝗦 𝗔𝗥𝗘𝗡𝗔',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1625),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                GameCard(
                  title: 'MEMORY CARD',
                  icon: Icons.grid_view,
                  color: const Color(0xFF3B82F6),
                  gameRules: GameRules.memoryCard,
                  gameBuilder: (context) => const MemoryCardGame(),
                ),
                GameCard(
                  title: 'BOM SQUAD',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                  gameRules: GameRules.bomSquad,
                  gameBuilder: (context) => const BomSquadGame(),
                ),
                GameCard(
                  title: 'TIC TAC TOE',
                  icon: Icons.close,
                  color: const Color(0xFF10B981),
                  gameRules: GameRules.ticTacToe,
                  gameBuilder: (context) => const TicTacToeGame(),
                ),
                GameCard(
                  title: 'SNAKE',
                  icon: Icons.smartphone,
                  color: const Color(0xFFF59E0B),
                  gameRules: GameRules.snake,
                  gameBuilder: (context) => const SnakeGame(),
                ),
                GameCard(
                  title: 'SUDOKU',
                  icon: Icons.grid_4x4,
                  color: const Color(0xFF8B5CF6),
                  gameRules: GameRules.sudoku,
                  gameBuilder: (context) => const SudokuGame(),
                ),
                GameCard(
                  title: 'PACMAN',
                  icon: Icons.circle,
                  color: const Color(0xFFFBBF24),
                  gameRules: GameRules.pacman,
                  gameBuilder: (context) => const PacmanGame(),
                ),
                GameCard(
                  title: 'SHOOTING',
                  icon: Icons.sports_esports,
                  color: const Color(0xFFEC4899),
                  gameRules: GameRules.shooting,
                  gameBuilder: (context) => const ShootingGame(),
                ),
                GameCard(
                  title: 'BLOCK BLAST',
                  icon: Icons.crop_square,
                  color: const Color(0xFF06B6D4),
                  gameRules: GameRules.blockBlast,
                  gameBuilder: (context) => const BlockBlastGame(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== GAME RULES ====================
class GameRules {
  static const Map<String, dynamic> memoryCard = {
    'title': 'MEMORY CARD',
    'description': 'Cocokkan semua pasangan kartu yang sama!',
    'rules': [
      'Klik kartu untuk membukanya',
      'Cari pasangan kartu dengan emoji yang sama',
      'Setiap pasangan yang cocok mendapat 10 poin',
      'Semakin sedikit langkah, semakin bagus!',
      'Game selesai jika semua kartu sudah terbuka',
    ],
    'tips': 'Ingat posisi kartu yang sudah terbuka!',
  };
  
  static const Map<String, dynamic> bomSquad = {
    'title': 'BOM SQUAD',
    'description': 'Temukan kotak aman, hindari bom!',
    'rules': [
      'Grid 5x5 berisi 5 bom tersembunyi',
      'Klik kotak untuk membukanya',
      'Jika kena bom → GAME OVER',
      'Setiap kotak aman memberi +10 poin',
      'Buka semua kotak aman untuk MENANG!',
    ],
    'tips': 'Angka menunjukkan jumlah bom di sekitarnya!',
  };
  
  static const Map<String, dynamic> ticTacToe = {
    'title': 'TIC TAC TOE',
    'description': 'Kalahkan AI dalam permainan X O!',
    'rules': [
      'Giliranmu sebagai X, AI sebagai O',
      'Buat garis 3 lurus (horizontal, vertikal, diagonal)',
      'Pilih level kesulitan: Easy, Medium, Hard, Super Impossible',
      'Super Impossible: AI tidak bisa dikalahkan!',
      'Best of 5 rounds untuk menentukan pemenang',
    ],
    'tips': 'Blokir gerakan AI untuk menang!',
  };
  
  static const Map<String, dynamic> snake = {
    'title': 'SNAKE',
    'description': 'Makan makanan, jangan menabrak!',
    'rules': [
      'Gunakan tombol panah untuk menggerakkan ular',
      'Makan makanan merah untuk menambah panjang',
      'Setiap makanan memberi +10 poin',
      'Jangan menabrak tembok atau tubuh sendiri',
      'Game berakhir jika ular menabrak!',
    ],
    'tips': 'Jangan terlalu cepat, atur strategi!',
  };
  
  static const Map<String, dynamic> sudoku = {
    'title': 'SUDOKU',
    'description': 'Isi angka 1-9 tanpa pengulangan!',
    'rules': [
      'Setiap baris harus berisi angka 1-9 tanpa duplikat',
      'Setiap kolom harus berisi angka 1-9 tanpa duplikat',
      'Setiap kotak 3x3 harus berisi angka 1-9 tanpa duplikat',
      'Angka biru adalah soal (tidak bisa diubah)',
      'Angka hijau adalah jawabanmu',
    ],
    'tips': 'Mulai dari angka yang paling mungkin!',
  };
  
  static const Map<String, dynamic> pacman = {
    'title': 'PACMAN',
    'description': 'Makan semua titik, hindari hantu!',
    'rules': [
      'Gunakan tombol panah untuk gerakkan Pacman',
      'Makan semua titik kuning untuk menang',
      'Hindari 4 hantu yang bergerak acak',
      'Jika terkena hantu → GAME OVER',
      'Semua titik habis = MENANG!',
    ],
    'tips': 'Perhatikan pergerakan hantu!',
  };
  
  static const Map<String, dynamic> shooting = {
    'title': 'SHOOTING GALLERY',
    'description': 'Tembak target sebanyak mungkin!',
    'rules': [
      'Klik target merah yang muncul',
      'Setiap target memberi +10 poin',
      'Target menghilang setelah 2 detik',
      'Waktu terbatas 30 detik',
      'Semakin cepat, semakin banyak skor!',
    ],
    'tips': 'Reaksi cepat adalah kuncinya!',
  };
  
  static const Map<String, dynamic> blockBlast = {
    'title': 'BLOCK BLAST',
    'description': 'Geser dan letakkan blok ke grid!',
    'rules': [
      'GESER block ke grid 8x8',
      'Buat baris atau kolom penuh untuk menghapus',
      'Setiap blok punya bentuk berbeda',
      'Semakin banyak baris dihapus, semakin tinggi skor',
      'Game berakhir jika tidak ada tempat untuk blok',
    ],
    'tips': 'Simpan ruang untuk blok besar!',
  };
}

// ==================== GAME CARD WIDGET ====================
class GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> gameRules;
  final Widget Function(BuildContext) gameBuilder;

  const GameCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.gameRules,
    required this.gameBuilder,
  });

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1625),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              gameRules['title'],
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gameRules['description'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '📜 PERATURAN:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(gameRules['rules'].length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: const TextStyle(color: Color(0xFF3B82F6)),
                      ),
                      Expanded(
                        child: Text(
                          gameRules['rules'][index],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, size: 20, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 TIPS: ${gameRules['tips']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: gameBuilder));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('MULAI GAME'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      color: const Color(0xFF1A1625),
      child: InkWell(
        onTap: () => _showRules(context),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== GAME 1: MEMORY CARD ====================
class MemoryCardGame extends StatefulWidget {
  const MemoryCardGame({super.key});

  @override
  State<MemoryCardGame> createState() => _MemoryCardGameState();
}

class _MemoryCardGameState extends State<MemoryCardGame> {
  List<CardModel> cards = [];
  int selectedIndex = -1;
  int moves = 0;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    List<String> emojis = [
      '🍎', '🍎', '🍌', '🍌', '🍒', '🍒', '🍇', '🍇',
      '🥝', '🥝', '🍊', '🍊', '🍉', '🍉', '🍓', '🍓'
    ];
    emojis.shuffle();
    cards = List.generate(emojis.length, (index) => CardModel(id: index, emoji: emojis[index]));
    selectedIndex = -1;
    moves = 0;
    score = 0;
    setState(() {});
  }

  void onCardTap(int index) {
    if (cards[index].isMatched || cards[index].isOpened) return;

    if (selectedIndex == -1) {
      cards[index].isOpened = true;
      selectedIndex = index;
      setState(() {});
    } else {
      cards[index].isOpened = true;
      moves++;

      if (cards[selectedIndex].emoji == cards[index].emoji) {
        cards[selectedIndex].isMatched = true;
        cards[index].isMatched = true;
        score += 10;
        selectedIndex = -1;

        if (cards.every((card) => card.isMatched)) {
          _showGameCompleteDialog();
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          cards[selectedIndex].isOpened = false;
          cards[index].isOpened = false;
          selectedIndex = -1;
          setState(() {});
        });
      }
      setState(() {});
    }
  }

  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Game Complete! 🎉'),
        content: Text('Final Score: $score\nMoves: $moves'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Memory Card'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Score: $score  Moves: $moves'),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onCardTap(index),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (cards[index].isMatched || cards[index].isOpened)
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF1A1625),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
              child: Center(
                child: (cards[index].isOpened || cards[index].isMatched)
                    ? Text(cards[index].emoji, style: const TextStyle(fontSize: 32))
                    : const Icon(Icons.question_mark, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardModel {
  final int id;
  final String emoji;
  bool isOpened;
  bool isMatched;

  CardModel({required this.id, required this.emoji, this.isOpened = false, this.isMatched = false});
}

// ==================== GAME 2: BOM SQUAD ====================
class BomSquadGame extends StatefulWidget {
  const BomSquadGame({super.key});

  @override
  State<BomSquadGame> createState() => _BomSquadGameState();
}

class _BomSquadGameState extends State<BomSquadGame> {
  static const int gridSize = 5;
  static const int totalBombs = 5;
  List<List<bool>> isRevealed = [];
  List<List<bool>> isBomb = [];
  int score = 0;
  int remainingSafe = gridSize * gridSize - totalBombs;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    isRevealed = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
    isBomb = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));

    int bombsPlaced = 0;
    Random random = Random();
    while (bombsPlaced < totalBombs) {
      int row = random.nextInt(gridSize);
      int col = random.nextInt(gridSize);
      if (!isBomb[row][col]) {
        isBomb[row][col] = true;
        bombsPlaced++;
      }
    }

    score = 0;
    remainingSafe = gridSize * gridSize - totalBombs;
    gameOver = false;
    setState(() {});
  }

  void onCellTap(int row, int col) {
    if (gameOver) return;
    if (isRevealed[row][col]) return;

    setState(() {
      isRevealed[row][col] = true;

      if (isBomb[row][col]) {
        gameOver = true;
        _showGameOverDialog(false);
      } else {
        score += 10;
        remainingSafe--;

        if (remainingSafe == 0) {
          gameOver = true;
          _showGameOverDialog(true);
        }
      }
    });
  }

  int getAdjacentBombs(int row, int col) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < gridSize && newCol >= 0 && newCol < gridSize) {
          if (isBomb[newRow][newCol]) count++;
        }
      }
    }
    return count;
  }

  void _showGameOverDialog(bool isWin) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isWin ? '🎉 You Win! 🎉' : '💥 BOOM! 💥'),
        content: Text('Final Score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Bom Squad'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Score: $score  Safe: $remainingSafe'),
          ),
        ],
      ),
      body: Center(
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            int row = index ~/ gridSize;
            int col = index % gridSize;
            bool revealed = isRevealed[row][col];

            return GestureDetector(
              onTap: () => onCellTap(row, col),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: revealed
                      ? (isBomb[row][col] ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                      : const Color(0xFF1A1625),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Center(
                  child: revealed
                      ? (isBomb[row][col]
                          ? const Icon(Icons.warning, color: Colors.white)
                          : Text(
                              getAdjacentBombs(row, col) > 0 ? '${getAdjacentBombs(row, col)}' : '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ))
                      : const Icon(Icons.help_outline, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== GAME 3: TIC TAC TOE (FIXED GRID & LEVELS) ====================
class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> board = List.filled(9, '');
  bool isPlayerTurn = true;
  int playerScore = 0;
  int aiScore = 0;
  bool gameOver = false;
  String difficulty = 'Medium';
  bool showDifficultyPicker = true;

  final List<String> difficulties = ['Easy', 'Medium', 'Hard', 'Super Impossible'];

  void _startGame(String selectedDifficulty) {
    setState(() {
      difficulty = selectedDifficulty;
      showDifficultyPicker = false;
      _resetGame();
    });
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      isPlayerTurn = true;
      gameOver = false;
    });
  }

  void _resetMatch() {
    setState(() {
      playerScore = 0;
      aiScore = 0;
      _resetGame();
    });
  }

  void playerMove(int index) {
    if (board[index] != '' || gameOver || !isPlayerTurn) return;

    setState(() {
      board[index] = 'X';
      isPlayerTurn = false;

      String? winner = _checkWinner();
      if (winner != null) {
        if (winner == 'X') {
          playerScore++;
          _showWinnerDialog('You Win!');
        } else {
          aiScore++;
          _showWinnerDialog('AI Wins!');
        }
        gameOver = true;
      } else if (_isBoardFull()) {
        _showWinnerDialog('Draw!');
        gameOver = true;
      } else {
        Future.delayed(const Duration(milliseconds: 300), aiMove);
      }
    });
  }

  void aiMove() {
    if (gameOver || isPlayerTurn) return;

    int? bestMove;
    
    if (difficulty == 'Easy') {
      bestMove = _getRandomMove();
    } else if (difficulty == 'Medium') {
      bestMove = _getMediumMove();
    } else if (difficulty == 'Hard') {
      bestMove = _getBestMove();
    } else {
      bestMove = _getSuperImpossibleMove();
    }
    
    if (bestMove == null) return;

    if (bestMove >= 0 && bestMove < 9) {
      setState(() {
        board[bestMove!] = 'O';
        isPlayerTurn = true;

        String? winner = _checkWinner();
        if (winner != null) {
          if (winner == 'O') {
            aiScore++;
          } else {
            playerScore++;
          }
          _showWinnerDialog(winner == 'O' ? 'AI Wins!' : 'You Win!');
          gameOver = true;
        } else if (_isBoardFull()) {
          _showWinnerDialog('Draw!');
          gameOver = true;
        }
      });
    }
  }

  int? _getRandomMove() {
    List<int> empty = [];
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') empty.add(i);
    }
    if (empty.isEmpty) return null;
    return empty[Random().nextInt(empty.length)];
  }

  int? _getMediumMove() {
    if (Random().nextDouble() < 0.7) {
      return _getBestMove();
    }
    return _getRandomMove();
  }

  int? _getBestMove() {
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') {
        board[i] = 'O';
        if (_checkWinner() == 'O') {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }
    
    for (int i = 0; i < 9; i++) {
      if (board[i] == '') {
        board[i] = 'X';
        if (_checkWinner() == 'X') {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }
    
    if (board[4] == '') return 4;
    
    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int corner in corners) {
      if (board[corner] == '') return corner;
    }
    
    return _getRandomMove();
  }

  int? _getSuperImpossibleMove() {
    var result = _minimax(board, 0, true);
    int? move = result['index'];
    if (move != null && move >= 0 && move < 9 && board[move] == '') {
      return move;
    }
    return _getRandomMove();
  }

  Map<String, dynamic> _minimax(List<String> currentBoard, int depth, bool isMaximizing) {
    String? winner = _checkWinnerOnBoard(currentBoard);
    
    if (winner == 'O') return {'score': 10 - depth, 'index': null};
    if (winner == 'X') return {'score': depth - 10, 'index': null};
    if (_isBoardFullOnBoard(currentBoard)) return {'score': 0, 'index': null};
    
    if (isMaximizing) {
      int bestScore = -1000;
      int? bestMove;
      
      for (int i = 0; i < 9; i++) {
        if (currentBoard[i] == '') {
          currentBoard[i] = 'O';
          int score = _minimax(currentBoard, depth + 1, false)['score'];
          currentBoard[i] = '';
          
          if (score > bestScore) {
            bestScore = score;
            bestMove = i;
          }
        }
      }
      return {'score': bestScore, 'index': bestMove};
    } else {
      int bestScore = 1000;
      int? bestMove;
      
      for (int i = 0; i < 9; i++) {
        if (currentBoard[i] == '') {
          currentBoard[i] = 'X';
          int score = _minimax(currentBoard, depth + 1, true)['score'];
          currentBoard[i] = '';
          
          if (score < bestScore) {
            bestScore = score;
            bestMove = i;
          }
        }
      }
      return {'score': bestScore, 'index': bestMove};
    }
  }

  String? _checkWinnerOnBoard(List<String> currentBoard) {
    List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var pattern in winPatterns) {
      if (currentBoard[pattern[0]] != '' &&
          currentBoard[pattern[0]] == currentBoard[pattern[1]] &&
          currentBoard[pattern[1]] == currentBoard[pattern[2]]) {
        return currentBoard[pattern[0]];
      }
    }
    return null;
  }

  bool _isBoardFullOnBoard(List<String> currentBoard) {
    return currentBoard.every((cell) => cell != '');
  }

  String? _checkWinner() {
    return _checkWinnerOnBoard(board);
  }

  bool _isBoardFull() {
    return _isBoardFullOnBoard(board);
  }

  void _showSuperWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Super Impossible'),
        content: const Text('Mode ini sangat sulit. Lanjut?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame('Super Impossible');
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  void _showWinnerDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(message),
        content: Text('You: $playerScore  |  AI: $aiScore'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (playerScore >= 3 || aiScore >= 3) {
                setState(() {
                  playerScore = 0;
                  aiScore = 0;
                  showDifficultyPicker = true;
                });
              } else {
                _resetGame();
              }
            },
            child: const Text('Next Round'),
          ),
          if (playerScore >= 3 || aiScore >= 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Menu'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showDifficultyPicker) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0D1A),
        appBar: AppBar(
          title: const Text('Tic Tac Toe'),
          backgroundColor: const Color(0xFF1A1625),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pilih Level Kesulitan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ...difficulties.map((level) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        if (level == 'Super Impossible') {
                          _showSuperWarning();
                        } else {
                          _startGame(level);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: level == 'Super Impossible' 
                            ? Colors.red 
                            : const Color(0xFF1A1625),
                        side: BorderSide(
                          color: level == 'Super Impossible' 
                              ? Colors.red 
                              : const Color(0xFF10B981),
                        ),
                      ),
                      child: Text(level, style: TextStyle(
                        color: level == 'Super Impossible' ? Colors.white : null,
                      )),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: Text('Tic Tac Toe - $difficulty'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetMatch,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('You: $playerScore  AI: $aiScore'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GRID TIC TAC TOE DENGAN GARIS JELAS
            Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1625),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 2),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => playerMove(index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          board[index],
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: board[index] == 'X' 
                                ? const Color(0xFF3B82F6) 
                                : const Color(0xFFEF4444),
                            shadows: [
                              Shadow(
                                color: board[index] == 'X' 
                                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                                    : const Color(0xFFEF4444).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1625),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                side: BorderSide(color: const Color(0xFF7C3AED), width: 1),
              ),
              child: const Text('Reset Round'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== GAME 4: SNAKE ====================
class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 15;
  List<List<int>> snake = [];
  List<int> food = [];
  String direction = 'RIGHT';
  bool isPlaying = true;
  int score = 0;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    snake = [[7, 7], [6, 7], [5, 7], [4, 7]];
    direction = 'RIGHT';
    isPlaying = true;
    score = 0;
    _generateFood();
    _startGame();
  }

  void _startGame() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (isPlaying) _moveSnake();
    });
  }

  void _generateFood() {
    Random random = Random();
    do {
      food = [random.nextInt(gridSize), random.nextInt(gridSize)];
    } while (snake.any((segment) => segment[0] == food[0] && segment[1] == food[1]));
  }

  void _moveSnake() {
    List<int> newHead = List.from(snake.first);
    switch (direction) {
      case 'UP': newHead[0]--; break;
      case 'DOWN': newHead[0]++; break;
      case 'LEFT': newHead[1]--; break;
      case 'RIGHT': newHead[1]++; break;
    }

    if (newHead[0] == food[0] && newHead[1] == food[1]) {
      setState(() {
        snake.insert(0, newHead);
        score += 10;
        _generateFood();
      });
    } else {
      setState(() {
        snake.insert(0, newHead);
        snake.removeLast();
      });
    }

    if (_checkCollision()) {
      setState(() {
        isPlaying = false;
        gameTimer?.cancel();
        _showGameOverDialog();
      });
    }
  }

  bool _checkCollision() {
    List<int> head = snake.first;
    if (head[0] < 0 || head[0] >= gridSize || head[1] < 0 || head[1] >= gridSize) return true;
    for (int i = 1; i < snake.length; i++) {
      if (snake[i][0] == head[0] && snake[i][1] == head[1]) return true;
    }
    return false;
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Final Score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Snake'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            gameTimer?.cancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Score: $score'),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1625),
              borderRadius: BorderRadius.circular(16),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                int row = index ~/ gridSize;
                int col = index % gridSize;
                bool isSnake = snake.any((segment) => segment[0] == row && segment[1] == col);
                bool isFood = food[0] == row && food[1] == col;
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSnake ? const Color(0xFF10B981) : (isFood ? const Color(0xFFEF4444) : const Color(0xFF0F0D1A)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(Icons.arrow_upward, 'UP'),
              const SizedBox(width: 16),
              _controlButton(Icons.arrow_downward, 'DOWN'),
              const SizedBox(width: 16),
              _controlButton(Icons.arrow_back, 'LEFT'),
              const SizedBox(width: 16),
              _controlButton(Icons.arrow_forward, 'RIGHT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, String dir) {
    return ElevatedButton(
      onPressed: isPlaying ? () {
        if ((dir == 'UP' && direction != 'DOWN') ||
            (dir == 'DOWN' && direction != 'UP') ||
            (dir == 'LEFT' && direction != 'RIGHT') ||
            (dir == 'RIGHT' && direction != 'LEFT')) {
          setState(() { direction = dir; });
        }
      } : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1625),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      child: Icon(icon, color: const Color(0xFF10B981)),
    );
  }
}

// ==================== GAME 5: SUDOKU ====================
class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});

  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  late List<List<int?>> board;
  late List<List<int?>> solution;
  List<List<bool>> isFixed = [];
  int selectedRow = -1;
  int selectedCol = -1;

  final List<List<int?>> easyPuzzle = [
    [5, 3, null, null, 7, null, null, null, null],
    [6, null, null, 1, 9, 5, null, null, null],
    [null, 9, 8, null, null, null, null, 6, null],
    [8, null, null, null, 6, null, null, null, 3],
    [4, null, null, 8, null, 3, null, null, 1],
    [7, null, null, null, 2, null, null, null, 6],
    [null, 6, null, null, null, null, 2, 8, null],
    [null, null, null, 4, 1, 9, null, null, 5],
    [null, null, null, null, 8, null, null, 7, 9],
  ];

  final List<List<int?>> easySolution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    board = List.generate(9, (i) => List.from(easyPuzzle[i]));
    solution = List.generate(9, (i) => List.from(easySolution[i]));
    isFixed = List.generate(9, (i) => List.generate(9, (j) => easyPuzzle[i][j] != null));
    selectedRow = -1;
    selectedCol = -1;
    setState(() {});
  }

  void _checkWin() {
    bool isComplete = true;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] != solution[i][j]) {
          isComplete = false;
          break;
        }
      }
    }
    if (isComplete) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You solved the Sudoku!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      );
    }
  }

  void _selectNumber(int number) {
    if (selectedRow != -1 && selectedCol != -1 && !isFixed[selectedRow][selectedCol]) {
      setState(() {
        board[selectedRow][selectedCol] = number;
        _checkWin();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Sudoku'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1625),
              borderRadius: BorderRadius.circular(16),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
              itemCount: 81,
              itemBuilder: (context, index) {
                int row = index ~/ 9;
                int col = index % 9;
                bool isSelected = selectedRow == row && selectedCol == col;
                return GestureDetector(
                  onTap: () => setState(() { selectedRow = row; selectedCol = col; }),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: (col + 1) % 3 == 0 ? BorderSide(color: Colors.grey.shade700) : BorderSide.none,
                        bottom: (row + 1) % 3 == 0 ? BorderSide(color: Colors.grey.shade700) : BorderSide.none,
                        left: BorderSide(color: Colors.grey.shade800),
                        top: BorderSide(color: Colors.grey.shade800),
                      ),
                      color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.3) : (isFixed[row][col] ? const Color(0xFF1A1625) : const Color(0xFF0F0D1A)),
                    ),
                    child: Center(
                      child: Text(
                        board[row][col] != null ? board[row][col].toString() : '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isFixed[row][col] ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1625),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(9, (i) {
                int number = i + 1;
                return ElevatedButton(
                  onPressed: () => _selectNumber(number),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F0D1A),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(50, 50),
                  ),
                  child: Text(number.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() { selectedRow = -1; selectedCol = -1; }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Clear Selection'),
          ),
        ],
      ),
    );
  }
}

// ==================== GAME 6: PACMAN ====================
class PacmanGame extends StatefulWidget {
  const PacmanGame({super.key});

  @override
  State<PacmanGame> createState() => _PacmanGameState();
}

class _PacmanGameState extends State<PacmanGame> {
  static const int gridWidth = 19;
  static const int gridHeight = 21;
  List<List<String>> maze = [];
  List<int> pacmanPos = [15, 9];
  List<List<int>> ghosts = [[9, 9], [9, 10], [10, 9], [10, 10]];
  String pacmanDirection = 'RIGHT';
  String nextDirection = 'RIGHT';
  int score = 0;
  int dotsRemaining = 0;
  bool isPlaying = true;
  bool isPacmanOpen = true;
  Timer? gameTimer;
  Timer? ghostTimer;
  Timer? mouthTimer;

  final List<List<String>> mazeLayout = [
    ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
    ['#','.','.','.','.','.','.','.','.','#','.','.','.','.','.','.','.','.','#'],
    ['#','.','#','#','#','.','#','#','.','#','.','#','#','.','#','#','#','.','#'],
    ['#','.','#','#','#','.','#','#','.','#','.','#','#','.','#','#','#','.','#'],
    ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
    ['#','.','#','#','#','.','#','.','#','#','#','.','#','.','#','#','#','.','#'],
    ['#','.','.','.','.','.','#','.','.','.','.','.','#','.','.','.','.','.','#'],
    ['#','#','#','#','#','.','#','#','#','.','#','#','#','.','#','#','#','#','#'],
    [' ',' ',' ',' ','#','.','#','#','#','.','#','#','#','.','#',' ',' ',' ',' '],
    [' ',' ',' ',' ','#','.','#','.','.','.','.','.','#','.','#',' ',' ',' ',' '],
    [' ',' ',' ',' ','#','.','#','.','#','#','#','.','#','.','#',' ',' ',' ',' '],
    [' ',' ',' ',' ','#','.','#','.','.','.','.','.','#','.','#',' ',' ',' ',' '],
    [' ',' ',' ',' ','#','.','#','#','#','#','#','#','#','.','#',' ',' ',' ',' '],
    ['#','#','#','#','#','.','.','.','.','.','.','.','.','.','#','#','#','#','#'],
    ['#','.','.','.','.','.','#','#','#','.','#','#','#','.','.','.','.','.','#'],
    ['#','.','#','#','#','.','#','#','#','.','#','#','#','.','#','#','#','.','#'],
    ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
    ['#','.','#','#','#','.','#','#','.','#','.','#','#','.','#','#','#','.','#'],
    ['#','.','.','.','.','.','.','.','.','#','.','.','.','.','.','.','.','.','#'],
    ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    maze = [];
    dotsRemaining = 0;
    for (int i = 0; i < mazeLayout.length; i++) {
      List<String> row = [];
      for (int j = 0; j < mazeLayout[i].length; j++) {
        row.add(mazeLayout[i][j]);
        if (mazeLayout[i][j] == '.') dotsRemaining++;
      }
      maze.add(row);
    }
    pacmanPos = [15, 9];
    ghosts = [[9, 9], [9, 10], [10, 9], [10, 10]];
    pacmanDirection = 'RIGHT';
    nextDirection = 'RIGHT';
    score = 0;
    isPlaying = true;
    _startGame();
  }

  void _startGame() {
    gameTimer?.cancel();
    ghostTimer?.cancel();
    mouthTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (isPlaying) { _movePacman(); setState(() {}); }
    });
    ghostTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (isPlaying) { _moveGhosts(); setState(() {}); }
    });
    mouthTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (isPlaying) { setState(() { isPacmanOpen = !isPacmanOpen; }); }
    });
  }

  void _movePacman() {
    int newRow = pacmanPos[0], newCol = pacmanPos[1];
    switch (nextDirection) {
      case 'UP': newRow--; break;
      case 'DOWN': newRow++; break;
      case 'LEFT': newCol--; break;
      case 'RIGHT': newCol++; break;
    }
    if (_isValidMove(newRow, newCol)) {
      pacmanDirection = nextDirection;
      pacmanPos = [newRow, newCol];
    } else {
      switch (pacmanDirection) {
        case 'UP': newRow = pacmanPos[0] - 1; newCol = pacmanPos[1]; break;
        case 'DOWN': newRow = pacmanPos[0] + 1; newCol = pacmanPos[1]; break;
        case 'LEFT': newRow = pacmanPos[0]; newCol = pacmanPos[1] - 1; break;
        case 'RIGHT': newRow = pacmanPos[0]; newCol = pacmanPos[1] + 1; break;
      }
      if (_isValidMove(newRow, newCol)) pacmanPos = [newRow, newCol];
    }
    if (maze[pacmanPos[0]][pacmanPos[1]] == '.') {
      maze[pacmanPos[0]][pacmanPos[1]] = ' ';
      score += 10;
      dotsRemaining--;
      if (dotsRemaining == 0) _gameWin();
    }
    for (var ghost in ghosts) {
      if (pacmanPos[0] == ghost[0] && pacmanPos[1] == ghost[1]) { _gameOver(); break; }
    }
  }

  bool _isValidMove(int row, int col) {
    if (row < 0 || row >= gridHeight || col < 0 || col >= gridWidth) return false;
    return maze[row][col] != '#';
  }

  void _moveGhosts() {
    for (int i = 0; i < ghosts.length; i++) {
      List<int> ghost = ghosts[i];
      List<int> newPos = _getGhostMove(ghost);
      if (newPos[0] == pacmanPos[0] && newPos[1] == pacmanPos[1]) { _gameOver(); return; }
      ghosts[i] = newPos;
    }
  }

  List<int> _getGhostMove(List<int> ghost) {
    List<List<int>> directions = [[-1,0],[1,0],[0,-1],[0,1]]..shuffle();
    for (var dir in directions) {
      int newRow = ghost[0] + dir[0], newCol = ghost[1] + dir[1];
      if (_isValidMove(newRow, newCol)) return [newRow, newCol];
    }
    return ghost;
  }

  void _gameOver() {
    isPlaying = false;
    gameTimer?.cancel(); ghostTimer?.cancel(); mouthTimer?.cancel();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Game Over!'), content: Text('Final Score: $score'),
      actions: [
        TextButton(onPressed: () { Navigator.pop(context); _initGame(); }, child: const Text('Play Again')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Menu')),
      ],
    ));
  }

  void _gameWin() {
    isPlaying = false;
    gameTimer?.cancel(); ghostTimer?.cancel(); mouthTimer?.cancel();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('You Win!'), content: Text('Final Score: $score'),
      actions: [
        TextButton(onPressed: () { Navigator.pop(context); _initGame(); }, child: const Text('Play Again')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Menu')),
      ],
    ));
  }

  void _changeDirection(String direction) { if (isPlaying) setState(() { nextDirection = direction; }); }

  @override
  void dispose() { gameTimer?.cancel(); ghostTimer?.cancel(); mouthTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Pacman'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () { gameTimer?.cancel(); ghostTimer?.cancel(); mouthTimer?.cancel(); Navigator.pop(context); },
        ),
        actions: [Padding(padding: const EdgeInsets.all(16), child: Text('Score: $score'))],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 380, height: 420,
            decoration: BoxDecoration(color: const Color(0xFF1A1625), borderRadius: BorderRadius.circular(16)),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridWidth),
              itemCount: gridWidth * gridHeight,
              itemBuilder: (context, index) {
                int row = index ~/ gridWidth, col = index % gridWidth;
                bool isPacman = (pacmanPos[0] == row && pacmanPos[1] == col);
                bool isGhost = ghosts.any((g) => g[0] == row && g[1] == col);
                String cell = maze[row][col];
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(color: cell == '#' ? const Color(0xFF3B82F6) : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                  child: Center(
                    child: isPacman ? Icon(isPacmanOpen ? Icons.circle : Icons.lens, size: 16, color: const Color(0xFFFBBF24))
                        : (isGhost ? Icon(Icons.warning, size: 14, color: const Color(0xFFEF4444))
                        : (cell == '.' ? Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle)) : const SizedBox())),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _controlButtonPacman(Icons.arrow_upward, 'UP'), const SizedBox(width: 16),
            _controlButtonPacman(Icons.arrow_downward, 'DOWN'), const SizedBox(width: 16),
            _controlButtonPacman(Icons.arrow_back, 'LEFT'), const SizedBox(width: 16),
            _controlButtonPacman(Icons.arrow_forward, 'RIGHT'),
          ]),
        ],
      ),
    );
  }

  Widget _controlButtonPacman(IconData icon, String dir) {
    return ElevatedButton(
      onPressed: isPlaying ? () => _changeDirection(dir) : null,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1625), shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
      child: Icon(icon, color: const Color(0xFFFBBF24)),
    );
  }
}

// ==================== GAME 7: SHOOTING GALLERY ====================
class ShootingGame extends StatefulWidget {
  const ShootingGame({super.key});

  @override
  State<ShootingGame> createState() => _ShootingGameState();
}

class _ShootingGameState extends State<ShootingGame> {
  List<Map<String, dynamic>> targets = [];
  int score = 0;
  int timeLeft = 30;
  bool isPlaying = false;
  Timer? gameTimer;
  Timer? spawnTimer;

  @override
  void initState() { super.initState(); _startGame(); }

  void _startGame() {
    setState(() { score = 0; timeLeft = 30; isPlaying = true; targets = []; });
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0 && isPlaying) { setState(() { timeLeft--; }); } else { _endGame(); }
    });
    spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (isPlaying && targets.length < 8) { _spawnTarget(); }
    });
  }

  void _spawnTarget() {
    Random random = Random();
    double x = random.nextDouble() * (MediaQuery.of(context).size.width - 100);
    double y = random.nextDouble() * 400 + 100;
    setState(() { targets.add({ 'x': x, 'y': y, 'size': 60.0, 'id': DateTime.now().millisecondsSinceEpoch, }); });
    Future.delayed(const Duration(seconds: 2), () { setState(() { targets.removeWhere((t) => t['id'] == targets.last['id']); }); });
  }

  void _shootTarget(Map<String, dynamic> target) { setState(() { targets.remove(target); score += 10; }); }

  void _endGame() {
    isPlaying = false;
    gameTimer?.cancel(); spawnTimer?.cancel();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Time\'s Up!'), content: Text('Final Score: $score'),
      actions: [
        TextButton(onPressed: () { Navigator.pop(context); _startGame(); }, child: const Text('Play Again')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Menu')),
      ],
    ));
  }

  @override
  void dispose() { gameTimer?.cancel(); spawnTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Shooting Gallery'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () { gameTimer?.cancel(); spawnTimer?.cancel(); Navigator.pop(context); },
        ),
        actions: [Padding(padding: const EdgeInsets.all(16), child: Text('Score: $score  Time: ${timeLeft}s'))],
      ),
      body: GestureDetector(
        onTapDown: (details) {
          for (var target in targets) {
            if (details.localPosition.dx >= target['x'] && details.localPosition.dx <= target['x'] + target['size'] &&
                details.localPosition.dy >= target['y'] && details.localPosition.dy <= target['y'] + target['size']) {
              _shootTarget(target); break;
            }
          }
        },
        child: Stack(children: [
          Container(width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [const Color(0xFF1A1625), const Color(0xFF0F0D1A)]),),),
          for (var target in targets)
            Positioned(
              left: target['x'], top: target['y'],
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 1.0, end: 0.0), duration: const Duration(seconds: 2),
                builder: (context, value, child) => Opacity(opacity: value, child: Transform.scale(scale: value, child: child)),
                child: GestureDetector(
                  onTap: () => _shootTarget(target),
                  child: Container(width: target['size'], height: target['size'],
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10)],),
                    child: const Icon(Icons.brightness_1, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          if (!isPlaying && timeLeft == 0) const Center(child: Text('Game Over', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red))),
        ]),
      ),
    );
  }
}

// ==================== GAME 8: BLOCK BLAST (DRAG & DROP + CLEAR VISUAL) ====================
class BlockBlastGame extends StatefulWidget {
  const BlockBlastGame({super.key});

  @override
  State<BlockBlastGame> createState() => _BlockBlastGameState();
}

class _BlockBlastGameState extends State<BlockBlastGame> {
  static const int gridSize = 8;
  late List<List<int?>> grid;
  List<Map<String, dynamic>> blocks = [];
  int score = 0;
  Map<String, dynamic>? draggedBlock;
  Offset dragPosition = Offset.zero;
  bool isDragging = false;

  final List blockShapes = [
    [[1,1],[1,1]],  // 2x2 square
    [[1,1,1]],      // 3 horizontal
    [[1],[1],[1]],  // 3 vertical
    [[1,0],[1,0],[1,1]], // L shape
    [[0,1,0],[1,1,1]],   // T shape
    [[1,1,0],[0,1,1]],   // Z shape
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => null));
    score = 0;
    _generateBlocks();
    setState(() {});
  }

  void _generateBlocks() {
    blocks = [];
    Random random = Random();
    for (int i = 0; i < 3; i++) {
      int shapeIndex = random.nextInt(blockShapes.length);
      blocks.add({
        'id': i,
        'shape': blockShapes[shapeIndex],
        'color': Colors.primaries[random.nextInt(Colors.primaries.length)],
      });
    }
  }

  bool _canPlaceBlock(List<dynamic> shape, int gridRow, int gridCol) {
    for (int i = 0; i < shape.length; i++) {
      List<dynamic> row = shape[i];
      for (int j = 0; j < row.length; j++) {
        if (row[j] == 1) {
          int rowCell = gridRow + i;
          int colCell = gridCol + j;
          if (rowCell >= gridSize || colCell >= gridSize || grid[rowCell][colCell] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _placeBlock(Map<String, dynamic> block, int gridRow, int gridCol) {
    List<dynamic> shape = block['shape'];
    
    if (!_canPlaceBlock(shape, gridRow, gridCol)) return;
    
    setState(() {
      for (int i = 0; i < shape.length; i++) {
        List<dynamic> row = shape[i];
        for (int j = 0; j < row.length; j++) {
          if (row[j] == 1) {
            grid[gridRow + i][gridCol + j] = (block['color'] as Color).value;
          }
        }
      }
      blocks.remove(block);
      score += 50;
      _checkAndClearLines();
      
      if (blocks.isEmpty) {
        _generateBlocks();
      }
      
      _checkGameOver();
      isDragging = false;
      draggedBlock = null;
    });
  }

  void _checkAndClearLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];
    
    for (int i = 0; i < gridSize; i++) {
      bool fullRow = true;
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == null) {
          fullRow = false;
          break;
        }
      }
      if (fullRow) rowsToClear.add(i);
    }
    
    for (int j = 0; j < gridSize; j++) {
      bool fullCol = true;
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] == null) {
          fullCol = false;
          break;
        }
      }
      if (fullCol) colsToClear.add(j);
    }
    
    for (int row in rowsToClear) {
      for (int j = 0; j < gridSize; j++) {
        grid[row][j] = null;
      }
      score += 100;
    }
    
    for (int col in colsToClear) {
      for (int i = 0; i < gridSize; i++) {
        grid[i][col] = null;
      }
      score += 100;
    }
  }

  void _checkGameOver() {
    for (var block in blocks) {
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          if (_canPlaceBlock(block['shape'], i, j)) {
            return;
          }
        }
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Final Score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockShape(List<dynamic> shape, Color color) {
    int rows = shape.length;
    int cols = shape[0].length;
    
    return Container(
      width: 70,
      height: 70,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
        ),
        itemCount: rows * cols,
        itemBuilder: (context, index) {
          int row = index ~/ cols;
          int col = index % cols;
          if (shape[row][col] == 1) {
            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D1A),
      appBar: AppBar(
        title: const Text('Block Blast'),
        backgroundColor: const Color(0xFF1A1625),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Score: $score'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Game Grid
          Container(
            width: 350,
            height: 350,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1625),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                int row = index ~/ gridSize;
                int col = index % gridSize;
                Color? cellColor = grid[row][col] != null ? Color(grid[row][col]!) : null;
                
                return DragTarget<Map<String, dynamic>>(
                  onAccept: (block) {
                    if (draggedBlock != null) {
                      _placeBlock(block, row, col);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return GestureDetector(
                      onTap: () {
                        if (draggedBlock != null) {
                          _placeBlock(draggedBlock!, row, col);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cellColor ?? const Color(0xFF0F0D1A),
                          border: Border.all(
                            color: cellColor != null 
                                ? const Color(0xFF7C3AED).withOpacity(0.5)
                                : Colors.grey.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Instructions
          const Text(
            'Tap block then tap on grid to place',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Available Blocks with DRAG
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: blocks.map((block) {
              return Draggable<Map<String, dynamic>>(
                data: block,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.7,
                    child: _buildBlockShape(block['shape'], block['color']),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildBlockShape(block['shape'], block['color']),
                ),
                onDragStarted: () {
                  setState(() {
                    draggedBlock = block;
                    isDragging = true;
                  });
                },
                onDragEnd: (details) {
                  setState(() {
                    isDragging = false;
                    draggedBlock = null;
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      draggedBlock = block;
                    });
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1625),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: draggedBlock == block 
                            ? const Color(0xFF3B82F6) 
                            : const Color(0xFF7C3AED).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: draggedBlock == block
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _buildBlockShape(block['shape'], block['color']),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    draggedBlock = null;
                    isDragging = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _initGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1625),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                ),
                child: const Text('Reset Game'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}