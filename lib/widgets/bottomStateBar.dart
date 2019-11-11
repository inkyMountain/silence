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
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      FlatButton(
          padding: EdgeInsets.all(0),
          child: Text('跳转到播放页'),
          onPressed: () {
            RoutesCenter.router.navigateTo(context, '/player');
          })
    ],
  );
}
