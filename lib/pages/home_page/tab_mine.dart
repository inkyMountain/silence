import 'package:flutter/material.dart';
import '../../http_service/http_service.dart';
import 'package:silence/router/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabMineState extends State<TabMine> {
  int _uid;
  List<dynamic> _playlist;

  @override
  void initState() {
    super.initState();
    // _initData();
  }

  Future _initData() async {
    await _initUidFromPersist();
    final playlistResult = await _getPlaylist();
    List<dynamic> playlist = playlistResult.data['playlist'];
    // _printWrapped(playlist.toString());
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
    // http.Response response = await http.get('$_host/user/playlist?uid=$_uid');
    // List<dynamic> playlist = json.decode(response.body)['playlist'];
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
          children: <Widget>[userSonglists, likedSonglists],
        )
      ],
    );
  }

  Widget buildSonglists({String listType}) {
    final computeSonglistsData = _computeSonglistsData(listType: listType);
    return ListView.builder(
      itemCount: computeSonglistsData == null ? 0 : computeSonglistsData.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Text('leading'),
          title: Text(computeSonglistsData[index]['name'] ?? ''),
          onTap: () {
            print(
                '歌单<${computeSonglistsData[index]['name']}>被点击, 这是一个用户自己创建的歌单。');
            RoutesCenter.router.navigateTo(
                context, '/songlist?id=${computeSonglistsData[index]['id']}');
          },
        );
      },
      shrinkWrap: true,
    );
  }
}

class TabMine extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabMineState();
}
