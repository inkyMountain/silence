import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluro/fluro.dart';
import 'package:layout/http_service/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:layout/router/routes.dart';
import 'package:layout/store/user_info.dart';
import 'package:provider/provider.dart';

class LoginState extends State<Login> {

  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneInputKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // checkLoginStatus();
    attachListeners();
  }

  @override
  void dispose() {
    super.dispose();
    accountController.dispose();
    passwordController.dispose();
  }

  checkLoginStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final uid = preferences.getInt('uid');
    if (uid != null) {
      RoutesCenter.router.navigateTo(context, '/home');
    }
  }

  login({String phone, String password}) async {
    Dio dio = await getDioInstance();
    Response loginResult =
        await dio.post('/login/cellphone?phone=$phone&password=$password');
    print(loginResult.data.toString());
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt("uid", loginResult.data['account']['id']);
    return loginResult.data['code'] == 200
        ? {
            'account': loginResult.data['account'],
            'profile': loginResult.data['profile']
          }
        : null;
  }

  String accountValidator(value) {
    if (value.length < 11) {
      return '手机号码需要为11位';
    }
    if (!value.startsWith('1')) {
      return '手机开头需要是1';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // checkLoginStatus();

    var accountInput = Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 60),
      child: TextFormField(
          keyboardType: TextInputType.number,
          controller: accountController,
          maxLength: 11,
          validator: accountValidator,
          decoration: InputDecoration(
              suffixIcon: Icon(Icons.phone, color: Colors.blue),
              hintText: '手机号',
              errorStyle: TextStyle(color: Colors.lightBlue),
              counterText: '',
              border: InputBorder.none)),
    );

    var passwordInput = Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 60),
      child: TextFormField(
          obscureText: true,
          validator: (value) {
            return value.length <= 1 ? '你的密码应该不会这么短吧' : null;
          },
          controller: passwordController,
          decoration: InputDecoration(
              hintText: '密码',
              suffixIcon: Icon(Icons.account_box, color: Colors.blue),
              counterText: '',
              errorStyle: TextStyle(color: Colors.lightBlue),
              border: InputBorder.none)),
    );

    return Scaffold(
      body: Stack(children: <Widget>[
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Form(
                      key: phoneInputKey,
                      child: Column(
                        children: <Widget>[
                          accountInput,
                          passwordInput,
                        ],
                      ),
                    ),
                    FlatButton(
                      child: Text(
                        '登录',
                        style: TextStyle(color: Colors.black87),
                      ),
                      onPressed: () async {
                        if (phoneInputKey.currentState.validate()) {
                          final userInfo = await login(
                              phone: accountController.text,
                              password: passwordController.text);
                          if (userInfo != null) {
                            Provider.of<UserInfo>(context, listen: false)
                                .setUserInfo(userInfo);
                            RoutesCenter.router.navigateTo(context, '/home',
                                transition: TransitionType.native,
                                replace: true);
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('登录出错，请检查账号密码。',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14)),
                                  );
                                });
                          }
                        }
                      },
                    ),
                  ],
                ),
              )
            ]),
        Positioned(
            child: Container(
          alignment: Alignment.bottomCenter,
          child: Container(
            child: Text(
              '注册功能目前未上线，请使用网易云账号登录。',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            margin: EdgeInsets.only(bottom: 20, top: 0, left: 20, right: 20),
          ),
        ))
      ]),
    );
  }

  TextFormField buildBaseInput(
      {hintText: String, controller: TextEditingController}) {
    return TextFormField(
        controller: controller,
        maxLength: 11,
        maxLengthEnforced: true,
        decoration: InputDecoration(
            hintText: hintText,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            border: InputBorder.none));
  }

  void attachListeners() {
    accountController.addListener(() {
      print(accountController.text);
    });
    passwordController.addListener(() {});
  }
}

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginState();
}
