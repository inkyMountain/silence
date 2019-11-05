import 'package:flutter/material.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _userInfo;
  Map<String, dynamic> _playlist;

  get userInfo {
    return _userInfo;
  }

  get playlist {
    return _playlist;
  }

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setPlaylist(Map<String, dynamic> playlist) {
    _playlist = _playlist;
    notifyListeners();
  }
}