import 'dart:convert';
import 'dart:io';

// import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayer/audioplayer.dart';
// import 'package:audioplayer/audioplayer.dart' as OriginalAudioPlayer;
import 'package:dio/dio.dart' as DioPrefix;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:silence/tools/audio_player.dart';
import 'package:silence/tools/http_service/http_service.dart';

class PlayCenter with ChangeNotifier {
  AudioPlayer player;
  Duration duration;
  Duration position;
  AudioPlayerState playerState;
  DioPrefix.Dio _dio;
  bool _hasInitialized = false;

  Map<dynamic, dynamic> _currentPlayingSong;
  Map<dynamic, dynamic> _currentPlayingSongUrl;
  Map<dynamic, dynamic> _playlist;
  Directory _appDocDir;

  get currenctPlayingSong => _currentPlayingSong;
  get playlist => _playlist;

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
    player = AudioPlayer();
    // await player.setReleaseMode(ReleaseMode.STOP);
    addPlayerListeners();
    _appDocDir = await getExternalStorageDirectory();
  }

  void addPlayerListeners() {
    // player.onDurationChanged.listen((Duration duration) {
    //   // print('Max duration: $duration');
    //   this.duration = duration;
    //   notifyListeners();
    // });
    player.onAudioPositionChanged.listen((Duration position) {
      this.position = position;
      notifyListeners();
    });
    player.onPlayerStateChanged.listen((AudioPlayerState state) {
      playerState = state;
      notifyListeners();
    });
    // player.onPlayerCompletion.listen((event) {
    //   next();
    //   notifyListeners();
    // });
    // player.onPlayerError.listen((error) {
    //   playerState = AudioPlayerState.STOPPED;
    //   duration = Duration(seconds: 0);
    //   position = Duration(seconds: 0);
    //   next();
    //   notifyListeners();
    // });
  }

  Future<Null> play(String songId) async {
    if (!_hasInitialized) await initPlayer();
    await player.stop();
    _dio = await getDioInstance();
    playerState = AudioPlayerState.PLAYING;
    final cacheRecordFile = new File('${_appDocDir.path}/cache_record.json');
    if (!await cacheRecordFile.exists()) {
      await cacheRecordFile.create();
    }
    dynamic cacheRecord = await cacheRecordFile.readAsString();
    cacheRecord = cacheRecord == '' ? '{}' : cacheRecord;
    final suffixList = json.decode(cacheRecord)[songId] ?? [];
    if (!suffixList.isEmpty) {
      player.play('${_appDocDir.path}/$songId.${suffixList[0]}', isLocal: true);
      return;
    }
    DioPrefix.Response songUrlResponse = await dio.get('/song/url?id=$songId');
    _currentPlayingSongUrl = songUrlResponse.data;
    final url = songUrlResponse.data['data'][0]['url'];
    await player.play(url);
    _cacheCurrentSong(url);
  }

  Future<Null> _cacheCurrentSong(String url) async {
    final songBytes = await readBytes(url);
    final songId = _currentPlayingSongUrl['data'][0]['id'];
    final songSuffix = _currentPlayingSongUrl['data'][0]['type'];
    final songFile = new File('${_appDocDir.path}/$songId.$songSuffix');
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
    // await player.resume();
    playerState = AudioPlayerState.PLAYING;
    notifyListeners();
  }

  previous() {
    final currentSongIndex = getCurrentSongIndex();
    final previousSongIndex = currentSongIndex == 0
        ? _playlist['playlist']['tracks'].length - 1
        : currentSongIndex - 1;
    _currentPlayingSong = _playlist['playlist']['tracks'][previousSongIndex];
    play(_playlist['playlist']['tracks'][previousSongIndex]['id'].toString());
  }

  next() {
    final currentSongIndex = getCurrentSongIndex();
    final nextSongIndex =
        currentSongIndex == _playlist['playlist']['tracks'].length - 1
            ? 0
            : currentSongIndex + 1;
    _currentPlayingSong = _playlist['playlist']['tracks'][nextSongIndex];
    play(_playlist['playlist']['tracks'][nextSongIndex]['id'].toString());
  }

  int getCurrentSongIndex() {
    int currentSongIndex;
    Map<dynamic, dynamic> tracksMap = _playlist['playlist']['tracks'].asMap();
    tracksMap.map((index, song) {
      if (song == _currentPlayingSong) {
        currentSongIndex = index;
      }
      return MapEntry(index, song);
    });
    return currentSongIndex;
  }
}
