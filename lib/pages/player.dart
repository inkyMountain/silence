import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/audio_player.dart';

class PlayerState extends State<Player> {
  String songId;
  AudioPlayer player;

  PlayerState({this.songId});

  @override
  void initState() {
    super.initState();
    playAudio();
    Consumer<Store>(builder: (context, store, child) {
      print(111);
      print(store);
      return Text('');
    });
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
        body: Center(child: Consumer<Store>(builder: (context, store, child) {
      return Text("${store.currenctPlayingSong['name']}");
    })));
  }
}

class Player extends StatefulWidget {
  final songId;
  Player({this.songId});

  @override
  State<StatefulWidget> createState() => PlayerState(songId: songId);
}
