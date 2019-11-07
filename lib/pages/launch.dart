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
    if (isLogin['code'] == 200) {
      await preferences.setInt('uid', isLogin['profile']['userId']);
      RoutesCenter.router.navigateTo(context, '/home', replace: true);
    } else {
      await preferences.remove('uid');
      RoutesCenter.router.navigateTo(context, '/login', replace: true);
    }
  }

  Future<dynamic> getLoginStatus() async {
    var dio = await getDioInstance();
    var result = await dio.post('/login/status').catchError((error) {
      print(error.response);
    });
    return result.data;
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
