import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import '../pages/index.dart';

Handler launchRouteHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return Launch();
});

Handler homeRouteHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return HomePage();
});

Handler loginRouteHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return Login();
});

Handler playerRouteHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return Player(songId: params['songId'] == null ? null : params['songId'][0]);
});

Handler songlistRouteHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return Songlist(
      id: params['id'][0],
      isUserPlaylist: params['isUserPlaylist'][0] == 'true');
});

Handler searchRouteHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return Search();
});

Handler notFoundHandler = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return Empty();
});
