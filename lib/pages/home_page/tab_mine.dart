import 'package:flutter/material.dart';
import 'package:silence/router/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tools/http_service/http_service.dart';

class TabMineState extends State<TabMine> with WidgetsBindingObserver {
  int _uid;
  List<dynamic> _playlist;

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
    print('获取uid');
    print(_uid);
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
    return _playlist.where((value) {
      return listType == 'liked'
          ? value['creator']['userId'] != _uid
          : value['creator']['userId'] == _uid;
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
            buildListHeader(likedSonglists, listTitle: '我创建的歌单'),
            buildListHeader(userSonglists, listTitle: '我的收藏'),
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
          // leading: Text('leading'),
          title: Text(computeSonglistsData[index]['name'] ?? ''),
          onTap: () {
            RoutesCenter.router.navigateTo(
                context, '/songlist?id=${computeSonglistsData[index]['id']}');
          },
        );
      },
      shrinkWrap: true,
    );
  }

  Widget buildListHeader(Widget list, {String listTitle}) {
    return Container(
      // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            child: Text(listTitle ?? '列表标题'),
            decoration: BoxDecoration(color: Colors.grey[50]),
            padding: EdgeInsets.only(top: 10, left: 20, bottom: 10),
          ),
          list
        ],
      ),
    );
  }
}

class TabMine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabMineState();
}
