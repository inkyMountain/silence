import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:silence/http_service/http_service.dart';
import './profile_drawer.dart';

import './tab_mine.dart';
import './tab_find.dart';
import './tab_more.dart';

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    FlutterStatusbarManager.setColor(Colors.blue.withAlpha(0));
    FlutterStatusbarManager.setHidden(false);
    // refreshLoginStatus();
  }

  refreshLoginStatus() async {
    var dio = await getDioInstance();
    var result = dio.post('/login/refresh');
    print('登录刷新');
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: TabBar(
              tabs: [
                Tab(text: '我的'),
                Tab(text: '发现'),
                Tab(text: '更多'),
              ],
            ),
            leading: Builder(builder: (BuildContext context) {
              return IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer());
            }),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => Navigator.pushNamed(context, '/search'))
            ],
          ),
          body: TabBarView(
            children: [
              TabMine(),
              TabFind(),
              TabMore(),
            ],
          ),
          drawer: ProfileDrawer()),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  HomePageState createState() => HomePageState();
}
