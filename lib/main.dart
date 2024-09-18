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
  int currentRotation = 0; // Для хранения текущего поворота фигуры

  // Описание фигур с их поворотами
  List<List<List<List<int>>>> shapes = [
    // I-образная (палочка) — 2 положения (вертикальное и горизонтальное)
    [
      [[0, 1], [1, 1], [2, 1], [3, 1]], // вертикальное положение
      [[0, 0], [0, 1], [0, 2], [0, 3]]  // горизонтальное положение
    ],
    // O-образная (квадрат) — не вращается
    [
      [[0, 0], [0, 1], [1, 0], [1, 1]] // одна конфигурация
    ],
    // T-образная — 4 положения
    [
      [[0, 1], [1, 0], [1, 1], [1, 2]], // "T"
      [[0, 1], [1, 1], [2, 1], [1, 2]], // повернуто вправо
      [[1, 0], [1, 1], [1, 2], [2, 1]], // перевернутое "T"
      [[0, 1], [1, 1], [2, 1], [1, 0]]  // повернуто влево
    ],
    // L-образная — 4 положения
    [
      [[0, 1], [1, 1], [2, 1], [2, 2]], // начальное положение
      [[1, 0], [1, 1], [1, 2], [2, 0]], // повернуто вправо
      [[0, 0], [0, 1], [1, 1], [2, 1]], // перевернуто
      [[1, 0], [1, 1], [1, 2], [0, 2]]  // повернуто влево
    ]
  ];

  List<List<List<int>>>? currentShape;
  int currentColumn = 0;
  int currentRow = 0;

  List<List<int>> gameBoard = List.generate(rows, (i) => List.generate(columns, (j) => 0));

  void resetGame() {
    setState(() {
      gameBoard = List.generate(rows, (i) => List.generate(columns, (j) => 0));
      generateRandomShape();
      _fallingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
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
      });
    });
  }

  void generateRandomShape() {
    final random = Random();
    currentShape = shapes[random.nextInt(shapes.length)];
    currentRotation = random.nextInt(currentShape!.length); // Выбираем случайный поворот

    int minCol = currentShape![currentRotation].map((point) => point[1]).reduce((a, b) => a < b ? a : b);
    int maxCol = currentShape![currentRotation].map((point) => point[1]).reduce((a, b) => a > b ? a : b);

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

  // Функция для вращения фигуры
  void rotateShape() {
    setState(() {
      int nextRotation = (currentRotation + 1) % currentShape!.length;
      bool canRotate = currentShape![nextRotation].every((point) {
        int newRow = currentRow + point[0];
        int newCol = currentColumn + point[1];
        return newRow >= 0 && newRow < rows && newCol >= 0 && newCol < columns && gameBoard[newRow][newCol] == 0;
      });

      if (canRotate) {
        currentRotation = nextRotation; // Вращаем фигуру
      }
    });
  }

  void moveShapeLeft() {
    setState(() {
      // Проверяем, можно ли двигать фигуру влево
      bool canMoveLeft = currentShape![currentRotation].every((point) {
        int newCol = currentColumn + point[1] - 1;
        return newCol >= 0 && gameBoard[currentRow + point[0]][newCol] == 0;
      });

      if (canMoveLeft) {
        currentColumn--; // Двигаем фигуру влево
      }
    });
  }

  void moveShapeRight() {
    setState(() {
      // Проверяем, можно ли двигать фигуру вправо
      bool canMoveRight = currentShape![currentRotation].every((point) {
        int newCol = currentColumn + point[1] + 1;
        return newCol < columns && gameBoard[currentRow + point[0]][newCol] == 0;
      });

      if (canMoveRight) {
        currentColumn++; // Двигаем фигуру вправо
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
        currentColumn--; // Двигаем фигуру влево
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
        currentColumn++; // Двигаем фигуру вправо
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
    _fallingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
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
                onTap: rotateShape, // Поворот фигуры при нажатии на игровое поле
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    // Если свайп влево
                    if (details.primaryVelocity! > 0) {
                      moveRight();
                    }
                    // Если свайп вправо
                    else if (details.primaryVelocity! < 0) {
                      moveLeft();
                    }
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