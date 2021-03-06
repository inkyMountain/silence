import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence/tools/http_service.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _userSonglists = {};
  Map<String, dynamic> _userInfo;
  // tab_find中请求并设置
  //日推歌曲： _recommends['playlists']['recommend'].where()
  // 播放中心的playlist原先是这个结构：_playlist['playlist']['tracks']
  // 所以需要把每日推荐也包装成相同的结构，这样可以少一些改动。真坑！
  Map<String, Map> _recommends = {'playlists': {}, 'songs': {}};
  Map<String, dynamic> needUpdate = {'songlists': false};
  Map _likedSonglistDetail;
  Dio _dio;
  int _uid;

  get userSonglists => _userSonglists;
  get userInfo => _userInfo;
  get recommendPlaylists => _recommends['playlists'];
  get recommendSongs => _recommends['songs'];
  get likedSonglists {
    final filtered = _userSonglists['playlist']
        .where((playlist) => playlist['creator']['userId'] != _uid)
        .toList();
    return _userSonglists['playlist'] == null ? [] : filtered;
  }

  get userCreatedSonglists {
    final filtered = _userSonglists['playlist']
        .where((playlist) => playlist['creator']['userId'] == _uid)
        .toList();
    return _userSonglists['playlist'] == null ? [] : filtered;
  }

  bool isThisSongBeenLiked(String id) {
    List songs = _likedSonglistDetail['playlist']['tracks'];
    List filtered =
        songs.where((song) => song['id'].toString() == id).toList() ?? [];
    return filtered.length > 0;
  }

  bool isThisPlaylistBeenLiked(String id) {
    List songlists = _userSonglists['playlist'];
    List filtered = songlists
            .where((playlist) => playlist['id'].toString() == id)
            .toList() ??
        [];
    return filtered.length > 0;
  }

  void addLikedSong(Map track) {
    List songs = _likedSonglistDetail['playlist']['tracks'];
    songs.add(track);
    notifyListeners();
  }

  void removeLikedSong(String id) {
    List songs = _likedSonglistDetail['playlist']['tracks'];
    songs.removeWhere((song) => song['id'].toString() == id);
    notifyListeners();
  }

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setRecommends(
      {Map<String, dynamic> playlists, Map<String, dynamic> songs}) {
    _recommends['playlists'] = playlists ?? _recommends['playlists'];
    _recommends['songs'] = songs ?? _recommends['songs'];
    notifyListeners();
  }

  // 获取所有初始化需要的数据，比如用户歌单。
  fetchInitData() async {
    _dio = _dio ?? await getDioInstance();
    await readUid();
    await Future.wait([_fetchSonglists(), _fetchDailyRecommend()]);
  }

  Future<Null> _fetchDailyRecommend() async {
    // _dailyRecommends['recommend'].where()
    // 播放中心的playlist原先是这个结构：_playlist['playlist']['tracks']
    // 所以需要把每日推荐也包装成相同的结构，这样可以少一些改动。真坑！
    final response = await _dio.post('${interfaces['recommendSongs']}');
    _recommends['songs'] = response.data;
  }

  Future<Null> _fetchSonglists() async {
    Response songlistsResponse = await _dio.post(
        '${interfaces['userPlaylist']}',
        queryParameters: {'uid': _uid, 'timestamp': DateTime.now()});
    _userSonglists = songlistsResponse.data;
    String likedSonglistId = _userSonglists['playlist']
        .firstWhere((playlist) =>
            playlist['creator']['nickname'] == _userInfo['nickname'])['id']
        .toString();
    _likedSonglistDetail =
        (await _dio.post('${interfaces['playlistDetail']}?id=$likedSonglistId'))
            .data;
    notifyListeners();
  }

  Future<void> readUid() async {
    final preferences = await SharedPreferences.getInstance();
    _uid = preferences.getInt("uid");
  }

  Map getSpecificPlaylist(
      {@required String id, @required bool isUserPlaylist}) {
    List list = isUserPlaylist
        ? _userSonglists['playlist'] as List
        : _recommends['playlists']['recommend'] as List;
    return list.firstWhere((playlist) => playlist['id'].toString() == id,
        orElse: () => null);
  }
}
