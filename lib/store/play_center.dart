import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayer/audioplayer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:silence/tools/http_service/http_service.dart';

class PlayCenter with ChangeNotifier {
  AudioPlayer player;
  Duration duration;
  Duration position;
  Dio _dio;
  bool _hasInitialized = false;

  Map<dynamic, dynamic> _currentPlayingSong;
  Map<dynamic, dynamic> _currentPlayingSongUrl;
  String _songUrl;
  bool _isLocal = false;
  int _currentSongIndex;
  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  Map<dynamic, dynamic> _playlist;
  Directory _appDocDir;

  get currenctPlayingSong => _currentPlayingSong;
  get playlist => _playlist;
  get currentSongIndex => _currentSongIndex;
  get playerState => player.state;

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

  void setCurrenctPlayingSong(Map<dynamic, dynamic> currentPlayingSong) {
    _currentPlayingSong = currentPlayingSong;
    notifyListeners();
  }

  initPlayer() async {
    _currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    player = AudioPlayer();
    _dio = await getDioInstance();
    _addPlayerListeners();
    _appDocDir = await getExternalStorageDirectory();
  }

  void _addPlayerListeners() {
    player.onAudioPositionChanged.listen((Duration position) {
      this.position = position;
      notifyListeners();
    });

    _positionSubscription = player.onAudioPositionChanged
        .listen((position) => () => this.position = position);

    final onPlayError = (msg) {
      duration = new Duration(seconds: 0);
      position = new Duration(seconds: 0);
      next();
      notifyListeners();
    };

    _audioPlayerStateSubscription = player.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) {
        this.duration = player.duration;
      } else if (state == AudioPlayerState.COMPLETED) {
        next();
        this.position = duration;
      }
      notifyListeners();
    }, onError: onPlayError);
  }

  /**
   * 播放优先级: 缓存 > 在线
   * 外界调用play方法前，会提前设置setCurrentPlayingSong & setPlaylist。
   */
  Future<Null> play(String songId) async {
    if (!_hasInitialized) await initPlayer();
    await player.stop();
    final suffixList = await getSuffixList(songId);
    final hasSongBeenCached = suffixList.length > 0;
    hasSongBeenCached
        ? await handleLocalSong(suffixList)
        : await handleOnlineSong(songId);
  }

  Future handleLocalSong(List suffixList) async {
    final escapedFileName = _currentPlayingSong['name'].replaceAll('/', '|');
    _songUrl = '${_appDocDir.path}/$escapedFileName.${suffixList[0]}';
    final songFile = new File(_songUrl);
    final isFileExsits = await songFile.exists();
    if (isFileExsits) {
      _isLocal = true;
      player.play(_songUrl, isLocal: true);
    }
  }

  Future handleOnlineSong(String songId) async {
    const BIT_RATE = 320000;
    Response songUrlResponse =
        await dio.get('/song/url?id=$songId&br=$BIT_RATE');
    _currentPlayingSongUrl = songUrlResponse.data;
    _songUrl = songUrlResponse.data['data'][0]['url'];
    if (_songUrl == null) {
      this.next();
      return;
    }
    await player.play(_songUrl);
    cacheCurrentSong(_songUrl);
    notifyListeners();
  }

  Future<List<dynamic>> getSuffixList(String songId) async {
    final cacheRecordFile = new File('${_appDocDir.path}/cache_record.json');
    if (!await cacheRecordFile.exists()) {
      await cacheRecordFile.create();
    }
    dynamic cacheRecord = await cacheRecordFile.readAsString();
    cacheRecord = cacheRecord == '' ? '{}' : cacheRecord;
    final suffixList = json.decode(cacheRecord)[songId] ?? [];
    return suffixList;
  }

  Future<Null> cacheCurrentSong(String url) async {
    final escapedFileName = _currentPlayingSong['name'].replaceAll('/', '|');
    final songId = _currentPlayingSongUrl['data'][0]['id'];
    final songSuffix = _currentPlayingSongUrl['data'][0]['type'];
    final songFile =
        new File('${_appDocDir.path}/$escapedFileName.$songSuffix');
    final songBytes = await http.readBytes(url);
    await songFile.writeAsBytes(songBytes);
    final cacheRecordFile = new File('${_appDocDir.path}/cache_record.json');
    dynamic cacheRecord = await cacheRecordFile.readAsString();
    cacheRecord = cacheRecord == '' ? Map() : json.decode(cacheRecord);
    List suffixList = cacheRecord[songId.toString()];
    suffixList = suffixList ?? [];
    if (!suffixList.contains(songSuffix)) {
      suffixList.add(songSuffix.toString());
    }
    cacheRecord[songId.toString()] = suffixList;
    await cacheRecordFile.writeAsString(json.encode(cacheRecord), flush: true);
  }

  Future<Null> pause() async {
    await player.pause();
    notifyListeners();
  }

  Future<Null> resume() async {
    await player.play(_songUrl, isLocal: _isLocal);
    notifyListeners();
  }

  previous() {
    int currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    int previousSongIndex = currentSongIndex == 0
        ? _playlist['playlist']['tracks'].length - 1
        : currentSongIndex - 1;
    _currentPlayingSong = _playlist['playlist']['tracks'][previousSongIndex];
    play(_playlist['playlist']['tracks'][previousSongIndex]['id'].toString());
  }

  next() {
    int currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    int nextSongIndex =
        currentSongIndex == _playlist['playlist']['tracks'].length - 1
            ? 0
            : currentSongIndex + 1;
    _currentPlayingSong = _playlist['playlist']['tracks'][nextSongIndex];
    play(_playlist['playlist']['tracks'][nextSongIndex]['id'].toString());
  }

  int getSongIndex(String songId) {
    int currentSongIndex;
    Map<dynamic, dynamic> tracksMap = _playlist['playlist']['tracks'].asMap();
    tracksMap.forEach((index, song) {
      if (song['id'].toString() == songId) {
        currentSongIndex = index;
      }
    });
    _currentSongIndex = currentSongIndex;
    return currentSongIndex;
  }
}
