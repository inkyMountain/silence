import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

Dio dio;
Future<Dio> getDioInstance() async {
  if (dio == null) {
    dio = Dio();
  }
  // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
  //     (HttpClient client) {
  //   client.findProxy = (uri) {
  //     return "PROXY 172.31.11.117:8888";
  //   };
  //   client.badCertificateCallback =
  //       (X509Certificate cert, String host, int port) => true;
  // };
  dio.interceptors.add(LogInterceptor(responseBody: true));
  dio.options.baseUrl = "http://118.25.185.172:8000";
  Directory appDocDir = await getApplicationDocumentsDirectory();
  var cookieJar = PersistCookieJar(dir: appDocDir.path);
  dio.interceptors.add(CookieManager(cookieJar));
  return dio;
  // print(cookieJar.loadForRequest(Uri.parse("https://baidu.com/")));
}
