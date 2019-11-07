import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/audio_player.dart';

class PlayerState extends State<Player> {
  String songId;
  AudioPlayer player;

  // 播放状态
  Duration _duration;
  Duration _position;
  AudioPlayerState _playerState;

  PlayerState({this.songId});

  @override
  void initState() {
    super.initState();
    initPage();
  }

  void initPage() async {
    await playAudio();
    addPlayerListeners();
  }

  void addPlayerListeners() {
    player.onDurationChanged.listen((Duration duration) {
      print('Max duration: $duration');
      setState(() => _duration = duration);
    });
    player.onAudioPositionChanged.listen((Duration position) {
      print('Current position: $position');
      setState(() => _position = position);
    });
    player.onPlayerStateChanged.listen((AudioPlayerState state) {
      print('Current player state: $state');
      setState(() => _playerState = state);
    });
    player.onPlayerCompletion.listen((event) {
      print('music play complete');
      setState(() => _position = _duration);
    });
    player.onPlayerError.listen((error) {
      print('audioPlayer error : $error');
      setState(() {
        _playerState = AudioPlayerState.STOPPED;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });
  }

  Future<Null> playAudio() async {
    if (player == null) {
      player = await getPlayerInstance();
      await player.setReleaseMode(ReleaseMode.STOP);
    }
    final url = 'https://music.163.com/song/media/outer/url?id=$songId.mp3';
    await player.play(url);
    setState(() {
      _playerState = AudioPlayerState.PLAYING;
    });
  }

  // store.currenctPlayingSong['name']  当前播放的歌曲
  // store.playlist  播放列表
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        Center(child: Consumer<Store>(builder: (context, store, child) {
          return Text("${store.currenctPlayingSong['name']}");
        })),
        Container(
          padding: EdgeInsets.all(40),
          child: IconButton(
            icon: Icon(_playerState == AudioPlayerState.PLAYING
                ? Icons.pause
                : Icons.play_arrow),
            onPressed: () {
              _playerState == AudioPlayerState.PLAYING
                  ? player.pause()
                  : player.resume();
            },
          ),
        )
      ],
    ));
  }
}

class Player extends StatefulWidget {
  final songId;
  Player({this.songId});

  @override
  State<StatefulWidget> createState() => PlayerState(songId: songId);
}
