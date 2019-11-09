import 'package:flutter/material.dart';

class Store with ChangeNotifier {
  Map<String, dynamic> _songlists;
  Map<String, dynamic> _userInfo;

  get songlists => _songlists;

  get userInfo => _userInfo;

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }

  void setSonglists(Map<String, dynamic> songlists) {
    _songlists = songlists;
    notifyListeners();
  }
}
