import 'package:flutter/material.dart';

class UserInfo with ChangeNotifier {
  Map<String, dynamic> _userInfo;

  void setUserInfo(Map<String, dynamic> userInfo) {
    _userInfo = userInfo;
    notifyListeners();
  }
}