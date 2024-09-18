import 'dart:async';
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
  int squareRow = 0; // Текущая строка квадрата
  Timer? _fallingTimer; // Таймер для падения
  int visibleBlocks = 0; // Количество видимых кубиков фигуры

  List<List<List<int>>> shapes = [
    // I-образная (палочка)
    [
      [0, -1], [0, 0], [0, 1], [0, 2]
    ],
    // O-образная (квадрат)
    [
      [0, 0], [0, 1], [1, 0], [1, 1]
    ],
    // T-образная
    [
      [-1, 0], [0, 0], [1, 0], [0, 1]
    ],
    // L-образная
    [
      [0, -1], [0, 0], [0, 1], [1, 1]
    ]
  ];

  List<List<int>>? currentShape; // Текущая фигура
  int currentColumn = 0; // Текущая позиция фигуры по горизонтали
  int currentRow = 0; // Текущая позиция фигуры по вертикали

  List<List<int>> gameBoard = List.generate(rows, (i) => List.generate(columns, (j) => 0)); // 0 — пустая клетка

  void resetGame() {
    setState(() {
      // Очищаем игровое поле
      gameBoard = List.generate(rows, (i) => List.generate(columns, (j) => 0));
      // Генерируем новую фигуру
      generateRandomShape();
      // Перезапускаем таймер
      _fallingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        setState(() {
          // Проверяем движение фигуры вниз
          bool canMoveDown = currentShape!.every((point) {
            int newRow = currentRow + point[0] + 1;
            return newRow < rows && gameBoard[newRow][currentColumn + point[1]] == 0;
          });

          if (canMoveDown) {
            currentRow++; // Двигаем фигуру вниз
          } else {
            // Фиксируем фигуру
            currentShape!.forEach((point) {
              gameBoard[currentRow + point[0]][currentColumn + point[1]] = 1;
            });
            generateRandomShape(); // Генерируем новую фигуру
          }
        });
      });
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
                resetGame(); // Перезапуск игры
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

    // Генерируем случайную фигуру при запуске
    generateRandomShape();

    // Запускаем таймер для движения фигуры вниз
    _fallingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        // Проверяем, может ли фигура двигаться вниз
        bool canMoveDown = currentShape!.every((point) {
          int newRow = currentRow + point[0] + 1;
          return newRow < rows && gameBoard[newRow][currentColumn + point[1]] == 0; // Проверяем, есть ли блоки ниже
        });

        if (canMoveDown) {
          currentRow++; // Двигаем фигуру вниз
        } else {
          // Фиксируем фигуру на игровом поле
          currentShape!.forEach((point) {
            gameBoard[currentRow + point[0]][currentColumn + point[1]] = 1; // Ставим 1 на место фигуры
          });

          // Генерируем новую фигуру
          generateRandomShape();
        }
      });
    });
  }


  void generateRandomShape() {
    List<List<List<int>>> shapes = [
      // I-образная (палочка)
      [
        [0, 1], [1, 1], [2, 1], [3, 1]
      ],
      // O-образная (квадрат)
      [
        [0, 0], [0, 1], [1, 0], [1, 1]
      ],
      // T-образная
      [
        [0, 1], [1, 0], [1, 1], [1, 2]
      ],
      // L-образная
      [
        [0, 1], [1, 1], [2, 1], [2, 2]
      ],
      // Зеркальная L-образная
      [
        [0, 1], [1, 1], [2, 1], [2, 0]
      ]
    ];

    // Выбираем случайную фигуру
    currentShape = shapes[DateTime.now().millisecondsSinceEpoch % shapes.length];

    // Находим минимальные и максимальные значения колонок для текущей фигуры
    int minCol = currentShape!.map((point) => point[1]).reduce((a, b) => a < b ? a : b);
    int maxCol = currentShape!.map((point) => point[1]).reduce((a, b) => a > b ? a : b);

    // Вычисляем начальную колонку так, чтобы фигура была по центру
    int shapeWidth = maxCol - minCol + 1;
    currentColumn = (columns - shapeWidth) ~/ 2;

    currentRow = 0; // Начинаем с верхней части поля

    // Проверяем, можно ли разместить новую фигуру в стартовой позиции
    bool canPlaceShape = currentShape!.every((point) {
      return gameBoard[currentRow + point[0]][currentColumn + point[1]] == 0;
    });

    if (!canPlaceShape) {
      // Останавливаем игру, если фигура не может быть размещена
      _fallingTimer?.cancel(); // Останавливаем таймер
      showGameOverDialog(); // Показываем сообщение "Game Over"
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kBottomNavigationBarHeight; // Учитываем высоту статус-бара и нижней панели

    // Определяем максимальный размер клетки, чтобы вписать их в доступное пространство
    final cellWidth = screenWidth / columns;
    final cellHeight = availableHeight / rows;
    // Выбираем минимальное значение для клеток, чтобы они точно помещались на экран
    final cellSize = cellWidth < cellHeight ? cellWidth : cellHeight;

    return Scaffold(
      body: SafeArea(
        child: Column( // Оборачиваем в Column
          children: [
            // Поле для информации
            Container(
              height: 100, // Высота поля для информации
              color: Colors.black12, // Цвет для примера
              alignment: Alignment.center,
              child: const Text(
                'Информация', // Пока что текст-заглушка
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            // Игровое поле
            Expanded( // Используем Expanded, чтобы игровое поле заняло все оставшееся место
              child: Center(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  // Запрет прокрутки
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 1, // Задаем соотношение сторон клеток 1:1 (квадратные клетки)
                  ),
                  itemCount: columns * rows,
                  itemBuilder: (context, index) {
                    int row = index ~/ columns;
                    int col = index % columns;

                    // Проверяем, является ли клетка частью зафиксированной фигуры
                    bool isFixedBlock = gameBoard[row][col] == 1;

                    // Проверяем, является ли эта клетка частью текущей падающей фигуры
                    bool isShapeCell = currentShape!.any((point) {
                      return row == currentRow + point[0] && col == currentColumn + point[1];
                    });

                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isShapeCell || isFixedBlock ? Colors.blue : Colors.grey[300], // Синий блок — либо зафиксированный, либо текущий
                        border: Border.all(color: Colors.black),
                      ),
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}