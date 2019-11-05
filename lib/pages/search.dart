import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/user_info.dart';

class SearchState extends State<Search> {
  final controller = TextEditingController();
  final searchFormKey = GlobalKey();
  var bodyContent = 'Default Text';

  @override
  void initState() {
    super.initState();
    // controller.addListener(() {
    //   print('${controller.text}');
    // });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: searchFormKey,
          controller: controller,
          autofocus: true,
        ),
      ),
      body: Consumer<UserInfo>(builder: (context, userInfo, child) {
        return Text("用户名: $userInfo");
      }),
    );
  }
}

class Search extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SearchState();
}
