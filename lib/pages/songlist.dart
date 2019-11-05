import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:layout/http_service/http_service.dart';
import 'package:layout/router/routes.dart';

class SonglistState extends State<Songlist> {
  dynamic id;
  Map<String, dynamic> _playlist = {};

  SonglistState({this.id});

  @override
  void initState() {
    super.initState();
    initData();
  }

  initData() async {
    Dio dio = await getDioInstance();
    Response response = await dio.post('/playlist/detail?id=$id');
    setState(() {
      _playlist = response.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('歌单'),
      ),
      body: Column(
        children: <Widget>[
          _playlist.isEmpty
              ? Text('')
              : Text('歌单名称：${_playlist['playlist']['name']}'),
          Expanded(
            child: buildPlaylist(),
          )
        ],
      ),
    );
  }

  Widget buildPlaylist() {
    final playlist = _playlist;
    if (playlist.isEmpty) {
      return Text('');
    }
    return ListView.builder(
      itemCount: playlist == null ? 0 : playlist['playlist']['tracks'].length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Text('leading'),
          title: Text(playlist['playlist']['tracks'][index]['name'] ?? ''),
          onTap: () {
            print('${playlist['playlist']['trackIds'][index]['id']}');
            final songId = playlist['playlist']['trackIds'][index]['id'];
            RoutesCenter.router.navigateTo(context, '/player?songId=$songId');
          },
        );
      },
      // shrinkWrap: true,
    );
  }
}

class Songlist extends StatefulWidget {
  final dynamic id;
  Songlist({this.id});

  @override
  State<StatefulWidget> createState() => SonglistState(id: id);
}
