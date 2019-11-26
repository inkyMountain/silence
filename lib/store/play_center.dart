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

typedef PositionListener(Duration duration);

class PlayCenter with ChangeNotifier {
  AudioPlayer player;
  Duration duration;
  Duration position;
  bool _hasInitialized = false;

  Map<dynamic, dynamic> _currentPlayingSong;
  Map<dynamic, dynamic> _currentPlayingSongUrl;
  Dio _dio;
  SharedPreferences _preferences;
  String _songUrl;
  bool _isLocal = false;
  int _currentSongIndex;
  Map<dynamic, dynamic> _lyricsData;
  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  Map<dynamic, dynamic> _playlist;
  List<PositionListener> _positionListeners = [];
  Directory _appDocDir;
  Map<String, List> _computedLyrics;
  bool _hasLyric;
  bool _hasLyricTranslation;

  get currenctPlayingSong => _currentPlayingSong;
  get playlist => _playlist;
  get currentSongIndex => _currentSongIndex;
  get currentSongLyric => _lyricsData;
  get playerState => player == null ? AudioPlayerState.STOPPED : player.state;
  get lyrics => {
        'exist': _hasLyric,
        'hasTranslation': _hasLyricTranslation,
        'computed': _computedLyrics
      };

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
    _dio = _dio ?? await getDioInstance();
    _currentSongIndex = getSongIndex(_currentPlayingSong['id'].toString());
    player = AudioPlayer();
    _addPlayerListeners();
    _appDocDir = await getExternalStorageDirectory();
  }

  initPersistedPlayingData() async {
    _preferences = await SharedPreferences.getInstance();
    final playlistString = _preferences.getString('playlist');
    _playlist = playlistString == null ? null : json.decode(playlistString);
    final currentPlayingSongString =
        _preferences.getString('currentPlayingSong');
    _currentPlayingSong = currentPlayingSongString == null
        ? null
        : json.decode(currentPlayingSongString);
  }

  void _addPlayerListeners() {
    player.onAudioPositionChanged.listen((Duration position) {
      this.position = position;
      _positionListeners.forEach((listener) {
        listener(position);
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

  void addPositionListener(PositionListener listener) {
    _positionListeners.add(listener);
  }

  /// 播放优先级: 缓存 > 在线
  /// 外界调用play方法前，会提前设置setCurrentPlayingSong & setPlaylist。
  Future<Null> play([String songId]) async {
    if (_currentPlayingSong == null && _playlist == null)
      await initPersistedPlayingData();
    if (_currentPlayingSong == null && _playlist == null) return;
    if (!_hasInitialized) await initPlayer();
    await player.stop();
    final suffixList =
        await getSuffixList(songId ?? _currentPlayingSong['id'].toString());
    final hasSongBeenCached = suffixList.length > 0;
    hasSongBeenCached
        ? await handleLocalSong(suffixList)
        : await handleOnlineSong(
            songId ?? _currentPlayingSong['id'].toString());
    handleLyrics();
    persistPlayingData();
  }

  persistPlayingData() async {
    _preferences.setString('playlist', json.encode(_playlist));
    _preferences.setString(
        'currentPlayingSong', json.encode(_currentPlayingSong));
  }

  Future handleLocalSong(List suffixList) async {
    final escapedFileName = _currentPlayingSong['name'].replaceAll('/', '|');
    _songUrl = '${_appDocDir.path}/$escapedFileName.${suffixList[0]}';
    final songFile = File(_songUrl);
    final isFileExsits = await songFile.exists();
    if (isFileExsits) {
      _isLocal = true;
      player.play(_songUrl, isLocal: true);
    }
  }

  void handleLyrics() async {
    final _lyricsData = await getLyrics();
    _hasLyric = _lyricsData['nolyric'] == null && _lyricsData['lrc'] != null;
    String originalLyrics = _hasLyric ? _lyricsData['lrc']['lyric'] : '';
    String translatedLyrics = _hasLyric ? _lyricsData['tlyric']['lyric'] : '';
    _hasLyric = RegExp(r'\d+:\d+').hasMatch(originalLyrics);
    _hasLyricTranslation = translatedLyrics != '' && translatedLyrics != null;
    final defaultOriginal = [
      {
        'duration': Duration(seconds: 0),
        'lyric': 'Sometimes rhythm touch you deeper than lyrics.'
      }
    ];
    List<Map> originalList = toListSyntax(originalLyrics);
    List<Map> translationList =
        translatedLyrics == null ? [] : toListSyntax(translatedLyrics);
    translationList = originalList.map((original) {
      String target;
      translationList.forEach((translation) {
        if (translation['duration'] == original['duration']) {
          target = translation['lyric'];
        }
      });
      return {'duration': original['duration'], 'lyric': target ?? ''};
    }).toList();
    _computedLyrics = {
      'original': _hasLyric ? originalList : defaultOriginal,
      'translation': translationList,
    };
  }

  List<Map<String, dynamic>> toListSyntax(String lyrics) {
    return lyrics
        .split('\n')
        .where((sentence) =>
            sentence != null &&
            sentence != '' &&
            RegExp(r'\d+:\d+').hasMatch(sentence))
        .map((sentence) {
      String lyric = sentence.split(']').sublist(1).join();
      String durationString = RegExp(r'\d+:\d+').stringMatch(sentence);
      final durationFragments =
          durationString.split(':').map((value) => int.parse(value)).toList();
      durationFragments.add(int.parse(durationString.split('.').length > 1
          ? durationString.split('.')[1]
          : '0'));
      final duration = Duration(
          minutes: durationFragments[0],
          seconds: durationFragments.length > 1 ? durationFragments[1] : 0,
          milliseconds:
              durationFragments.length > 2 ? durationFragments[2] : 0);
      return {'duration': duration, 'lyric': lyric};
    }).where((map) {
      String lyric = map['lyric'];
      return lyric != '';
      // return lyric != '' && !lyric.contains(':') && !lyric.contains('：');
    }).toList();
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
    player.play(_songUrl);
    cacheCurrentSong(_songUrl);
    notifyListeners();
  }

  Future<List<dynamic>> getSuffixList(String songId) async {
    final cacheRecordFile = File('${_appDocDir.path}/cache_record.json');
    if (!await cacheRecordFile.exists()) {
      await cacheRecordFile.create();
    }
    dynamic cacheRecord = await cacheRecordFile.readAsString();
    cacheRecord = cacheRecord == '' ? '{}' : cacheRecord;
    return json.decode(cacheRecord)[songId] ?? [];
  }

  Future<Map<dynamic, dynamic>> getLyrics() async {
    final lyricUrl = '${interfaces['lyric']}?id=${_currentPlayingSong['id']}';
    final lyricResponse = await _dio.post(lyricUrl);
    return lyricResponse.data;
  }

  Future<Null> cacheCurrentSong(String url) async {
    final escapedFileName = _currentPlayingSong['name'].replaceAll('/', '|');
    final songId = _currentPlayingSongUrl['data'][0]['id'];
    final songSuffix = _currentPlayingSongUrl['data'][0]['type'];
    final songFile = File('${_appDocDir.path}/$escapedFileName.$songSuffix');
    final songBytes = await http.readBytes(url);
    await songFile.writeAsBytes(songBytes);
    final cacheRecordFile = File('${_appDocDir.path}/cache_record.json');
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

  Future<Null> stop() async {
    await player.stop();
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
