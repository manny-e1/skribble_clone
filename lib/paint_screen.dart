import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:skribbl_clone/final_leaderboard.dart';
import 'package:skribbl_clone/home_screen.dart';
import 'package:skribbl_clone/models/custom_painter.dart';
import 'package:skribbl_clone/models/touch_points.dart';
import 'package:skribbl_clone/sidebar/player_scoreboard_drawer.dart';
import 'package:skribbl_clone/waiting_lobby_screen.dart';
import 'package:skribbl_clone/widgets/custom_text_field.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:skribbl_clone/enums.dart';

class PaintScreen extends StatefulWidget {
  final Map<String, String> data;
  final ScreenFrom screenFrom;
  const PaintScreen({
    Key? key,
    required this.data,
    required this.screenFrom,
  }) : super(key: key);

  @override
  _PaintScreenState createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late IO.Socket _socket;
  Map dataOfRoom= {};
  List<TouchPoints> points = [];
  List<Widget> textBlankWidget = [];
  List<Map<String, dynamic>> messages = [];
  final _scrollController = ScrollController();
  final textController = TextEditingController();
  double strokeWidth = 2;
  Color selectedColor = Colors.black;
  double opacity = 1;

  int guessedUserCtr = 0;
  int _start = 60;
  Timer? _timer;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> scoreboard = [];
  bool isTextInputReadOnly = false;
  int maxPoints = 0;
  String winner = "";
  bool isShowFinalLeaderboard = false;

  @override
  void initState() {
    super.initState();
    connect();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer time) {
      if (_start == 0) {
        _socket.emit('change-turn', dataOfRoom['name']);
        setState(() {
          _timer!.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void connect() {
    _socket = IO.io(
      'http://172.20.10.9:3000',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false
      },
    );
    _socket.connect();
    if (widget.screenFrom == ScreenFrom.createRoom) {
      _socket.emit('create-game', widget.data);
    }else
    {
      _socket.emit('join-game', widget.data);
    }
    _socket.onConnect((data) {
      _socket.on('updateRoom', (roomData) {
        setState(() {
          renderTextBlank(roomData['word']);
          dataOfRoom= roomData;
        });
        if (roomData['isJoin'] != true) {
          startTimer();
        }
        scoreboard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString()
            });
          });
        }
      });
    });

    _socket.on(
        'notCorrectGame',
        (data) => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false));

    _socket.on('points', (point) {
      if (point['details'] != null) {
        final dx = point['details']['dx'];
        final dy = point['details']['dy'];
        setState(() {
          points.add(
            TouchPoints(
              paint: Paint()
                ..strokeCap = StrokeCap.round
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth,
              points: Offset(dx.toDouble(), dy.toDouble()),
            ),
          );
        });
      }
    });

    _socket.on('stroke-width', (data) {
      setState(() {
        strokeWidth = data.toDouble();
      });
    });

    _socket.on('color-change', (data) {
      int value = int.parse(data, radix: 16);
      Color color = Color(value);
      setState(() {
        selectedColor = color;
      });
    });

    _socket.on('clear-screen', (data) {
      setState(() {
        points.clear();
      });
    });

    _socket.on('msg', (data) {
      setState(() {
        messages.add(data);
        guessedUserCtr = data['guessedUserCtr'];
      });
      if (guessedUserCtr == dataOfRoom['players'].length - 1) {
        _socket.emit('change-turn', dataOfRoom['name']);
      }
      if (messages.length >= 3) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn,
        );
      }
    });

    _socket.on('change-turn', (data) {
      String oldWord = dataOfRoom['word'];
      showDialog(
          context: context,
          builder: (context) {
            Future.delayed(const Duration(seconds: 3), () {
              setState(() {
                dataOfRoom= data;
                renderTextBlank(data['word']);
                isTextInputReadOnly = false;
                guessedUserCtr = 0;
                _start = 60;
                points.clear();
              });
              Navigator.of(context).pop();
              _timer!.cancel();
              startTimer();
            });
            return AlertDialog(title: Center(child: Text('Word was $oldWord')));
          });
    });

    _socket.on('updateScore', (roomData) {
      scoreboard.clear();
      for (int i = 0; i < roomData['players'].length; i++) {
        setState(() {
          scoreboard.add({
            'username': roomData['players'][i]['nickname'],
            'points': roomData['players'][i]['points'].toString()
          });
        });
      }
    });

    _socket.on("show-leaderboard", (roomPlayers) {
      scoreboard.clear();
      for (int i = 0; i < roomPlayers.length; i++) {
        setState(() {
          scoreboard.add({
            'username': roomPlayers[i]['nickname'],
            'points': roomPlayers[i]['points'].toString()
          });
        });
        if (maxPoints < int.parse(scoreboard[i]['points'])) {
          winner = scoreboard[i]['username'];
          maxPoints = int.parse(scoreboard[i]['points']);
        }
      }
      setState(() {
        _timer!.cancel();
        isShowFinalLeaderboard = true;
      });
    });

    _socket.on('closeInput', (_) {
      _socket.emit('updateScore', widget.data['name']);
      setState(() {
        isTextInputReadOnly = true;
      });
    });

    _socket.on('user-disconnected', (data) {
      scoreboard.clear();
      for (int i = 0; i < data['players'].length; i++) {
        setState(() {
          scoreboard.add({
            'username': data['players'][i]['nickname'],
            'points': data['players'][i]['points'].toString()
          });
        });
      }
    });
  }

  void renderTextBlank(String text) {
    textBlankWidget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWidget.add(const Text(
        '_',
        style: TextStyle(fontSize: 30),
      ));
    }
  }

  void selectColor() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Choose Color'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: selectedColor,
                onColorChanged: (color) {
                  String colorStr = color.toString();
                  String valueStr = colorStr.split('(0x')[1].split(')')[0];
                  _socket.emit('color-change',
                      {'color': valueStr, 'roomName': dataOfRoom['name']});
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    textController.dispose();
    _socket.dispose();
    _timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      key: scaffoldKey,
      drawer: PlayerScore(scoreboard),
      backgroundColor: Colors.white,
      body: dataOfRoom!= null
          ? dataOfRoom['isJoin'] != true
              ? !isShowFinalLeaderboard
                  ? Stack(
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: size.width,
                              height: size.height * 0.55,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  _socket.emit('paint', {
                                    'details': {
                                      'dx': details.localPosition.dx,
                                      'dy': details.localPosition.dy,
                                    },
                                    'roomName': widget.data['name']
                                  });
                                },
                                onPanStart: (details) {
                                  _socket.emit('paint', {
                                    'details': {
                                      'dx': details.localPosition.dx,
                                      'dy': details.localPosition.dy,
                                    },
                                    'roomName': widget.data['name']
                                  });
                                },
                                onPanEnd: (details) {
                                  _socket.emit('paint', {
                                    'details': null,
                                    'roomName': widget.data['name']
                                  });
                                },
                                child: SizedBox.expand(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      painter: MyCustomPainter(points),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: selectColor,
                                  icon: Icon(
                                    Icons.color_lens,
                                    color: selectedColor,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                      min: 0,
                                      max: 10,
                                      label: 'StrokeWidth $strokeWidth',
                                      value: strokeWidth,
                                      onChanged: (val) {
                                        _socket.emit('stroke-width', {
                                          'value': val,
                                          'roomName': widget.data['name']
                                        });
                                      }),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _socket.emit('clean-screen',
                                        {'roomName': dataOfRoom['name']});
                                  },
                                  icon: Icon(
                                    Icons.layers_clear,
                                    color: selectedColor,
                                  ),
                                ),
                              ],
                            ),
                            dataOfRoom['turn']['nickname'] !=
                                    widget.data['nickname']
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: textBlankWidget,
                                  )
                                : Center(
                                    child: Text(dataOfRoom['word'],
                                        style: const TextStyle(fontSize: 30))),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: messages.length,
                                controller: _scrollController,
                                itemBuilder: (context, index) {
                                  final msg = messages[index].values;
                                  return ListTile(
                                    leading: Text(
                                      msg.elementAt(0),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      msg.elementAt(1),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                },
                              ),
                            ),
                            dataOfRoom['turn']['nickname'] !=
                                    widget.data['nickname']
                                ? Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: CustomTextField(
                                      controller: textController,
                                      hintText: 'Your Guess',
                                      isMessageField: true,
                                      onSubmitted: (value) {
                                        final data = widget.data;
                                        if (value.trim().isNotEmpty) {
                                          Map<String, dynamic> map = {
                                            'username': data['nickname'],
                                            'msg': value.trim(),
                                            'word': dataOfRoom['word'],
                                            'roomName': data['name'],
                                             'guessedUserCtr': guessedUserCtr,
                                            'totalTime': 60,
                                            'timeTaken': 60 - _start,
                                          };
                                          _socket.emit('msg', map);
                                          textController.clear();
                                        }
                                      },
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                        SafeArea(
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black),
                            onPressed: () =>
                                scaffoldKey.currentState!.openDrawer(),
                          ),
                        ),
                      ],
                    )
                  : FinalLeaderboard(scoreboard, winner)
              : WaitingLobbyScreen(
                  lobbyName: dataOfRoom['name'],
                  noOfPlayers: dataOfRoom['players'].length,
                  occupancy: dataOfRoom['occupancy'],
                  players: dataOfRoom['players'],
                )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 7,
          backgroundColor: Colors.white,
          child: Text('$_start',
              style: const TextStyle(color: Colors.black, fontSize: 22)),
        ),
      ),
    );
  }
}
