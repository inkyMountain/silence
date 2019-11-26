import 'package:audioplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:silence/store/play_center.dart';
import 'package:silence/tools/calc_box_size.dart';
import 'package:silence/tools/http_service.dart';

class PlayerState extends State<Player> with TickerProviderStateMixin {
  PlayerState(this._songId);

  // Data
  String _songId;
  static const int VISIBLE_SONG_NUMBER = 8;
  int _lastLyricIndex = 0;
  Map<int, double> _lyricHeights = {};

  // Animation
  Animation<double> animation;
  AnimationController animationController;
  Map<String, dynamic> lyrics;

  // Tool
  Dio _dio;
  PlayCenter playCenter;
  final _playlistScrollController = ScrollController();

  // Box size
  double _lyricAreaHeight = 250;
  GlobalKey _lyricAreaKey = GlobalKey();
  double _tileContainerHeight = 0;
  GlobalKey _listTileKey = GlobalKey();

  @override
  void dispose() {
    _playlistScrollController.dispose();
    if (animation != null && animationController != null) {
      animation.removeListener(animationListener);
      animationController.dispose();
      animationController = null;
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    _dio = _dio ?? await getDioInstance();
    playCenter = Provider.of<PlayCenter>(context, listen: false);
    _listenPositionChange();
    if (_songId != null) await playCenter.play(_songId);
  }

  void _listenPositionChange() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      playCenter.addPositionListener((duration) {
        if (lyrics == null) return;
        int index;
        lyrics['computed']['original'].asMap().forEach((i, lyric) {
          if (lyric['duration'] >= duration && index == null) {
            index = (i - 1);
          }
        });
        if (index == null) {
          List original = lyrics['computed']['original'];
          index = original.length - 1;
        }
        if (_lastLyricIndex != index && index != null) {
          double totalHeight = 0;
          _lyricHeights.forEach((i, height) {
            if (i < index - 1) totalHeight += height;
          });
          if (index >= 1) {
            _scrollLyrics(totalHeight, totalHeight + _lyricHeights[index - 1]);
          }
          _lastLyricIndex = index;
        }
      });
    });
  }

  void _createAnimationCooperators(
      double begin, double end, Duration duration) {
    if (animationController != null) {
      animationController.dispose();
      animation.removeListener(animationListener);
    }
    animationController = AnimationController(duration: duration, vsync: this);
    Animation curvedAnimation =
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut);
    animation = Tween(begin: begin, end: end).animate(curvedAnimation)
      ..addListener(animationListener);
  }

  void animationListener() {
    if (this.mounted) setState(() {});
  }

  void _scrollLyrics(double from, double to) {
    _createAnimationCooperators(from, to, Duration(milliseconds: 500));
    animationController.forward();
  }

  void _measureBoxesSize() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _lyricAreaHeight = calcBoxSize(_lyricAreaKey)['height'];
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
    if (lyrics['computed'] == null) return Center(child: Text(''));
    List originalLyrics = lyrics['computed']['original'];
    List translatedLyrics = lyrics['computed']['translation'];
    bool hasTranslation = translatedLyrics.length > 0;
    final lyricsList = originalLyrics
        .asMap()
        .map((index, map) {
          return MapEntry(index, Builder(
            builder: (context) {
              SchedulerBinding.instance.addPostFrameCallback(
                  (_) => _lyricHeights.addAll({index: context.size.height}));
              return Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Column(
                      children: buildSentence(
                          originalLyrics[index]['lyric'],
                          hasTranslation
                              ? translatedLyrics[index]['lyric']
                              : null,
                          index)));
            },
          ));
        })
        .values
        .toList();
    double lyricsTop = _lyricAreaHeight / 2 -
        (_lyricHeights[0] ?? 0) / 2 - // 控制中间蓝色歌词的高度
        (animation == null ? 0 : animation.value);
    return Stack(key: _lyricAreaKey, children: <Widget>[
      Positioned(
          top: lyricsTop,
          left: 0,
          right: 0,
          child: Container(child: Column(children: lyricsList)))
    ]);
  }

  List<Widget> buildSentence(String original, [String translation, int index]) {
    Function buildText = (String content) => Text(content,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: index == _lastLyricIndex ? Colors.blue : Colors.black));
    List<Widget> list = [buildText(original)];
    if (translation != null && translation != '')
      list.add(buildText(translation));
    return list;
  }

  Widget buildControlsButtons() {
    return Container(
        padding: EdgeInsets.only(bottom: 40, left: 50, right: 50),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    final songId = Provider.of<PlayCenter>(context)
                        .currenctPlayingSong['id'];
                    dio.post('${interfaces['like']}?id=$songId&like=true');
                  }),
              IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    playCenter.previous();
                  }),
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
                  onPressed: () {
                    playCenter.next();
                  }),
              IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => showModalBottomSheet(
                      context: context, builder: buildPlayingList()))
            ]));
  }

  @override
  Widget build(BuildContext context) {
    _measureBoxesSize();
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
}

class Player extends StatefulWidget {
  Player({this.songId});

  final songId;

  @override
  State<StatefulWidget> createState() => PlayerState(songId);
}
