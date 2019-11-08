import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silence/store/store.dart';
import '../../tools/http_service/http_service.dart';

class TabMineState extends State<TabMine> with WidgetsBindingObserver {
  List<dynamic> _songlists;
  Map<String, bool> _songlistFoldConfig = {
    'userSonglist': false,
    'likedSonglist': false,
  };

  int _uid;

  @override
  dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<Null> _initData() async {
    await _initUidFromPersist();
    final songlistsInStore = Provider.of<Store>(context).songlists;
    List<dynamic> songlists;
    // 优先使用store中的数据
    if (songlistsInStore != null) {
      songlists = songlistsInStore['playlist'];
    } else {
      final songlistsResponse = await _getSonglists();
      songlists = songlistsResponse.data['playlist'];
    }
    setState(() {
      _songlists = songlists;
    });
  }

  Future<void> _initUidFromPersist() async {
    final preferences = await SharedPreferences.getInstance();
    _uid = preferences.getInt("uid");
  }

  Future<Response> _getSonglists() async {
    Dio dio = await getDioInstance();
    Response songlists = await dio.post('/user/playlist?uid=$_uid');
    Provider.of<Store>(context).setSonglists(songlists.data);
    return songlists;
  }

  List<dynamic> _computeSonglistsData({String listType}) {
    /**
     * listType == 'liked'  用户收藏歌单
     * listType == 'user'   用户自创建歌单
     */
    if (_songlists == null) {
      final fallbackList = List();
      fallbackList.add(Map());
      return fallbackList;
    }
    return _songlists.where((song) {
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

  Widget buildSonglists({String listType}) {
    final computeSonglistsData = _computeSonglistsData(listType: listType);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: computeSonglistsData == null ? 0 : computeSonglistsData.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          dense: true,
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
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FlatButton(
              onPressed: onTapHeader,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.only(top: 0, bottom: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                      decoration: BoxDecoration(
                          color:
                              isFolded ? Color(0xffe0dfdf) : Color(0xfff5f5f5),
                          border: Border(
                              left: isFolded
                                  ? BorderSide(
                                      color: Color(0xffababab), width: 5)
                                  : BorderSide(
                                      color: Color(0x00ababab), width: 5))),
                      child: Text(listTitle ?? '列表标题',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              )),
          Container(
            child: contentList,
            padding: EdgeInsets.symmetric(horizontal: 20),
          )
        ],
      ),
    );
  }

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
}

class TabMine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabMineState();
}
