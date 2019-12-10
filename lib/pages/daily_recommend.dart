import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/play_center.dart';
import 'package:silence/store/store.dart';

class DailyRecommend extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DailyRecommendState();
}

class DailyRecommendState extends State<DailyRecommend> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<Store>(context);
    final playCenter = Provider.of<PlayCenter>(context);
    List dailyRecommends = store.recommendSongs['recommend']
      ..forEach((song) {
        song['al'] = song['album'];
      });

    return Scaffold(
        body: Stack(children: <Widget>[
      Container(
          child: ListView.builder(
            itemBuilder: (context, index) => ListTile(
                title: Text(
                  dailyRecommends[index]['name'],
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                onTap: () {
                  playCenter.setPlaylist({
                    'playlist': {'tracks': dailyRecommends}
                  });
                  playCenter.setCurrentPlayingSong(dailyRecommends[index]);
                  final songId = dailyRecommends[index]['id'];
                  RoutesCenter.router.navigateTo(
                      context, '/player?songId=$songId',
                      transition: TransitionType.fadeIn);
                }),
            itemCount: dailyRecommends.length,
          ),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff2193b0), Color(0xff6dd5ed)])))
    ]));
  }
}
