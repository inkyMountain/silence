import 'dart:math';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:silence/store/play_center.dart';

class PlayerState extends State<Player> {
  String _songId;
  final _scrollController = ScrollController();
  GlobalKey _listTileKey = GlobalKey();
  PlayCenter playCenter;
  double _tileContainerHeight = 0;
  static const int VISIBLE_SONG_NUMBER = 8;

  PlayerState(this._songId);

  @override
  void initState() {
    super.initState();
    init();
  }

  // 不可以缩减成一个方法，因为initState不允许加上async修饰符。
  void init() async {
    playCenter = Provider.of<PlayCenter>(context, listen: false);
    if (_songId != null) await playCenter.play(_songId);
  }

  void _setScrollTop() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      int songNumber = Provider.of<PlayCenter>(context)
          .playlist['playlist']['tracks']
          .length;
      int currentSongIndex = Provider.of<PlayCenter>(context).currentSongIndex;
      final RenderBox containerRenderBox =
          _listTileKey.currentContext.findRenderObject();
      _tileContainerHeight = containerRenderBox.size.height;
      setState(() {});
      if (songNumber > VISIBLE_SONG_NUMBER) {
        final jumpNumber =
            (songNumber - currentSongIndex) >= VISIBLE_SONG_NUMBER
                ? currentSongIndex
                : (songNumber - VISIBLE_SONG_NUMBER);
        _scrollController.jumpTo(_tileContainerHeight * jumpNumber);
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
                      controller: _scrollController,
                      itemCount: tracks.length,
                      itemBuilder: playlistItemBuilder)))
        ]));
  }

  // store.currenctPlayingSong['name']  当前播放的歌曲
  // store.playlist  播放列表
  @override
  Widget build(BuildContext context) {
    final currentSongName =
        Provider.of<PlayCenter>(context).currenctPlayingSong['name'];
    return Scaffold(
        body: Stack(children: <Widget>[
      AppBar(),
      Container(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
            Expanded(child: Center(child: Text(currentSongName))),
            buildMusicControls()
          ]))
    ]));
  }

  Widget buildMusicControls() {
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
