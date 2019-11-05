import 'package:fluro/fluro.dart';
import './route_handlers.dart';

class RoutesCenter {
  static Router router;
  // 支持二级路由，比如 /player/playing_list 只是这里还用不到。

  static void configureRoutes(Router router) {
    router.notFoundHandler = notFoundHandler;
    // router.define('/', handler: launchRouteHandler);
    // router.define('/', handler: loginRouteHandler);
    router.define('/', handler: homeRouteHandler);
    router.define('/launch', handler: launchRouteHandler);
    router.define('/login', handler: loginRouteHandler);
    router.define('/home', handler: homeRouteHandler);
    router.define('/player', handler: playerRouteHandler);
    router.define('/songlist', handler: songlistRouteHandler);
    router.define('/search', handler: searchRouteHandler);
  }
}
