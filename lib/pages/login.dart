import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluro/fluro.dart';
import 'package:silence/tools/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:silence/router/routes.dart';
import 'package:silence/store/store.dart';
import 'package:provider/provider.dart';

class LoginState extends State<Login> {
  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneInputKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    attachListeners();
  }

  @override
  void dispose() {
    super.dispose();
    accountController.dispose();
    passwordController.dispose();
  }

  Future login({String phone, String password}) async {
    Dio dio = await getDioInstance();
    Response loginResult = await dio
        .post('${interfaces['phoneLogin']}?phone=$phone&password=$password')
        .catchError((error) => error.response);
    Map loginData = loginResult.data;
    if (loginData['code'] == 200) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt("uid", loginData['account']['id']);
    }
    return loginData;
  }

  void showErrorMessage(String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: Text(message,
                style: TextStyle(color: Colors.black87, fontSize: 14))));
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
            validator: (value) => value.length <= 1 ? '你的密码应该不会这么短吧' : null,
            controller: passwordController,
            decoration: InputDecoration(
                hintText: '密码',
                suffixIcon: Icon(Icons.account_box, color: Colors.blue),
                counterText: '',
                errorStyle: TextStyle(color: Colors.lightBlue),
                border: InputBorder.none)));

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
                          children: <Widget>[accountInput, passwordInput])),
                  FlatButton(
                      child: Text(
                        '登录',
                        style: TextStyle(color: Colors.black87),
                      ),
                      onPressed: onPressLogin)
                ]))
          ]),
      Positioned(
          child: Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                child: Text(
                  '注册功能目前未上线，请使用网易云账号登录。',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
                margin:
                    EdgeInsets.only(bottom: 20, top: 0, left: 20, right: 20),
              )))
    ]));
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
    accountController.addListener(() {});
    passwordController.addListener(() {});
  }

  onPressLogin() async {
    if (!phoneInputKey.currentState.validate()) return;
    Map loginData = await login(
        phone: accountController.text, password: passwordController.text);
    if (loginData['code'] != 200) {
      showErrorMessage(loginData['msg'] ?? loginData['message']);
      return;
    }
    Provider.of<Store>(context, listen: false)
        .setUserInfo(loginData['profile']);
    RoutesCenter.router.navigateTo(context, '/launch',
        transition: TransitionType.fadeIn, replace: true);
  }
}

class Login extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LoginState();
}
