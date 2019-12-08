import 'package:flutter_exoplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:silence/store/play_center.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/calc_box_size.dart';
import 'package:silence/tools/http_service.dart';

class PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  PlayerPageState(this._songId);

  // Data
  String _songId;
  static const int VISIBLE_SONG_NUMBER = 8;
  int _lastLyricIndex = 0;
  Map<int, double> _lyricHeights = {-1: 0, -2: 0, -3: 0};

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
    // lyrics scroll animation
    SchedulerBinding.instance.addPostFrameCallback((_) {
      playCenter.addPositionListener('player', (duration) {
        if (lyrics == null) return;
        List<Map> original = lyrics['original'];
        Map currentLyric = original.firstWhere(
            (lyric) => lyric['duration'] >= duration,
            orElse: () => null);
        // 减1以后才是正在唱的歌词,最后一句歌词需要特殊处理.
        int index = original.indexOf(currentLyric) - 1;
        index = index == -2 ? original.length - 1 : index;
        if (_lastLyricIndex == index) return;
        double totalHeight = 0;
        _lyricHeights
            .forEach((i, height) => totalHeight += i < index ? height : 0.0);
        _scrollLyrics(
            start: totalHeight, end: totalHeight + _lyricHeights[index]);
        _lastLyricIndex = index;
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

  void _scrollLyrics({@required double start, @required double end}) {
    _createAnimationCooperators(start, end, Duration(milliseconds: 500));
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
      int currentSongIndex = Provider.of<PlayCenter>(context).songIndex;
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
                color:
                    Provider.of<PlayCenter>(context).currentPlayingSong['id'] ==
                            tracks[index]['id']
                        ? Colors.blue
                        : Colors.black)),
        onTap: () => playCenter
          ..setCurrentPlayingSong(tracks[index])
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
    if (lyrics == null) return Center(child: Text(''));
    List originalLyrics = lyrics['original'];
    List translatedLyrics = lyrics['translation'];
    bool hasTranslation = translatedLyrics.length > 0;
    final lyricsList = originalLyrics
        .asMap()
        .map((index, map) {
          return MapEntry(index, Builder(builder: (context) {
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
          }));
        })
        .values
        .toList();
    double lyricsTop = _lyricAreaHeight / 2 +
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
    if (translation != null && translation != '') {
      list.add(buildText(translation));
    }
    return list;
  }

  Widget buildControlsButtons() {
    final playCenter = Provider.of<PlayCenter>(context);
    final store = Provider.of<Store>(context);
    String songId = playCenter.currentPlayingSong['id'].toString();
    bool isLiked = store.isThisSongBeenLiked(songId);
    return Container(
        padding: EdgeInsets.only(bottom: 40, left: 50, right: 50),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                  onPressed: () async {
                    Response likeResponse = await dio.post(interfaces['like'],
                        queryParameters: {
                          'id': songId,
                          'like': !isLiked,
                          'timestamp': DateTime.now()
                        });
                    if (likeResponse.statusCode == 200 && !isLiked) {
                      store.addLikedSong(playCenter.currentPlayingSong);
                    }
                    if (likeResponse.statusCode == 200 && isLiked) {
                      store.removeLikedSong(songId);
                    }
                    //
                  }),
              IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => playCenter.previous()),
              IconButton(
                  icon: Icon(Provider.of<PlayCenter>(context).playerState ==
                          PlayerState.PLAYING
                      ? Icons.pause
                      : Icons.play_arrow),
                  onPressed: () =>
                      Provider.of<PlayCenter>(context).playerState ==
                              PlayerState.PLAYING
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
        Provider.of<PlayCenter>(context).currentPlayingSong['name'];

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

class PlayerPage extends StatefulWidget {
  PlayerPage({this.songId});

  final songId;

  @override
  State<StatefulWidget> createState() => PlayerPageState(songId);
}
