import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/store.dart';

class TabMineState extends State<TabMine> with WidgetsBindingObserver {
  Map<String, bool> _songlistFoldConfig = {
    'userCreated': false,
    'liked': false,
  };

  @override
  dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Widget buildSonglists({String listType}) {
    final store = Provider.of<Store>(context);
    List songlists = listType == 'liked'
        ? store.likedSonglists as List
        : store.userCreatedSonglists as List;
    songlists = _songlistFoldConfig[listType] ? [] : songlists;
    return ListView.builder(
        padding: EdgeInsets.all(0),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: songlists.length,
        itemBuilder: (BuildContext context, int index) => ListTile(
            dense: true,
            title: Text(songlists[index]['name'] ?? '',
                style: TextStyle(fontSize: 14)),

            // contentPadding: EdgeInsets.symmetric(vertical: 5),
            /// 歌单封面
            // leading: ClipRRect(
            //   borderRadius: BorderRadius.circular(5),
            //   child: Image.network(songlists[index]['coverImgUrl'],
            //       width: 45, height: 45),
            // ),
            onTap: () => RoutesCenter.router.navigateTo(context,
                '/songlist?id=${songlists[index]['id']}&isUserPlaylist=true')),
        shrinkWrap: true);
  }

  Widget buildListHeader(Widget contentList,
      {String listTitle, Function onTapHeader, bool isFolded = false}) {
    return Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
          FlatButton(
              onPressed: onTapHeader,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.only(top: 0, bottom: 0),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: <
                      Widget>[
                Expanded(
                    child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  decoration: BoxDecoration(
                      color: isFolded ? Color(0xffe0dfdf) : Color(0xfff9f9f9),
                      border: Border(
                          left: isFolded
                              ? BorderSide(color: Color(0xffababab), width: 5)
                              : BorderSide(
                                  color: Color(0x00ababab), width: 5))),
                  child: Text(listTitle ?? '列表标题',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ))
              ])),
          Container(
              child: contentList, padding: EdgeInsets.symmetric(horizontal: 20))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    Widget userCreateds = buildSonglists(listType: 'userCreated');
    Widget likeds = buildSonglists(listType: 'liked');

    return ListView(children: <Widget>[
      Column(children: <Widget>[
        buildListHeader(userCreateds,
            listTitle: '我创建的歌单',
            isFolded: _songlistFoldConfig['userCreated'], onTapHeader: () {
          _songlistFoldConfig['userCreated'] =
              !_songlistFoldConfig['userCreated'];
          setState(() {});
        }),
        buildListHeader(likeds,
            listTitle: '我的收藏',
            isFolded: _songlistFoldConfig['liked'], onTapHeader: () {
          _songlistFoldConfig['liked'] = !_songlistFoldConfig['liked'];
          setState(() {});
        })
      ])
    ], shrinkWrap: true);
  }
}

class TabMine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabMineState();
}
