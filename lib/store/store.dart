import 'package:flutter/material.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _userInfo;
  List<dynamic> _playlist;
  Map<String, dynamic> _currentPlayingSong;

  get userInfo {
    return _userInfo;
  }

  get playlist {
    return _playlist;
  }

  get currenctPlayingSong {
    return _currentPlayingSong;
  }

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setPlaylist(List<dynamic> playlist) {
    _playlist = playlist;
    notifyListeners();
  }

  void setCurrenctPlayingSong(Map<String, dynamic> currentPlayingSong) {
    _currentPlayingSong = currentPlayingSong;
    notifyListeners();
  }
}
