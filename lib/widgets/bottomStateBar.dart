import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/play_center.dart';

Widget buildBottomStateBar(BuildContext context) {
  final currenctPlayingSong =
      Provider.of<PlayCenter>(context).currenctPlayingSong;
  if (currenctPlayingSong == null) {
    return Text('');
  }
  final playCenter = Provider.of<PlayCenter>(context);
  String coverUrl =
      Provider.of<PlayCenter>(context).currenctPlayingSong['al']['picUrl'];

  return Padding(
      padding: EdgeInsets.all(10),
      child: Row(children: <Widget>[
        Expanded(
            child: FlatButton(
                padding: EdgeInsets.all(0),
                child: Row(children: <Widget>[
                  ClipRRect(
                    child: Image.network(coverUrl,
                        width: 40, height: 40, fit: BoxFit.cover),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  Expanded(
                      child: Container(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                              Provider.of<PlayCenter>(context)
                                  .currenctPlayingSong['name'],
                              overflow: TextOverflow.ellipsis)))
                ]),
                onPressed: () =>
                    RoutesCenter.router.navigateTo(context, '/player'))),
        IconButton(
            icon: Icon(Provider.of<PlayCenter>(context).playerState ==
                    AudioPlayerState.PLAYING
                ? Icons.pause
                : Icons.play_arrow),
            onPressed: () => Provider.of<PlayCenter>(context).playerState ==
                    AudioPlayerState.PLAYING
                ? playCenter.pause()
                : playCenter.resume())
      ]));
}
