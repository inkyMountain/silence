import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:silence/tools/http_service/http_service.dart';
import 'package:silence/widgets/bottomStateBar.dart';
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

  List<Widget> buildTabs() {
    return tabs
        .asMap()
        .map((index, tabTitle) {
          return MapEntry(index, Tab(text: tabTitle));
        })
        .values
        .toList();
  }

  TabBar buildTabBar() {
    return TabBar(
      labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle:
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      indicator: BoxDecoration(),
      unselectedLabelColor: Colors.grey,
      labelColor: Colors.black,
      controller: _tabController,
      tabs: buildTabs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Container(
            child: buildTabBar(),
            // padding: EdgeInsets.symmetric(horizontal: 15),
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
        body: Stack(
          children: <Widget>[
            TabBarView(
              controller: _tabController,
              children: [
                TabMine(),
                TabFind(),
                TabMore(),
              ],
            ),
            Positioned(
              child: buildBottomStateBar(context),
              bottom: 0,
              left: 0,
              right: 0,
            )
          ],
        ),
        drawer: ProfileDrawer(),
        // persistentFooterButtons: buildBottomStateBar(context),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  HomePageState createState() => HomePageState();
}
