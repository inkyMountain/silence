import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:silence/store/play_center.dart';

class PlayerState extends State<Player> {
  String _songId;
  final _scrollController = ScrollController();
  GlobalKey _listTileKey = GlobalKey();

  PlayerState(this._songId);

  @override
  void initState() {
    super.initState();
    initPage();
  }

  jumpIndex(int index) {
    final RenderBox containerRenderBox =
        _listTileKey.currentContext.findRenderObject();
    final tileContainerHeight = containerRenderBox.size.height;
    _scrollController.jumpTo(tileContainerHeight * index);
  }

  // 不可以缩减成一个方法，因为initState不允许加上async修饰符。
  void initPage() async {
    if (_songId != null) {
      play();
    }
  }

  Future<Null> play() async {
    await Provider.of<PlayCenter>(context, listen: false).play(_songId);
  }

  Future<Null> pause() async {
    await Provider.of<PlayCenter>(context).pause();
  }

  Future<Null> resume() async {
    await Provider.of<PlayCenter>(context).resume();
  }

  Function buildPlayingList() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final currentSongIndex =
          Provider.of<PlayCenter>(context).currentSongIndex;
      jumpIndex(currentSongIndex);
    });
    final tracks =
        Provider.of<PlayCenter>(context).playlist['playlist']['tracks'];
    return (context) => Container(
        height: 600,
        child: Column(children: <Widget>[
          Expanded(
              child: Scrollbar(
                  child: ListView.builder(
                      controller: _scrollController,
                      itemCount: tracks.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                            key: index == 0 ? _listTileKey : null,
                            dense: true,
                            title: Text(tracks[index]['name'],
                                style: TextStyle(
                                    color: Provider.of<PlayCenter>(context)
                                                .currenctPlayingSong['id'] ==
                                            tracks[index]['id']
                                        ? Colors.blue
                                        : Colors.black)),
                            onTap: () {
                              Provider.of<PlayCenter>(context)
                                  .setCurrenctPlayingSong(tracks[index]);
                              Provider.of<PlayCenter>(context)
                                  .play(tracks[index]['id'].toString());
                            });
                      })))
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
                onPressed: () =>
                    Provider.of<PlayCenter>(context, listen: false).previous(),
              ),
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
                  }),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () =>
                    Provider.of<PlayCenter>(context, listen: false).next(),
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
