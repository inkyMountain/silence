import 'package:audioplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:silence/store/play_center.dart';
import 'package:silence/tools/calcBoxSize.dart';
import 'package:silence/tools/http_service.dart';

class PlayerState extends State<Player> with TickerProviderStateMixin {
  // Tool
  Dio _dio;
  PlayCenter playCenter;
  // Data
  String _songId;
  static const int VISIBLE_SONG_NUMBER = 8;
  Map<String, dynamic> lyrics;
  int _currentLyricIndex;
  // Box size
  double _tileContainerHeight = 0;
  GlobalKey _listTileKey = GlobalKey();
  double _singleLyricHeight = 0;
  GlobalKey _singleLyricKey = GlobalKey();
  final _playlistScrollController = ScrollController();
  // Animation
  Animation<double> animation;
  AnimationController animationController;

  PlayerState(this._songId);

  @override
  void initState() {
    super.initState();
    init();
  }

  void createAnimationCooperators(Duration duration, double begin, double end) {
    if (animationController != null) {
      animationController.dispose();
    }
    animationController = AnimationController(duration: duration, vsync: this);
    Animation curvedAnimation =
        CurvedAnimation(parent: animationController, curve: Curves.ease);
    animation = Tween(begin: begin, end: end).animate(curvedAnimation)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _playlistScrollController.dispose();
  }

  void init() async {
    _dio = _dio ?? await getDioInstance();
    playCenter = Provider.of<PlayCenter>(context, listen: false);
    _measureBoxesSize();
    _listenPositionChange();
    if (_songId != null) await playCenter.play(_songId);
  }

  void _listenPositionChange() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      playCenter.addPositionListener((duration) {
        if (lyrics == null) return;
      });

      // todo
      // createAnimationCooperators(
      //     const Duration(seconds: 10), 0.0, _singleLyricHeight * 10 ?? 10.0);
      // animationController.forward();
    });
  }

  void _measureBoxesSize() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _singleLyricHeight = calcBoxSize(_singleLyricKey)['height'];
    });
  }

  void _setScrollTop() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      int songNumber = Provider.of<PlayCenter>(context)
          .playlist['playlist']['tracks']
          .length;
      int currentSongIndex = Provider.of<PlayCenter>(context).currentSongIndex;
      _tileContainerHeight = calcBoxSize(_listTileKey)['height'];
      if (songNumber > VISIBLE_SONG_NUMBER) {
        final jumpNumber =
            (songNumber - currentSongIndex) >= VISIBLE_SONG_NUMBER
                ? currentSongIndex
                : (songNumber - VISIBLE_SONG_NUMBER);
        _playlistScrollController.jumpTo(_tileContainerHeight * jumpNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String songName =
        Provider.of<PlayCenter>(context).currenctPlayingSong['name'];

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            elevation: 0,
            title: Text(songName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        body: Stack(children: <Widget>[
          Container(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                Expanded(
                    child: Container(
                        padding: EdgeInsets.only(left: 40, right: 40),
                        child: buildLyrics())),
                buildControlsButtons()
              ]))
        ]));
  }

  Function buildPlayingList() {
    _setScrollTop();
    final tracks =
        Provider.of<PlayCenter>(context).playlist['playlist']['tracks'];
    final playlistItemBuilder = (BuildContext context, int index) => ListTile(
        key: index == 0 ? _listTileKey : null,
        dense: true,
        title: Text(tracks[index]['name'],
            style: TextStyle(
                color: Provider.of<PlayCenter>(context)
                            .currenctPlayingSong['id'] ==
                        tracks[index]['id']
                    ? Colors.blue
                    : Colors.black)),
        onTap: () => playCenter
          ..setCurrenctPlayingSong(tracks[index])
          ..play(tracks[index]['id'].toString()));

    return (context) => Container(
        height: _tileContainerHeight * VISIBLE_SONG_NUMBER,
        child: Column(children: <Widget>[
          Expanded(
              child: Scrollbar(
                  child: ListView.builder(
                      controller: _playlistScrollController,
                      itemCount: tracks.length,
                      itemBuilder: playlistItemBuilder)))
        ]));
  }

  Widget buildLyrics() {
    lyrics = Provider.of<PlayCenter>(context).lyrics;
    final originalLyrics = lyrics['computed']['original'];
    final translatedLyrics = lyrics['computed']['translated'];
    return lyrics['exist']
        ? Stack(children: <Widget>[
            Positioned(
                top: animation == null ? 0 : -animation.value,
                bottom: 0,
                left: 0,
                right: 0,
                child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: originalLyrics.length,
                    itemBuilder: (context, index) => Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        key: index == 0 ? _singleLyricKey : null,
                        alignment: Alignment.center,
                        child: Column(children: <Widget>[
                          buildLyric(originalLyrics[index]['lyric']),
                          buildLyric(translatedLyrics[index]['lyric'])
                        ]))))
          ])
        : Center(
            child: Text(
            'Sometimes rhythm touch you deeper than lyrics.',
            style:
                TextStyle(height: 2, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ));
  }

  Widget buildLyric(String content) => Text(content,
      textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5));

  Widget buildControlsButtons() {
    return Container(
        padding: EdgeInsets.only(bottom: 40, left: 50, right: 50),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => playCenter.previous(),
              ),
              IconButton(
                  icon: Icon(Provider.of<PlayCenter>(context).playerState ==
                          AudioPlayerState.PLAYING
                      ? Icons.pause
                      : Icons.play_arrow),
                  onPressed: () =>
                      Provider.of<PlayCenter>(context).playerState ==
                              AudioPlayerState.PLAYING
                          ? playCenter.pause()
                          : playCenter.resume()),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () => playCenter.next(),
              ),
              IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => showModalBottomSheet(
                      context: context, builder: buildPlayingList()))
            ]));
  }
}

class Player extends StatefulWidget {
  final songId;
  Player({this.songId});

  @override
  State<StatefulWidget> createState() => PlayerState(songId);
}
