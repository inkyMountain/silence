import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/play_center.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/http_service/http_service.dart';
import 'package:silence/widgets/bottomStateBar.dart';

class SonglistState extends State<Songlist> {
  dynamic id;
  Map<String, dynamic> _playlist;
  PlayCenter playCenter;

  SonglistState({this.id});

  @override
  void initState() {
    super.initState();
    initData();
    playCenter = Provider.of<PlayCenter>(context, listen: false);
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
    if (_playlist == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(''),
        ),
        body: Center(
          child: Text('Loading'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: Text(_playlist['playlist']['name']),
      ),
      body: Stack(
        children: <Widget>[
          Column(children: <Widget>[
            Expanded(
              child: buildPlaylist(),
            )
          ]),
          Positioned(
            child: buildBottomStateBar(context),
            bottom: 0,
            left: 0,
            right: 0,
          )
        ],
      ),
      // persistentFooterButtons: buildBottomStateBar(context),
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
          dense: true,
          leading: Text('leading'),
          title: Text(playlist['playlist']['tracks'][index]['name'] ?? ''),
          onTap: () {
            playCenter.setPlaylist(playlist);
            playCenter
                .setCurrenctPlayingSong(playlist['playlist']['tracks'][index]);
            final songId = playlist['playlist']['tracks'][index]['id'];
            RoutesCenter.router.navigateTo(context, '/player?songId=$songId');
          },
        );
      },
    );
  }
}

class Songlist extends StatefulWidget {
  final dynamic id;
  Songlist({this.id});

  @override
  State<StatefulWidget> createState() => SonglistState(id: id);
}
