import 'package:audioplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:silence/store/play_center.dart';
import 'package:silence/tools/calcBoxSize.dart';
import 'package:silence/tools/http_service.dart';

class PlayerState extends State<Player> {
  String _songId;
  final _playlistScrollController = ScrollController();
  final _lyricsScrollController = ScrollController();
  Dio _dio;
  GlobalKey _listTileKey = GlobalKey();
  PlayCenter playCenter;
  double _tileContainerHeight = 0;
  List<Map<String, String>> _lyricMaps;
  static const int VISIBLE_SONG_NUMBER = 8;

  PlayerState(this._songId);

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    _dio = _dio ?? await getDioInstance();
    playCenter = Provider.of<PlayCenter>(context, listen: false);
    if (_songId != null) await playCenter.play(_songId);
  }

  @override
  Widget build(BuildContext context) {
    String songName =
        Provider.of<PlayCenter>(context).currenctPlayingSong['name'];

    return Scaffold(
        body: Stack(children: <Widget>[
      AppBar(
          title: Text(songName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      Container(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
            Expanded(
                child: Container(
                    padding: EdgeInsets.only(
                        left: 70, right: 70, top: 40, bottom: 10),
                    child: buildLyrics())),
            buildControlsButtons()
          ]))
    ]));
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
        _playlistScrollController.animateTo(_tileContainerHeight * jumpNumber,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      setState(() {});
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

  buildLyrics() {
    String lyrics;
    try {
      lyrics =
          Provider.of<PlayCenter>(context).currentSongLyric['lrc']['lyric'];
    } catch (e) {
      lyrics = '';
    }
    List<String> timeAndLyric = lyrics.split('\n');
    _lyricMaps = timeAndLyric.map((sentence) {
      String time = sentence.split(']')[0];
      String lyric = sentence.split(']').sublist(1).join();
      return {'time': time, 'lyric': lyric};
    }).toList();
    if (lyrics == null || lyrics == '' || lyrics.contains('纯音乐请欣赏')) {
      return Center(
          child: Text(
        'Sometimes rhythm touch you deeper than lyrics.',
        style: TextStyle(height: 2, fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ));
    }
    return Column(children: <Widget>[
      Expanded(
          child: ListView.builder(
        controller: _lyricsScrollController,
        itemCount: _lyricMaps.length,
        itemBuilder: (context, index) => Container(
            alignment: Alignment.center,
            child: Text(_lyricMaps[index]['lyric'])),
      ))
    ]);
  }

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

  // store.currenctPlayingSong['name']  当前播放的歌曲
  // store.playlist  播放列表

}

class Player extends StatefulWidget {
  final songId;
  Player({this.songId});

  @override
  State<StatefulWidget> createState() => PlayerState(songId);
}
