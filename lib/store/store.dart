import 'package:flutter/material.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _songlists;
  Map<String, dynamic> _userInfo;
  Map<String, Map> _recommends = {};

  get songlists => _songlists;
  get userInfo => _userInfo;
  get recommendPlaylists => _recommends['playlists'];
  get recommendSongs => _recommends['songs'];

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setSonglists(Map<String, dynamic> songlists) {
    _songlists = songlists;
    notifyListeners();
  }

  void setRecommends(
      {Map<String, dynamic> playlists, Map<String, dynamic> songs}) {
    _recommends['playlists'] = playlists ?? _recommends['playlists'];
    _recommends['songs'] = songs ?? _recommends['songs'];
    notifyListeners();
  }
}
