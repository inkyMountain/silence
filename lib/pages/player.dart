import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/store/play_center.dart';
import 'package:silence/store/store.dart';

class PlayerState extends State<Player> {
  String _songId;

  // 播放状态
  Duration _duration;
  Duration _position;

  PlayerState(this._songId);

  @override
  void initState() {
    super.initState();
    initPage();
  }

  void initPage() async {
    await playAudio();
  }

  Future<Null> playAudio() async {
    await Provider.of<PlayCenter>(context, listen: false).play(_songId);
  }

  Future<Null> pause() async {
    await Provider.of<PlayCenter>(context).pause();
  }

  Future<Null> resume() async {
    await Provider.of<PlayCenter>(context).resume();
  }

  // store.currenctPlayingSong['name']  当前播放的歌曲
  // store.playlist  播放列表
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        Center(
            child: Consumer<PlayCenter>(builder: (context, playCenter, child) {
          return Text("${playCenter.currenctPlayingSong['name']}");
        })),
        Container(
            padding: EdgeInsets.all(40),
            child: Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(Provider.of<PlayCenter>(context).playerState ==
                          AudioPlayerState.PLAYING
                      ? Icons.pause
                      : Icons.play_arrow),
                  onPressed: () {
                    Provider.of<PlayCenter>(context).playerState ==
                            AudioPlayerState.PLAYING
                        ? pause()
                        : resume();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Provider.of<PlayCenter>(context, listen: false).previous();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    Provider.of<PlayCenter>(context, listen: false).next();
                  },
                ),
              ],
            )),
      ],
    ));
  }
}

class Player extends StatefulWidget {
  final songId;
  Player({this.songId});

  @override
  State<StatefulWidget> createState() => PlayerState(songId);
}
