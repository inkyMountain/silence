import 'package:flutter/material.dart';
import 'package:silence/tools/http_service/http_service.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence/router/routes.dart';

class LaunchState extends State<Launch> {
  int uid;

  @override
  void initState() {
    super.initState();
    FlutterStatusbarManager.setHidden(true);
    init();
  }

  init() async {
    final isLogin = await getLoginStatus();
    final preferences = await SharedPreferences.getInstance();
    if (isLogin) {
      await preferences.setInt('uid', 121643199);
      RoutesCenter.router.navigateTo(context, '/home');
    } else {
      final removeResult = await preferences.remove('uid');
      print('remove result:');
      print(removeResult);
      RoutesCenter.router.navigateTo(context, '/login');
    }
  }

  Future<bool> getLoginStatus() async {
    var dio = await getDioInstance();
    var result = await dio.post('/login/status').catchError((error) {
      print(error.response);
    });
    return result == null ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      color: Colors.lightBlue,
                      fontSize: 50,
                      fontWeight: FontWeight.w700),
                )
              ]),
        ),
        Flexible(
          flex: 2,
          fit: FlexFit.tight,
          child: FlatButton(
              onPressed: () {
                // RoutesCenter.router.navigateTo(
                //   context,
                //   '/home',
                //   // replace: true,
                //   transition: TransitionType.native,
                // );
              },
              child: Text('Flat Button')),
        ),
      ],
    ));
  }
}

class Launch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LaunchState();
}
