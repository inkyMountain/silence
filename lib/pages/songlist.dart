import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/http_service/http_service.dart';

class SonglistState extends State<Songlist> {
  dynamic id;
  Map<String, dynamic> _playlist;
  Store store;

  SonglistState({this.id});

  @override
  void initState() {
    super.initState();
    initData();
    store = Provider.of<Store>(context, listen: false);
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
        body: Center(child: Text('Loading')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: Text(_playlist['playlist']['name']),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildPlaylist(),
          ),
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
          dense: true,
          leading: Text('leading'),
          title: Text(playlist['playlist']['tracks'][index]['name'] ?? ''),
          onTap: () {
            store.setPlaylist(playlist);
            // store.setPlaylist(playlist['playlist']['tracks']);
            store.setCurrenctPlayingSong(playlist['playlist']['tracks'][index]);
            final songId = playlist['playlist']['trackIds'][index]['id'];
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
