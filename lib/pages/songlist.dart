import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/play_center.dart';
import 'package:silence/tools/http_service.dart';
import 'package:silence/widgets/bottomStateBar.dart';

class SonglistState extends State<Songlist> {
  SonglistState({this.id});

  String id;
  Map<String, dynamic> _playlist;
  PlayCenter playCenter;

  @override
  void initState() {
    super.initState();
    initData();
    playCenter = Provider.of<PlayCenter>(context, listen: false);
  }

  initData() async {
    Dio dio = await getDioInstance();
    Response response = await dio.post('${interfaces['playlistDetail']}?id=$id');
    setState(() {
      _playlist = response.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_playlist == null) {
      return Scaffold(
          appBar: AppBar(title: Text('')),
          body: Center(child: Text('Loading')));
    }

    final scaffold = Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          title: Text(_playlist['playlist']['name']),
        ),
        body: Stack(children: <Widget>[
          Column(children: <Widget>[
            Expanded(child: buildPlaylist()),
            Container(child: buildBottomStateBar(context))
          ])
        ]));
    return scaffold;
  }

  Widget buildPlaylist() {
    if (_playlist.isEmpty) {
      return Text('');
    }
    final listview = ListView.builder(
        itemCount:
            _playlist == null ? 0 : _playlist['playlist']['tracks'].length,
        itemBuilder: (BuildContext context, int index) => ListTile(
            dense: true,
            title: Text(_playlist['playlist']['tracks'][index]['name'] ?? ''),
            onTap: () {
              playCenter.setPlaylist(_playlist);
              playCenter.setCurrenctPlayingSong(
                  _playlist['playlist']['tracks'][index]);
              final songId = _playlist['playlist']['tracks'][index]['id'];
              RoutesCenter.router.navigateTo(context, '/player?songId=$songId');
            }));
    return listview;
  }
}

class Songlist extends StatefulWidget {
  final String id;
  Songlist({this.id});

  @override
  State<StatefulWidget> createState() => SonglistState(id: id);
}
