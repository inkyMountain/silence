import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/store.dart';
import 'package:silence/tools/http_service.dart';

class TabFindState extends State<TabFind> {
  Dio _dio;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    _dio = await getDioInstance();
    final store = Provider.of<Store>(context);
    bool needRequest = store.recommendPlaylists == null ||
        store.recommendSongs == null ||
        (store.recommendPlaylists as Map).length == 0 ||
        (store.recommendSongs as Map).length == 0;
    if (!needRequest) return;
    Map recommendPlaylists =
        (await _dio.post(interfaces['recommendPlaylists'])).data;
    Map recommendSongs = (await _dio.post(interfaces['recommendSongs'])).data;
    store.setRecommends(playlists: recommendPlaylists, songs: recommendSongs);
  }

  @override
  Widget build(BuildContext context) {
    Map playlists = Provider.of<Store>(context).recommendPlaylists;
    if (playlists == null) return Center(child: Text('loading'));
    return Stack(children: <Widget>[
      Column(children: <Widget>[buildRecommendPlaylists(playlists)])
    ]);
  }

  GridView buildRecommendPlaylists(Map playlists) {
    const int totalGrids = 9;
    return GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.7),
        itemCount: totalGrids,
        itemBuilder: (context, index) {
          Map playlist = playlists['recommend'][index];
          return Column(children: <Widget>[
            FlatButton(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      playlist['picUrl'],
                      fit: BoxFit.cover,
                    )),
                onPressed: () => RoutesCenter.router
                    .navigateTo(context, '/songlist?id=${playlist['id']}')),
            Container(
                child: Text(playlist['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey)))
          ]);
        });
  }
}

class TabFind extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabFindState();
}
