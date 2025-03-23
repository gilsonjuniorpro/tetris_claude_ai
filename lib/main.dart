// Core Flutter framework
import 'package:flutter/material.dart';
// For handling keyboard input
import 'package:flutter/services.dart';
// For Timer functionality
import 'dart:async';
// For Random number generation
import 'dart:math';

// Entry point of the application
void main() {
  runApp(const MyApp());
}

// Root widget of the application that sets up the theme and initial screen
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Tetris',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TetrisGame(), // Main game screen
    );
  }
}

// Main game widget that maintains the game state
class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

// Game state and logic implementation
class _TetrisGameState extends State<TetrisGame> {
  // Game board dimensions and cell size constants
  static const int BOARD_WIDTH = 10; // Width of the game board
  static const int BOARD_HEIGHT = 20; // Height of the game board
  static const double CELL_SIZE = 30.0; // Size of each cell in pixels

  // Game board: 2D list where null represents empty cell and Color represents filled cell
  List<List<Color?>> board = List.generate(
    BOARD_HEIGHT,
    (i) => List.generate(BOARD_WIDTH, (j) => null),
  );

  Timer? gameTimer; // Controls the automatic downward movement of pieces
  int score = 0; // Player's current score
  bool isGameOver = false; // Tracks game state
  Piece? currentPiece; // The currently falling piece
  Position currentPosition = Position(
    0,
    0,
  ); // Current piece's position on board

  @override
  void initState() {
    super.initState();
    startGame(); // Initialize game when widget is first created
  }

  // Initialize or reset the game state
  void startGame() {
    isGameOver = false;
    score = 0;
    // Clear the game board
    board = List.generate(
      BOARD_HEIGHT,
      (i) => List.generate(BOARD_WIDTH, (j) => null),
    );
    spawnNewPiece();
    // Start game timer - moves piece down every 500ms
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      moveDown();
    });
  }

  // Create and position a new random piece at the top of the board
  void spawnNewPiece() {
    final random = Random();
    final tetrominos = Tetromino.values;
    currentPiece = Piece(tetrominos[random.nextInt(tetrominos.length)]);
    // Position piece at top center of board
    currentPosition = Position(BOARD_WIDTH ~/ 2 - 2, 0);

    // Check if new piece can be placed - if not, game is over
    if (!isValidMove(currentPosition)) {
      gameOver();
    }
  }

  // Handle game over state
  void gameOver() {
    gameTimer?.cancel();
    setState(() {
      isGameOver = true;
    });
  }

  // Check if a move is valid (within bounds and not overlapping other pieces)
  bool isValidMove(Position position) {
    if (currentPiece == null) return false;

    // Check each cell of the piece
    for (int i = 0; i < currentPiece!.shape.length; i++) {
      for (int j = 0; j < currentPiece!.shape[i].length; j++) {
        if (currentPiece!.shape[i][j] == 1) {
          int newX = position.x + j;
          int newY = position.y + i;

          // Check board boundaries
          if (newX < 0 || newX >= BOARD_WIDTH || newY >= BOARD_HEIGHT) {
            return false;
          }

          // Check collision with existing pieces
          if (newY >= 0 && board[newY][newX] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Move the current piece down one position
  void moveDown() {
    if (!isGameOver) {
      setState(() {
        Position newPosition = Position(
          currentPosition.x,
          currentPosition.y + 1,
        );
        if (isValidMove(newPosition)) {
          currentPosition = newPosition;
        } else {
          // If can't move down, place piece and spawn new one
          placePiece();
          clearLines();
          spawnNewPiece();
        }
      });
    }
  }

  // Move the current piece one position to the left
  void moveLeft() {
    if (!isGameOver) {
      setState(() {
        Position newPosition = Position(
          currentPosition.x - 1,
          currentPosition.y,
        );
        if (isValidMove(newPosition)) {
          currentPosition = newPosition;
        }
      });
    }
  }

  // Move the current piece one position to the right
  void moveRight() {
    if (!isGameOver) {
      setState(() {
        Position newPosition = Position(
          currentPosition.x + 1,
          currentPosition.y,
        );
        if (isValidMove(newPosition)) {
          currentPosition = newPosition;
        }
      });
    }
  }

  // Rotate the current piece clockwise
  void rotate() {
    if (!isGameOver && currentPiece != null) {
      setState(() {
        // Save original shape in case rotation is invalid
        final originalShape = List<List<int>>.from(
          currentPiece!.shape.map((row) => List<int>.from(row)),
        );
        currentPiece!.rotate();
        // If rotation is invalid, restore original shape
        if (!isValidMove(currentPosition)) {
          currentPiece!.shape = originalShape;
        }
      });
    }
  }

  // Fix the current piece in place on the board
  void placePiece() {
    if (currentPiece == null) return;

    // Add each cell of the piece to the board
    for (int i = 0; i < currentPiece!.shape.length; i++) {
      for (int j = 0; j < currentPiece!.shape[i].length; j++) {
        if (currentPiece!.shape[i][j] == 1) {
          int boardY = currentPosition.y + i;
          int boardX = currentPosition.x + j;
          if (boardY >= 0 &&
              boardY < BOARD_HEIGHT &&
              boardX >= 0 &&
              boardX < BOARD_WIDTH) {
            board[boardY][boardX] = currentPiece!.type.color;
          }
        }
      }
    }
  }

  // Check and clear completed lines, update score
  void clearLines() {
    for (int i = BOARD_HEIGHT - 1; i >= 0; i--) {
      bool isLineFull = true;
      // Check if line is complete
      for (int j = 0; j < BOARD_WIDTH; j++) {
        if (board[i][j] == null) {
          isLineFull = false;
          break;
        }
      }

      if (isLineFull) {
        score += 100; // Add points for completed line
        // Move all lines above down
        for (int k = i; k > 0; k--) {
          board[k] = List.from(board[k - 1]);
        }
        // Clear top line
        board[0] = List.generate(BOARD_WIDTH, (j) => null);
        i++; // Recheck current line as it now contains the line from above
      }
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Main game UI with keyboard input handling
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      // Handle keyboard input for game controls
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            moveLeft();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            moveRight();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            moveDown();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            rotate();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Flutter Tetris'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score display
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Game board container with border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Stack(
                  children: [
                    // Game board and current piece
                    CustomPaint(
                      size: Size(
                        BOARD_WIDTH * CELL_SIZE,
                        BOARD_HEIGHT * CELL_SIZE,
                      ),
                      painter: BoardPainter(
                        board: board,
                        currentPiece: currentPiece,
                        currentPosition: currentPosition,
                      ),
                    ),
                    // Game over overlay
                    if (isGameOver)
                      Container(
                        width: BOARD_WIDTH * CELL_SIZE,
                        height: BOARD_HEIGHT * CELL_SIZE,
                        color: Colors.black54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Game Over',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: startGame,
                              child: const Text('Play Again'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: moveLeft,
                    child: const Icon(Icons.arrow_left),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: rotate,
                    child: const Icon(Icons.rotate_right),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: moveRight,
                    child: const Icon(Icons.arrow_right),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: moveDown,
                    child: const Icon(Icons.arrow_drop_down),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for rendering the game board and pieces
class BoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final Piece? currentPiece;
  final Position currentPosition;

  BoardPainter({
    required this.board,
    required this.currentPiece,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / _TetrisGameState.BOARD_WIDTH;
    final cellHeight = size.height / _TetrisGameState.BOARD_HEIGHT;

    // Draw the placed pieces on the board
    for (int y = 0; y < _TetrisGameState.BOARD_HEIGHT; y++) {
      for (int x = 0; x < _TetrisGameState.BOARD_WIDTH; x++) {
        final color = board[y][x];
        if (color != null) {
          drawCell(canvas, x, y, cellWidth, cellHeight, color);
        }
      }
    }

    // Draw the current falling piece
    if (currentPiece != null) {
      for (int y = 0; y < currentPiece!.shape.length; y++) {
        for (int x = 0; x < currentPiece!.shape[y].length; x++) {
          if (currentPiece!.shape[y][x] == 1) {
            final pieceX = currentPosition.x + x;
            final pieceY = currentPosition.y + y;
            if (pieceY >= 0) {
              drawCell(
                canvas,
                pieceX,
                pieceY,
                cellWidth,
                cellHeight,
                currentPiece!.type.color,
              );
            }
          }
        }
      }
    }

    // Draw grid lines
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..strokeWidth = 1.0;

    // Draw vertical grid lines
    for (int i = 0; i <= _TetrisGameState.BOARD_WIDTH; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        paint,
      );
    }

    // Draw horizontal grid lines
    for (int i = 0; i <= _TetrisGameState.BOARD_HEIGHT; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        paint,
      );
    }
  }

  // Helper method to draw a single cell with color and border
  void drawCell(
    Canvas canvas,
    int x,
    int y,
    double cellWidth,
    double cellHeight,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      x * cellWidth,
      y * cellHeight,
      cellWidth,
      cellHeight,
    );

    // Fill cell with color
    final paint = Paint()..color = color;
    canvas.drawRect(rect, paint);

    // Draw cell border
    final borderPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper class to represent a position on the game board
class Position {
  final int x;
  final int y;

  Position(this.x, this.y);
}

// Class representing a Tetris piece with its type and shape
class Piece {
  final Tetromino type;
  List<List<int>> shape;

  Piece(this.type) : shape = type.defaultShape;

  // Rotate the piece 90 degrees clockwise
  void rotate() {
    final List<List<int>> rotatedShape = List.generate(
      shape[0].length,
      (i) => List.generate(shape.length, (j) => 0),
    );

    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape[i].length; j++) {
        rotatedShape[j][shape.length - 1 - i] = shape[i][j];
      }
    }
    shape = rotatedShape;
  }
}

// Enum defining all possible Tetris piece types with their colors and shapes
enum Tetromino {
  I, // Long piece (####)
  O, // Square piece
  T, // T-shaped piece
  S, // S-shaped piece
  Z, // Z-shaped piece
  J, // J-shaped piece
  L; // L-shaped piece

  // Get the color for each piece type
  Color get color {
    switch (this) {
      case Tetromino.I:
        return Colors.cyan;
      case Tetromino.O:
        return Colors.yellow;
      case Tetromino.T:
        return Colors.purple;
      case Tetromino.S:
        return Colors.green;
      case Tetromino.Z:
        return Colors.red;
      case Tetromino.J:
        return Colors.blue;
      case Tetromino.L:
        return Colors.orange;
    }
  }

  // Get the shape matrix for each piece type
  List<List<int>> get defaultShape {
    switch (this) {
      case Tetromino.I:
        return [
          [1, 1, 1, 1], // ####
        ];
      case Tetromino.O:
        return [
          [1, 1], // ##
          [1, 1], // ##
        ];
      case Tetromino.T:
        return [
          [0, 1, 0], //  #
          [1, 1, 1], // ###
        ];
      case Tetromino.S:
        return [
          [0, 1, 1], //  ##
          [1, 1, 0], // ##
        ];
      case Tetromino.Z:
        return [
          [1, 1, 0], // ##
          [0, 1, 1], //  ##
        ];
      case Tetromino.J:
        return [
          [1, 0, 0], // #
          [1, 1, 1], // ###
        ];
      case Tetromino.L:
        return [
          [0, 0, 1], //   #
          [1, 1, 1], // ###
        ];
    }
  }
}
