import 'package:flutter/material.dart';

class TabFind extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabFindState();
}

class TabFindState extends State<TabFind> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(icon: Icon(Icons.plus_one), onPressed: () {}),
    );
  }
}
