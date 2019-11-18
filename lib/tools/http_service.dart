import 'dart:io';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

Dio dio;
Future<Dio> getDioInstance() async {
  dio = dio ?? Dio();
  // setProxy(dio, '172.31.11.117:8888');
  dio.interceptors.add(LogInterceptor(responseBody: true));
  dio.options.baseUrl = "http://118.25.185.172:8000";
  // dio.options.baseUrl = "http://192.168.124.5:8000";
  Directory appDocDir = await getApplicationDocumentsDirectory();
  CookieJar cookieJar = PersistCookieJar(dir: appDocDir.path);
  dio.interceptors.add(CookieManager(cookieJar));
  return dio;
}

setProxy(Dio dio, String proxyUrl) {
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.findProxy = (uri) => "PROXY $proxyUrl";
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  };
}

Map<String, String> interfaces = {
  'loginStatus': '/login/status',
  'userPlaylist': '/user/playlist',
  'phoneLogin': '/login/cellphone',
  'playlistDetail': '/playlist/detail',
  'lyric': '/lyric',
};
