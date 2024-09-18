import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int columns = 16;
  static const int rows = 26;
  Timer? _fallingTimer;
  int currentRotation = 0;

  // Фигуры с разными поворотами
  List<List<List<List<int>>>> shapes = [
    [
      [[0, 1], [1, 1], [2, 1], [3, 1]], // I-образная (вертикальная)
      [[0, 0], [0, 1], [0, 2], [0, 3]]  // I-образная (горизонтальная)
    ],
    [
      [[0, 0], [0, 1], [1, 0], [1, 1]] // O-образная
    ],
    [
      [[0, 1], [1, 0], [1, 1], [1, 2]], // T-образная (начальная)
      [[0, 1], [1, 1], [2, 1], [1, 2]], // T-образная (поворот вправо)
      [[1, 0], [1, 1], [1, 2], [2, 1]], // T-образная (перевернутая)
      [[0, 1], [1, 1], [2, 1], [1, 0]]  // T-образная (поворот влево)
    ],
    // L-образная
    [
      [[0, 1], [1, 1], [2, 1], [2, 2]], // L (начальное положение)
      [[1, 0], [1, 1], [1, 2], [2, 0]], // L (поворот вправо)
      [[0, 0], [0, 1], [1, 1], [2, 1]], // L (перевернутая)
      [[1, 0], [1, 1], [1, 2], [0, 2]]  // L (поворот влево)
    ]
  ];

  List<List<List<int>>>? currentShape;
  int currentColumn = 0;
  int currentRow = 0;
  bool isFastDropping = false;
  Duration dropSpeed = const Duration(milliseconds: 500);
  bool allowMove = true;

  List<List<int>> gameBoard = List.generate(rows, (i) => List.generate(columns, (j) => 0));

  void resetGame() {
    setState(() {
      gameBoard = List.generate(rows, (i) => List.generate(columns, (j) => 0));
      generateRandomShape();
      _fallingTimer?.cancel();
      _fallingTimer = Timer.periodic(dropSpeed, (timer) {
        moveShapeDown();
      });
    });
  }

  void generateRandomShape() {
    final random = Random();
    currentShape = shapes[random.nextInt(shapes.length)];
    currentRotation = random.nextInt(currentShape!.length);

    int minCol = currentShape![currentRotation].map((point) => point[1]).reduce(min);
    int maxCol = currentShape![currentRotation].map((point) => point[1]).reduce(max);
    int shapeWidth = maxCol - minCol + 1;
    currentColumn = (columns - shapeWidth) ~/ 2;
    currentRow = 0;

    bool canPlaceShape = currentShape![currentRotation].every((point) {
      return gameBoard[currentRow + point[0]][currentColumn + point[1]] == 0;
    });

    if (!canPlaceShape) {
      _fallingTimer?.cancel();
      showGameOverDialog();
    }
  }

  void moveShapeDown() {
    setState(() {
      bool canMoveDown = currentShape![currentRotation].every((point) {
        int newRow = currentRow + point[0] + 1;
        return newRow < rows && gameBoard[newRow][currentColumn + point[1]] == 0;
      });

      if (canMoveDown) {
        currentRow++;
      } else {
        currentShape![currentRotation].forEach((point) {
          gameBoard[currentRow + point[0]][currentColumn + point[1]] = 1;
        });
        generateRandomShape();
      }
    });
  }

  void fastDrop() {
    setState(() {
      isFastDropping = true;
      allowMove = false;
      _fallingTimer?.cancel();

      _fallingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        bool canMoveDown = currentShape![currentRotation].every((point) {
          int newRow = currentRow + point[0] + 1;
          return newRow < rows && gameBoard[newRow][currentColumn + point[1]] == 0;
        });

        if (canMoveDown) {
          setState(() {
            currentRow++;
          });
        } else {
          setState(() {
            currentShape![currentRotation].forEach((point) {
              gameBoard[currentRow + point[0]][currentColumn + point[1]] = 1;
            });
            resetDropSpeed();  // Возвращаем стандартную скорость после завершения быстрого падения
            generateRandomShape();
          });
          timer.cancel();
        }
      });
    });
  }

  void resetDropSpeed() {
    setState(() {
      isFastDropping = false;
      allowMove = true;
      dropSpeed = const Duration(milliseconds: 500);
      _fallingTimer?.cancel();
      _fallingTimer = Timer.periodic(dropSpeed, (timer) {
        moveShapeDown();
      });
    });
  }

  void rotateShape() {
    setState(() {
      int nextRotation = (currentRotation + 1) % currentShape!.length;
      bool canRotate = currentShape![nextRotation].every((point) {
        int newRow = currentRow + point[0];
        int newCol = currentColumn + point[1];
        return newRow >= 0 && newRow < rows && newCol >= 0 && newCol < columns && gameBoard[newRow][newCol] == 0;
      });

      if (canRotate) {
        currentRotation = nextRotation;
      }
    });
  }

  void moveLeft() {
    setState(() {
      bool canMoveLeft = currentShape![currentRotation].every((point) {
        int newCol = currentColumn + point[1] - 1;
        return newCol >= 0 && gameBoard[currentRow + point[0]][newCol] == 0;
      });

      if (canMoveLeft) {
        currentColumn--;
      }
    });
  }

  void moveRight() {
    setState(() {
      bool canMoveRight = currentShape![currentRotation].every((point) {
        int newCol = currentColumn + point[1] + 1;
        return newCol < columns && gameBoard[currentRow + point[0]][newCol] == 0;
      });

      if (canMoveRight) {
        currentColumn++;
      }
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: const Text('Фигуры достигли потолка!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: const Text('Начать заново'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    generateRandomShape();
    _fallingTimer = Timer.periodic(dropSpeed, (timer) {
      moveShapeDown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kBottomNavigationBarHeight;

    final cellWidth = screenWidth / columns;
    final cellHeight = availableHeight / rows;
    final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 100,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Text(
                'Информация',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: allowMove ? rotateShape : null,
                onHorizontalDragEnd: allowMove ? (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 0) {
                      moveRight();
                    } else if (details.primaryVelocity! < 0) {
                      moveLeft();
                    }
                  }
                } : null,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                    fastDrop();
                  }
                },
                child: Center(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 1,
                    ),
                    itemCount: columns * rows,
                    itemBuilder: (context, index) {
                      int row = index ~/ columns;
                      int col = index % columns;

                      bool isFixedBlock = gameBoard[row][col] == 1;
                      bool isShapeCell = currentShape![currentRotation].any((point) {
                        return row == currentRow + point[0] && col == currentColumn + point[1];
                      });

                      return Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isShapeCell || isFixedBlock ? Colors.blue : Colors.grey[300],
                          border: Border.all(color: Colors.black),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
