import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../http_service/http_service.dart';

class PlayerState extends State<Player> {
  String songId;
  PlayerState({this.songId});
  AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    AudioPlayer.logEnabled = true;
    play();
    // player.play('https://music.163.com/song/media/outer/url?id=$songId.mp3');
  }

  void play() async {
    final url = 'https://music.163.com/song/media/outer/url?id=$songId.mp3';
    final result = await player.play(url);
    print('Audio playing result:');
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('播放器'),
      ),
      body: Center(child: Text('$songId')),
    );
  }

}

class Player extends StatefulWidget {
  final songId;
  Player({this.songId});

  @override
  State<StatefulWidget> createState() => PlayerState(songId: songId);
}
