import 'package:flutter/material.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _currentPlayingSong;
  Map<String, dynamic> _songlists;
  Map<String, dynamic> _playlist;
  Map<String, dynamic> _userInfo;

  get currenctPlayingSong => _currentPlayingSong;

  get songlists => _songlists;

  get playlist => _playlist;

  get userInfo => _userInfo;

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setSonglists(Map<String, dynamic> songlists) {
    _songlists = songlists;
    notifyListeners();
  }

  void setPlaylist(Map<String, dynamic> playlist) {
    _playlist = playlist;
    notifyListeners();
  }

  void setCurrenctPlayingSong(Map<String, dynamic> currentPlayingSong) {
    _currentPlayingSong = currentPlayingSong;
    notifyListeners();
  }
}
