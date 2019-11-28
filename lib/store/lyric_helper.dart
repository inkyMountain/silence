import 'package:silence/tools/http_service.dart';
import 'package:dio/dio.dart';

class LyricHelper {
  String _songId;
  Map<String, List> _computedLyrics;
  Dio _dio;

  LyricHelper(String songId) : this._songId = songId;

  /// Firstly request lyrics if empty.
  /// Then return lyrics in readable syntax.
  Future getLyrics() async {
    if (_computedLyrics == null) {
      final lyricsData = await requestLyrics();
      _computedLyrics = await handleLyrics(lyricsData);
    }
    return _computedLyrics;
  }

  Future requestLyrics() async {
    _dio = _dio == null ? await getDioInstance() : _dio;
    return (await _dio.post('${interfaces['lyric']}?id=$_songId')).data;
  }

  Future<Map<String, List>> handleLyrics(Map lyricsData) async {
    bool hasLyric = lyricsData['nolyric'] == null && lyricsData['lrc'] != null;
    String originalLyrics = hasLyric ? lyricsData['lrc']['lyric'] : '';
    String translatedLyrics = hasLyric ? lyricsData['tlyric']['lyric'] : '';
    bool isLyricMeaningful = RegExp(r'\d+:\d+').hasMatch(originalLyrics);
    final placeholder = {
      'duration': Duration(seconds: 0),
      'lyric': 'Sometimes rhythm touch you deeper than lyrics.'
    };
    List<Map> originalList = toListSyntax(originalLyrics);
    List<Map> translationList =
        translatedLyrics == null ? [] : toListSyntax(translatedLyrics);
    translationList = originalList.map((original) {
      final matches = translationList
          .where(
              (translation) => translation['duration'] == original['duration'])
          .toList();
      String target = matches.length >= 1 &&
              !original['lyric'].contains(':') &&
              !original['lyric'].contains('：')
          ? matches[0]['lyric']
          : '';
      return {'duration': original['duration'], 'lyric': target};
    }).toList();
    return {
      'original': isLyricMeaningful ? originalList : [placeholder],
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
    }).toList();
  }
}
