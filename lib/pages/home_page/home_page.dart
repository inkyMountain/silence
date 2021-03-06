import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/store/play_center.dart';
import 'package:silence/widgets/bottomStateBar.dart';
import './profile_drawer.dart';
import './tab_mine.dart';
import './tab_find.dart';

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List tabs = ['我的', '发现'];

  @override
  void initState() {
    super.initState();
    init();
  }

  init() {
    Provider.of<PlayCenter>(context, listen: false).play();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: DefaultTabController(
            length: tabs.length,
            child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  elevation: 0,
                  centerTitle: true,
                  title: Container(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: buildTabBar()),
                  // leading: Builder(
                  //     builder: (BuildContext context) => IconButton(
                  //         icon: Icon(Icons.menu),
                  //         onPressed: () => Scaffold.of(context).openDrawer())),
                  // actions: <Widget>[
                  //   IconButton(
                  //       icon: Icon(Icons.search),
                  //       onPressed: () =>
                  //           Navigator.pushNamed(context, '/search'))
                  // ]
                ),
                // drawer: ProfileDrawer(),
                body: Stack(children: <Widget>[
                  Column(children: <Widget>[
                    Expanded(
                      child: TabBarView(children: [TabMine(), TabFind()]),
                    ),
                    Container(child: BottomStateBar())
                  ])
                ]))));
  }

  Future<bool> _onWillPop() async {
    final playCenter = Provider.of<PlayCenter>(context, listen: false);
    await playCenter.stop();
    await playCenter.release();
    return true;
  }

  List<Widget> buildTabs() => tabs
      .asMap()
      .map((index, tabTitle) {
        return MapEntry(index, Tab(text: tabTitle));
      })
      .values
      .toList();

  TabBar buildTabBar() => TabBar(
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        indicator: BoxDecoration(),
        unselectedLabelColor: Colors.grey,
        labelColor: Colors.black,
        tabs: buildTabs(),
      );
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  HomePageState createState() => HomePageState();
}
