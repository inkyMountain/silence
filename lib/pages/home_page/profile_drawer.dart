import 'package:flutter/material.dart';

class ProfileDrawerState extends State<ProfileDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DrawerHeader(
          child: Text('Drawer Header'),
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
        ),
        ListTile(
          title: Text('设置'),
          onTap: () {},
        ),
        ListTile(
          title: Text('我的页面'),
          onTap: () {},
        ),
      ],
    ));
  }
}

class ProfileDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ProfileDrawerState();
}
