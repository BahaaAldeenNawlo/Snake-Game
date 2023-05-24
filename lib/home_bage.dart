import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snakegame/blank_pixel.dart';
import 'package:snakegame/food_pixel.dart';
import 'package:snakegame/highscore_tile.dart';
import 'package:snakegame/snake_pixel.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

enum snake_Direction { UP, DOWN, LEFT, RIGHT }

class _HomePageState extends State<HomePage> {
  int currentScore = 0;
  //grid dimensions
  int rowSize = 10;

  int totalNumberOfSquares = 100;

  //snake position

  List snakePos = [0, 1, 2];

  // food position

  int foodPos = 55;

// start the game!

  bool gameHasStarted = false;
  final _nameController = TextEditingController();
  // snake direction is initially to the right
  var currentDirection = snake_Direction.RIGHT;
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        setState(
          () {
            // keep the snake movign!!

            moveSnake();
            
            if (gameOver()) {
              timer.cancel();
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Game Over'),
                      content: Column(
                        children: [
                          Text('Your Score Is $currentScore'),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                hintText: 'Enter Your Name'),
                          ),
                        ],
                      ),
                      actions: [
                        MaterialButton(
                          onPressed: () {
                            submitScore();
                            Navigator.pop(context);
                            newGame();
                          },
                          color: Colors.pink,
                          child: const Text('Submit'),
                        )
                      ],
                    );
                  });
            }
          },
        );
      },
    );
  }

  List<String> highScore_DocIds = [];
  late final Future? letsGetDocId;
  @override
  void initState() {
    letsGetDocId = getDocId();
    super.initState();
  }

  Future getDocId() async {
    await FirebaseFirestore.instance
        .collection('highscores')
        .orderBy('score', descending: true)
        .limit(10)
        .get()
        .then((value) => value.docs.forEach((element) {
              highScore_DocIds.add(element.reference.id);
            }));
  }

  Future newGame() async {
    highScore_DocIds = [];
    await getDocId();
    setState(() {
      snakePos = [0, 1, 2];
      foodPos = 55;
      currentDirection = snake_Direction.RIGHT;
      gameHasStarted = false;
      currentScore = 0;
    });
  }

  void submitScore() {
    var database = FirebaseFirestore.instance;
    database
        .collection('highscores')
        .add({'name': _nameController.text, 'score': currentScore});
  }

  void eatFood() {
    currentScore += 5;
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case snake_Direction.RIGHT:
        {
          // add a head
          // if snake is at the right wall,need to re-adjust
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }

        break;
      case snake_Direction.LEFT:
        {
          // add a head

          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }

        break;
      case snake_Direction.UP:
        {
          // add a head

          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last - rowSize);
          }
        }

        break;
      case snake_Direction.DOWN:
        {
          // add a head

          if (snakePos.last + rowSize > totalNumberOfSquares) {
            snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last + rowSize);
          }
        }

        break;
      default:
    }
    //snake is eating food
    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      snakePos.removeAt(0);
    }
  }

  bool gameOver() {
    List bodySnake = snakePos.sublist(0, snakePos.length - 1);
    if (bodySnake.contains(snakePos.last)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) &&
              currentDirection != snake_Direction.UP) {
            currentDirection = snake_Direction.DOWN;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
              currentDirection != snake_Direction.DOWN) {
            currentDirection = snake_Direction.UP;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft) &&
              currentDirection != snake_Direction.RIGHT) {
            currentDirection = snake_Direction.LEFT;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight) &&
              currentDirection != snake_Direction.LEFT) {
            currentDirection = snake_Direction.RIGHT;
          }
        },
        child: SizedBox(
          width: screenWidth > 428 ? 428 : screenWidth,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Current Score Is ',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            currentScore.toString(),
                            style: const TextStyle(
                                fontSize: 36, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: gameHasStarted
                          ? Container()
                          : FutureBuilder(
                              future: letsGetDocId,
                              builder: ((context, snapshot) {
                                return ListView.builder(
                                  itemCount: highScore_DocIds.length,
                                  itemBuilder: (context, index) {
                                    return HighScoreTile(
                                        documentId: highScore_DocIds[index]);
                                  },
                                );
                              })),
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0 &&
                        currentDirection != snake_Direction.UP) {
                      currentDirection = snake_Direction.DOWN;
                    } else if (details.delta.dy < 0 &&
                        currentDirection != snake_Direction.DOWN) {
                      currentDirection = snake_Direction.UP;
                    }
                  },
                  onHorizontalDragUpdate: (detials) {
                    if (detials.delta.dx > 0 &&
                        currentDirection != snake_Direction.LEFT) {
                      currentDirection = snake_Direction.RIGHT;
                    } else if (detials.delta.dx < 0 &&
                        currentDirection != snake_Direction.RIGHT) {
                      currentDirection = snake_Direction.LEFT;
                    }
                  },
                  child: GridView.builder(
                      itemCount: totalNumberOfSquares,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rowSize,
                      ),
                      itemBuilder: (context, index) {
                        if (snakePos.contains(index)) {
                          return SnakePixel();
                        } else if (foodPos == index) {
                          return const FoodPixel();
                        } else {
                          return const BlankPixel();
                        }
                      }),
                ),
              ),
              Expanded(
                  child: Container(
                child: Center(
                  child: MaterialButton(
                    onPressed: gameHasStarted ? () {} : startGame,
                    // onPressed: () async {
                    //   // FirebaseFirestore.instance
                    //   //     .collection('user')
                    //   //     .add({'name': 'jfdkjfd'});

                    //   // FirebaseFirestore.instance
                    //   //     .collection('user')
                    //   //     .doc('mnb')
                    //   //     .set({'djfkdjfk': 6});

                    //   // var s = await FirebaseFirestore.instance
                    //   //     .collection('user')
                    //   //     .doc('mnb')
                    //   //     .get();
                    //   // print(s.data());

                    //   // var s =
                    //   //     FirebaseFirestore.instance.collection('user').snapshots();
                    //   // s.listen((event) {
                    //   //   print(event.docs[1].data());
                    //   // });

                    //   // FirebaseFirestore.instance
                    //   //     .collection('user')
                    //   //     .doc('mnb')
                    //   //     .collection('data')
                    //   //     .add({'jdkfjdlk': 44});
                    // },
                    color: gameHasStarted ? Colors.blueGrey : Colors.blue,
                    child: const Text('PLAY'),
                  ),
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
