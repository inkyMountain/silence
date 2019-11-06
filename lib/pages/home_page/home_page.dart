import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:silence/tools/http_service/http_service.dart';
import './profile_drawer.dart';

import './tab_mine.dart';
import './tab_find.dart';
import './tab_more.dart';

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List tabs = ['我的', '发现', '更多'];
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    FlutterStatusbarManager.setColor(Colors.blue.withAlpha(0));
    FlutterStatusbarManager.setHidden(false);
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      _tabController.index;
    });
  }

  @override
  dispose() {
    super.dispose();
    _tabController.dispose();
  }

  refreshLoginStatus() async {
    Dio dio = await getDioInstance();
    dio.post('/login/refresh');
  }

  @override
  Widget build(BuildContext context) {
    var tabBar = TabBar(
      indicator: BoxDecoration(),
      labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      unselectedLabelStyle:
          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      unselectedLabelColor: Colors.grey,
      labelColor: Colors.black,
      controller: _tabController,
      tabs: buildTabs(),
    );

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: tabBar,
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
            controller: _tabController,
            children: [
              TabMine(),
              TabFind(),
              TabMore(),
            ],
          ),
          drawer: ProfileDrawer()),
    );
  }

  List<Widget> buildTabs() {
    return tabs
        .asMap()
        .map((index, tabTitle) {
          return MapEntry(index, Text(tabTitle));
        })
        .values
        .toList();
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  HomePageState createState() => HomePageState();
}
