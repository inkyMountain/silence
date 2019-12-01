import 'package:flutter/material.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _userSonglists;
  Map<String, dynamic> _userInfo;
  Map<String, Map> _recommends = {};

  get userSonglists => _userSonglists;
  get userInfo => _userInfo;
  get recommendPlaylists => _recommends['playlists'];
  get recommendSongs => _recommends['songs'];

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setSonglists(Map<String, dynamic> songlists) {
    _userSonglists = songlists;
    notifyListeners();
  }

  void setRecommends(
      {Map<String, dynamic> playlists, Map<String, dynamic> songs}) {
    _recommends['playlists'] = playlists ?? _recommends['playlists'];
    _recommends['songs'] = songs ?? _recommends['songs'];
    notifyListeners();
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
