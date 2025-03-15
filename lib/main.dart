import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

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
      home: const TetrisGame(),
    );
  }
}

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const int BOARD_WIDTH = 10;
  static const int BOARD_HEIGHT = 20;
  static const double CELL_SIZE = 30.0;

  List<List<Color?>> board = List.generate(
    BOARD_HEIGHT,
    (i) => List.generate(BOARD_WIDTH, (j) => null),
  );

  Timer? gameTimer;
  int score = 0;
  bool isGameOver = false;
  Piece? currentPiece;
  Position currentPosition = Position(0, 0);

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    isGameOver = false;
    score = 0;
    board = List.generate(
      BOARD_HEIGHT,
      (i) => List.generate(BOARD_WIDTH, (j) => null),
    );
    spawnNewPiece();
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      moveDown();
    });
  }

  void spawnNewPiece() {
    final random = Random();
    final tetrominos = Tetromino.values;
    currentPiece = Piece(tetrominos[random.nextInt(tetrominos.length)]);
    currentPosition = Position(BOARD_WIDTH ~/ 2 - 2, 0);

    if (!isValidMove(currentPosition)) {
      gameOver();
    }
  }

  void gameOver() {
    gameTimer?.cancel();
    setState(() {
      isGameOver = true;
    });
  }

  bool isValidMove(Position position) {
    if (currentPiece == null) return false;

    for (int i = 0; i < currentPiece!.shape.length; i++) {
      for (int j = 0; j < currentPiece!.shape[i].length; j++) {
        if (currentPiece!.shape[i][j] == 1) {
          int newX = position.x + j;
          int newY = position.y + i;

          if (newX < 0 || newX >= BOARD_WIDTH || newY >= BOARD_HEIGHT) {
            return false;
          }

          if (newY >= 0 && board[newY][newX] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

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
          placePiece();
          clearLines();
          spawnNewPiece();
        }
      });
    }
  }

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

  void rotate() {
    if (!isGameOver && currentPiece != null) {
      setState(() {
        final originalShape = List<List<int>>.from(
          currentPiece!.shape.map((row) => List<int>.from(row)),
        );
        currentPiece!.rotate();
        if (!isValidMove(currentPosition)) {
          currentPiece!.shape = originalShape;
        }
      });
    }
  }

  void placePiece() {
    if (currentPiece == null) return;

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

  void clearLines() {
    for (int i = BOARD_HEIGHT - 1; i >= 0; i--) {
      bool isLineFull = true;
      for (int j = 0; j < BOARD_WIDTH; j++) {
        if (board[i][j] == null) {
          isLineFull = false;
          break;
        }
      }

      if (isLineFull) {
        score += 100;
        for (int k = i; k > 0; k--) {
          board[k] = List.from(board[k - 1]);
        }
        board[0] = List.generate(BOARD_WIDTH, (j) => null);
        i++; // Check the same line again
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
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
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
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Stack(
                  children: [
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

    // Draw the board
    for (int y = 0; y < _TetrisGameState.BOARD_HEIGHT; y++) {
      for (int x = 0; x < _TetrisGameState.BOARD_WIDTH; x++) {
        final color = board[y][x];
        if (color != null) {
          drawCell(canvas, x, y, cellWidth, cellHeight, color);
        }
      }
    }

    // Draw the current piece
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

    for (int i = 0; i <= _TetrisGameState.BOARD_WIDTH; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        paint,
      );
    }

    for (int i = 0; i <= _TetrisGameState.BOARD_HEIGHT; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        paint,
      );
    }
  }

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

    final paint = Paint()..color = color;
    canvas.drawRect(rect, paint);

    // Draw border
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

class Position {
  final int x;
  final int y;

  Position(this.x, this.y);
}

class Piece {
  final Tetromino type;
  List<List<int>> shape;

  Piece(this.type) : shape = type.defaultShape;

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

enum Tetromino {
  I,
  O,
  T,
  S,
  Z,
  J,
  L;

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

  List<List<int>> get defaultShape {
    switch (this) {
      case Tetromino.I:
        return [
          [1, 1, 1, 1],
        ];
      case Tetromino.O:
        return [
          [1, 1],
          [1, 1],
        ];
      case Tetromino.T:
        return [
          [0, 1, 0],
          [1, 1, 1],
        ];
      case Tetromino.S:
        return [
          [0, 1, 1],
          [1, 1, 0],
        ];
      case Tetromino.Z:
        return [
          [1, 1, 0],
          [0, 1, 1],
        ];
      case Tetromino.J:
        return [
          [1, 0, 0],
          [1, 1, 1],
        ];
      case Tetromino.L:
        return [
          [0, 0, 1],
          [1, 1, 1],
        ];
    }
  }
}
