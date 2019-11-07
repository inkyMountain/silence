import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence/store/store.dart';
import '../../tools/http_service/http_service.dart';

class TabMineState extends State<TabMine> with WidgetsBindingObserver {
  int _uid;
  List<dynamic> _playlist;
  Map<String, bool> _songlistFoldConfig = {
    'userSonglist': false,
    'likedSonglist': false,
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  dispose() {
    super.dispose();
  }

  Future<Null> _initData() async {
    await _initUidFromPersist();
    final playlistResult = await _getPlaylist();
    List<dynamic> playlist = playlistResult.data['playlist'];
    setState(() {
      _playlist = playlist;
    });
  }

  Future _initUidFromPersist() async {
    final preferences = await SharedPreferences.getInstance();
    _uid = preferences.getInt("uid");
  }

  Future _getPlaylist() async {
    var dio = await getDioInstance();
    var result = await dio.post('/user/playlist?uid=$_uid');
    return result;
  }

  List<dynamic> _computeSonglistsData({String listType}) {
    /**
     * listType == 'liked'  用户收藏歌单
     * listType == 'user'   用户自创建歌单
     */
    if (_playlist == null) {
      final fallbackList = List();
      fallbackList.add(Map());
      return fallbackList;
    }
    return _playlist.where((song) {
      switch (listType) {
        case 'liked':
          return !_songlistFoldConfig['likedSonglist'] &&
              song['creator']['userId'] != _uid;
          break;
        case 'user':
          return !_songlistFoldConfig['userSonglist'] &&
              song['creator']['userId'] == _uid;
          break;
      }
      return false;
    }).toList();
  }

  // void _printWrapped(String text) {
  //   final pattern = new RegExp('.{1,800}');
  //   pattern.allMatches(text).forEach((match) => print(match.group(0)));
  // }

  @override
  Widget build(BuildContext context) {
    Widget userSonglists = buildSonglists(listType: 'liked');
    Widget likedSonglists = buildSonglists(listType: 'user');
    if (_computeSonglistsData(listType: 'user').length == 1 &&
        _computeSonglistsData(listType: 'liked').length == 1) {
      return Center(child: Text(''));
    }

    return ListView(
      children: <Widget>[
        Column(
          children: <Widget>[
            buildListHeader(likedSonglists,
                listTitle: '我创建的歌单',
                isFolded: _songlistFoldConfig['userSonglist'], onTapHeader: () {
              _songlistFoldConfig['userSonglist'] =
                  !_songlistFoldConfig['userSonglist'];
              setState(() {});
            }),
            buildListHeader(userSonglists,
                listTitle: '我的收藏',
                isFolded: _songlistFoldConfig['likedSonglist'],
                onTapHeader: () {
              _songlistFoldConfig['likedSonglist'] =
                  !_songlistFoldConfig['likedSonglist'];
              setState(() {});
            }),
          ],
        )
      ],
      shrinkWrap: true,
    );
  }

  Widget buildSonglists({String listType}) {
    final computeSonglistsData = _computeSonglistsData(listType: listType);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: computeSonglistsData == null ? 0 : computeSonglistsData.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(
            computeSonglistsData[index]['name'] ?? '',
            style: TextStyle(fontSize: 15),
          ),
          onTap: () {
            RoutesCenter.router.navigateTo(
                context, '/songlist?id=${computeSonglistsData[index]['id']}');
          },
        );
      },
      shrinkWrap: true,
    );
  }

  Widget buildListHeader(Widget contentList,
      {String listTitle, Function onTapHeader, bool isFolded = false}) {
    final blackBorderSide = BorderSide(color: Color(0xffababab), width: 5);
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FlatButton(
              onPressed: onTapHeader,
              padding: EdgeInsets.all(0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color:
                              isFolded ? Color(0xffe0dfdf) : Color(0xfff5f5f5),
                          border:
                              isFolded ? Border(left: blackBorderSide) : null),
                      child: Text(listTitle ?? '列表标题',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      padding: EdgeInsets.only(top: 15, left: 20, bottom: 15),
                    ),
                  )
                ],
              )),
          contentList
        ],
      ),
    );
  }
}

class TabMine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabMineState();
}
