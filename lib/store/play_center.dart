import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence/tools/http_service.dart';
import 'package:silence/store/lyric_helper.dart';
// import 'package:flutter_exoplayer/audioplayer.dart';

class PlayCenter with ChangeNotifier {
  AudioPlayer player = AudioPlayer();
  Duration duration;
  Duration position;
  bool _hasInitialized = false;

  Map<dynamic, dynamic> _songData;
  Map<dynamic, dynamic> _songUrlData;
  Dio _dio;
  SharedPreferences _preferences;
  String _songUrl;
  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  Map<dynamic, dynamic> _playlist;
  List<Map<String, dynamic>> _positionListeners = [];
  Map<String, List<Map>> _computedLyrics;
  bool _isLocal = false;
  Directory _appDocDir;
  List<String> _cachedFilePaths = [];

  get currentPlayingSong => _songData;
  get playlist => _playlist;
  get playerState => player == null ? AudioPlayerState.STOPPED : player.state;
  get lyrics => _computedLyrics;
  get songIndex => getSongIndex(currentPlayingSong['id'].toString());

  @override
  void dispose() {
    super.dispose();
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    player.stop();
  }

  void setPlaylist(Map<dynamic, dynamic> playlist) {
    _playlist = playlist;
    notifyListeners();
  }

  void setCurrentPlayingSong(Map<dynamic, dynamic> songData) {
    _songData = songData;
    notifyListeners();
  }

  init() async {
    _dio = _dio ?? await getDioInstance();
    _addPlayerListeners();
    _appDocDir = await getExternalStorageDirectory();
    await _appDocDir.list().forEach((file) => _cachedFilePaths.add(file.path));
    _hasInitialized = true;
  }

  readCachedPlayInfo() async {
    _preferences = _preferences ?? await SharedPreferences.getInstance();
    String cachedPlaylist = _preferences.getString('playlist');
    String cachedSongData = _preferences.getString('songData');
    _playlist = cachedPlaylist == null ? null : json.decode(cachedPlaylist);
    _songData = cachedSongData == null ? null : json.decode(cachedSongData);
    notifyListeners();
  }

  void _addPlayerListeners() {
    player.onAudioPositionChanged.listen((Duration position) {
      this.position = position;
      _positionListeners.forEach((map) {
        map['listener'](position);
      });
      notifyListeners();
    });
    final onPlayError = (msg) {
      duration = Duration(seconds: 0);
      position = Duration(seconds: 0);
      next();
      notifyListeners();
    };
    _audioPlayerStateSubscription = player.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) this.duration = player.duration;
      if (state == AudioPlayerState.COMPLETED) next();
      notifyListeners();
    }, onError: onPlayError);
  }

  // check duplicate before put in
  void addPositionListener(String source, Function listener) {
    final duplicates = _positionListeners
        .where((listenerMap) => listenerMap['source'] == source);
    duplicates.length >= 1
        ? duplicates.toList()[0]['listener'] = listener
        : _positionListeners.add({'source': source, 'listener': listener});
  }

  /// play cache before online
  /// 外界调用play方法前，会提前设置setsongData & setPlaylist。
  /// Todo 用户删除缓存时的处理
  Future<Null> play([String songId]) async {
    if (_songData == null && _playlist == null) await readCachedPlayInfo();
    if (!_hasInitialized) await init();
    await player.stop();
    List<String> targets = _cachedFilePaths.where((path) {
      List<String> fragments = path.split('/');
      return fragments[fragments.length - 1].contains(_songData['name']);
    }).toList();
    if (songId == null && _songData == null) return;
    songId = songId ?? _songData['id'].toString();
    targets.length > 0
        ? await playCache(targets[0])
        : await playOnline(songId.toString());
    _computedLyrics =
        await LyricHelper(songId ?? _songData['id'].toString()).getLyrics();
    cachePlayData();
  }

  cachePlayData() async {
    _preferences.setString('playlist', json.encode(_playlist));
    _preferences.setString('songData', json.encode(_songData));
  }

  Future playCache(String path) async {
    List<String> fragments = path.split('/');
    final escapedName = fragments[fragments.length - 1].replaceAll('/', '|');
    _songUrl = '${_appDocDir.path}/$escapedName';
    _isLocal = true;
    player.play(_songUrl, isLocal: _isLocal);
  }

  Future playOnline(String songId) async {
    const BIT_RATE = 128000;
    _songUrlData = (await dio.post('/song/url?id=$songId&br=$BIT_RATE')).data;
    _songUrl = _songUrlData['data'][0]['url'];
    if (_songUrl == null) return this.next();
    player.play(_songUrl);
    String fileName = '${_songData['name']}.${_songUrlData['data'][0]['type']}';
    cacheSongFile(_songUrl, fileName);
    notifyListeners();
  }

  Future<Null> cacheSongFile(String url, String fileName) async {
    final escapedFileName = fileName.replaceAll('/', '|');
    File songFile = File('${_appDocDir.path}/$escapedFileName');
    final songBytes = await http.readBytes(url);
    if (await songFile.exists()) return;
    await songFile.writeAsBytes(songBytes);
    _cachedFilePaths.add(songFile.path);
  }

  Future<Null> pause() async {
    await player.pause();
    notifyListeners();
  }

  Future<Null> resume() async {
    await player.play(_songUrl, isLocal: _isLocal);
    notifyListeners();
  }

  Future<Null> stop() async {
    await player.stop();
    notifyListeners();
  }

  previous() {
    int songIndex = getSongIndex(_songData['id'].toString());
    int previousSongIndex = songIndex == 0
        ? _playlist['playlist']['tracks'].length - 1
        : songIndex - 1;
    _songData = _playlist['playlist']['tracks'][previousSongIndex];
    play(_playlist['playlist']['tracks'][previousSongIndex]['id'].toString());
  }

  next() {
    int songIndex = getSongIndex(_songData['id'].toString());
    int nextSongIndex = songIndex == _playlist['playlist']['tracks'].length - 1
        ? 0
        : songIndex + 1;
    _songData = _playlist['playlist']['tracks'][nextSongIndex];
    play(_playlist['playlist']['tracks'][nextSongIndex]['id'].toString());
  }

  int getSongIndex(String songId) {
    int songIndex;
    Map tracksMap = _playlist['playlist']['tracks'].asMap();
    tracksMap.forEach((index, song) =>
        songIndex = song['id'].toString() == songId ? index : songIndex);
    return songIndex;
  }
}
