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
  AudioPlayerState playerState;
  Dio _dio;
  bool _hasInitialized = false;

  Map<dynamic, dynamic> _currentPlayingSong;
  Map<dynamic, dynamic> _currentPlayingSongUrl;
  int _currentSongIndex;
  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  String _songUrl;
  Map<dynamic, dynamic> _playlist;
  Directory _appDocDir;

  get currenctPlayingSong => _currentPlayingSong;
  get playlist => _playlist;
  get currentSongIndex => _currentSongIndex;

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
    // player = await getPlayerInstance();
    _currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    player = AudioPlayer();
    _dio = await getDioInstance();
    // await player.setReleaseMode(ReleaseMode.STOP);
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
      playerState = AudioPlayerState.STOPPED;
      duration = new Duration(seconds: 0);
      position = new Duration(seconds: 0);
      next();
      notifyListeners();
    };

    _audioPlayerStateSubscription = player.onPlayerStateChanged.listen((state) {
      playerState = state;
      if (state == AudioPlayerState.PLAYING) {
        this.duration = player.duration;
      } else if (state == AudioPlayerState.COMPLETED) {
        next();
        this.position = duration;
      }
      notifyListeners();
    }, onError: onPlayError);
  }

  // 播放优先: 缓存 > 在线
  Future<Null> play(String songId) async {
    if (!_hasInitialized) await initPlayer();
    await player.stop();
    playerState = AudioPlayerState.PLAYING;

    final cacheRecordFile = new File('${_appDocDir.path}/cache_record.json');
    if (!await cacheRecordFile.exists()) {
      await cacheRecordFile.create();
    }
    dynamic cacheRecord = await cacheRecordFile.readAsString();
    cacheRecord = cacheRecord == '' ? '{}' : cacheRecord;
    final suffixList = json.decode(cacheRecord)[songId] ?? [];
    if (!suffixList.isEmpty) {
      final escapedFileName = _currentPlayingSong['name'].replaceAll('/', '|');
      final songFilePath =
          '${_appDocDir.path}/$escapedFileName.${suffixList[0]}';
      final songFile = new File(songFilePath);
      final isFileExsits = await songFile.exists();
      if (isFileExsits) {
        player.play(songFilePath, isLocal: true);
        return;
      }
    }

    final bitRate = 320000;
    Response songUrlResponse =
        await dio.get('/song/url?id=$songId&br=$bitRate');
    _currentPlayingSongUrl = songUrlResponse.data;
    final url = songUrlResponse.data['data'][0]['url'];
    _songUrl = url;
    if (url == null) {
      this.next();
      return;
    }
    await player.play(url);
    _cacheCurrentSong(url);
    notifyListeners();
  }

  Future<Null> _cacheCurrentSong(String url) async {
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
    playerState = AudioPlayerState.PAUSED;
    notifyListeners();
  }

  Future<Null> resume() async {
    await player.play(_songUrl);
    playerState = AudioPlayerState.PLAYING;
    notifyListeners();
  }

  previous() {
    final currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    final previousSongIndex = currentSongIndex == 0
        ? _playlist['playlist']['tracks'].length - 1
        : currentSongIndex - 1;
    _currentPlayingSong = _playlist['playlist']['tracks'][previousSongIndex];
    play(_playlist['playlist']['tracks'][previousSongIndex]['id'].toString());
  }

  next() {
    final currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    final nextSongIndex =
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
