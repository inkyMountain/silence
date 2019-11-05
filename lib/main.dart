import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluro/fluro.dart';

import './router/routes.dart';
import './store/user_info.dart';

void main() {
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
  //   statusBarColor: Color(0x00000000), //or set color with: Color(0xFF0000FF)
  // ));
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(builder: (context) => UserInfo()),
    ],
    child: App(),
  ));
}

class App extends StatefulWidget {
  App() {
    final router = Router();
    RoutesCenter.configureRoutes(router);
    RoutesCenter.router = router;
  }

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Colors.white,
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          accentColor: Colors.blue[300]),
      // home: Launch(),
      onGenerateRoute: RoutesCenter.router.generator,
    );
  }
}
