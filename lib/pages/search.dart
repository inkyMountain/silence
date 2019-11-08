import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/store.dart';

class SearchState extends State<Search> {
  String bodyContent = 'Default Text';
  final searchFormKey = GlobalKey();
  final searchTextController = TextEditingController();

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // searchTextController.addListener(() {
    //   print('${searchTextController.text}');
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<Store>(builder: (context, userInfo, child) {
        return Stack(
          children: <Widget>[
            AppBar(
                elevation: 0,
                title: TextField(
                  key: searchFormKey,
                  controller: searchTextController,
                  autofocus: true,
                )),
          ],
        );
      }),
    );
  }
}

class Search extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SearchState();
}
