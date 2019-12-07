import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/play_center.dart';
import 'package:silence/tools/http_service.dart';
import 'package:silence/widgets/bottomStateBar.dart';

class SonglistState extends State<Songlist> {
  SonglistState({this.id, this.isUserPlaylist});

  String id;
  bool isUserPlaylist;
  Map<String, dynamic> _playlist;
  PlayCenter playCenter;
  bool initilized = false;

  @override
  void initState() {
    super.initState();
    playCenter = Provider.of<PlayCenter>(context, listen: false);
    init();
  }

  init() async {
    Dio dio = await getDioInstance();
    Response response =
        await dio.post('${interfaces['playlistDetail']}?id=$id');
    setState(() => _playlist = response.data);
    initilized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_playlist == null)
      return Scaffold(body: Center(child: Text('Loading')));
    final scaffold = Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: <Widget>[
          Column(children: <Widget>[
            Expanded(child: buildPlaylist()),
            Container(child: BottomStateBar())
          ]),
          Positioned(child: BackButton(), left: 15, top: 30)
        ]));
    return scaffold;
  }

  Widget buildPlaylist() {
    if (_playlist.isEmpty) return Text('');
    final cover = Image.network(_playlist['playlist']['coverImgUrl'],
        height: 250, fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      return AnimatedOpacity(
        child: Stack(children: <Widget>[
          Row(children: <Widget>[
            Flexible(
                fit: FlexFit.tight,
                child: ClipRRect(
                    child: child, borderRadius: BorderRadius.circular(10)))
          ]),
          Container(
              width: MediaQuery.of(context).size.width,
              height: 250,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment(0, -1),
                      end: Alignment(0, 1),
                      colors: <Color>[
                    const Color(0x99ffffff),
                    const Color(0x00ffffff)
                  ])))
        ]),
        opacity: frame == null ? 0 : 1,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut,
      );
    });
    final listview = ListView.builder(
        itemCount:
            _playlist == null ? 0 : _playlist['playlist']['tracks'].length,
        itemBuilder: (BuildContext context, int index) =>
            index == 0 ? cover : buildListTile(index - 1));
    return MediaQuery.removePadding(
        context: context, child: listview, removeTop: true);
  }

  Widget buildListTile(int index) {
    return ListTile(
        dense: true,
        title: Text(_playlist['playlist']['tracks'][index]['name'] ?? ''),
        onTap: () {
          playCenter.setPlaylist(_playlist);
          playCenter
              .setCurrentPlayingSong(_playlist['playlist']['tracks'][index]);
          final songId = _playlist['playlist']['tracks'][index]['id'];
          RoutesCenter.router.navigateTo(context, '/player?songId=$songId');
        });
  }
}

class Songlist extends StatefulWidget {
  final String id;
  final bool isUserPlaylist;
  Songlist({this.id, this.isUserPlaylist});

  @override
  State<StatefulWidget> createState() =>
      SonglistState(id: id, isUserPlaylist: isUserPlaylist);
}
