import 'package:dio/dio.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/http_service.dart';
import 'package:silence/router/routes.dart';

class LaunchState extends State<Launch> {
  int uid;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    final isLogin = await getLoginStatus();
    final preferences = await SharedPreferences.getInstance();
    if (isLogin['code'] == 200) {
      await preferences.setInt('uid', isLogin['profile']['userId']);
      RoutesCenter.router.navigateTo(context, '/home',
          replace: true, transition: TransitionType.fadeIn);
    } else {
      await preferences.remove('uid');
      RoutesCenter.router.navigateTo(context, '/login',
          replace: true, transition: TransitionType.fadeIn);
    }
  }

  Future<dynamic> getLoginStatus() async {
    Dio dio = await getDioInstance();
    var errorMessage;
    var loginStatus =
        await dio.post(interfaces['loginStatus']).catchError((error) {
      errorMessage = error.response.data;
    });
    Provider.of<Store>(context).setUserInfo(loginStatus.data['profile']);
    return loginStatus == null ? errorMessage : loginStatus.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff42a5f5),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                fit: FlexFit.tight,
                flex: 1,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'Silence',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.w400),
                      )
                    ]),
              ),
              Flexible(flex: 2, fit: FlexFit.tight, child: Text(''))
            ]));
  }
}

class Launch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LaunchState();
}
