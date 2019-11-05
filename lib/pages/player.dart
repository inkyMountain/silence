import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:silence/tools/audio_player.dart';

class PlayerState extends State<Player> {
  String songId;
  AudioPlayer player;

  PlayerState({this.songId}) {
  }

  @override
  void initState() {
    super.initState();
    playAudio();
    // player.play('https://music.163.com/song/media/outer/url?id=$songId.mp3');
  }

  Future<Null> playAudio() async {
    if (player == null) {
      player = await getPlayerInstance();
      await player.setReleaseMode(ReleaseMode.STOP);
    }
    final url = 'https://music.163.com/song/media/outer/url?id=$songId.mp3';
    await player.play(url);
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
