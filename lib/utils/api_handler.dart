import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
class ApiHandler{

  final _httpClient = HttpClient();


  String? userPassCode;
  int code = 0;
  String? uuid;
  String returnMsg = "請聯繫客服" ;

  bool isRoutineCheckRunning = false;


  // 1 is running,0 is stop
  int isCalculatorRunning = 0;


  String _generateUuid(){
    var uuidGenerator = const Uuid();
    return uuidGenerator.v4().toString();
  }

  Future<void> getUuid() async {
    final prefs = await SharedPreferences.getInstance();

    uuid = prefs.getString('uuid');
    if(uuid==null){
      uuid = _generateUuid();
      await prefs.setString('uuid', uuid!);
    }
    Fimber.i("uuid = $uuid");
  }


  Future<String?> checkServeState() async {

    var uri = Uri.http('bigwinners.cc', '/api/baccarat/check', {'code': userPassCode});
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    Fimber.i("data = $data");

    if(data["code"] == 0 && data["data"] == null){
      returnMsg = data['msg'];
      userPassCode = null;
      return null;
    }

    if(data["code"]==0){
      final Uri _url = Uri.parse(data["data"]["checkout_link"]);
      _launchUrl(_url);
      return null;
      // Fimber.i("link = ${data["data"]["checkout_link"]}");
    }

    code = data["code"];

    return "clear";
  }

  Future<void> _launchUrl(Uri _url) async {
    if (!await launchUrl(_url,
        mode: LaunchMode.externalApplication,webViewConfiguration: const WebViewConfiguration(enableJavaScript: true,enableDomStorage: true))) {
      throw 'Could not launch $_url';
    }
  }

  Future<void> debtApiWhenCloseApp()async{

    var uri = Uri.http('bigwinners.cc', '/api/baccarat/debt', {'code': userPassCode,'debt':"100"});
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    Fimber.i("data = $data");
    // debugPrint("data = $data");
  }


  Future<void> check2WhenCloseApp() async{
    int timestamp = DateTime.now().millisecondsSinceEpoch~/1000;
    await getUuid();
    final jwt = JWT(
        {
          'code': userPassCode,
          'uid': uuid,
          'iat': timestamp,
          'exp': timestamp+120,
          'exps': 120,
          'act': isCalculatorRunning
        });
    final token = jwt.sign(SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC('));
    var uri = Uri.http('bigwinners.cc', '/api/baccarat/check2', {'d': token});
    var request = await _httpClient.getUrl(uri);
    await request.close();
    Fimber.i("isCalculatorRunning = $isCalculatorRunning");
    Fimber.i("check2 finish");
    // debugPrint("check2 finish");
    // var responseBody = await response.transform(utf8.decoder).join();
  }

  Future<bool?> routineCheck() async{
    int timestamp = DateTime.now().millisecondsSinceEpoch~/1000;
    await getUuid();
    final jwt = JWT(
        {
          'code': userPassCode,
          'uid': uuid,
          'iat': timestamp,
          'exp': timestamp+120,
          'exps': 120,
          'act': isCalculatorRunning
        });
    final token = jwt.sign(SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC('));
    var uri = Uri.http('bigwinners.cc', '/api/baccarat/check2', {'d': token});
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    try {
      // Verify a token
      final jwt = JWT.verify(data['data']['d'], SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC('));
      // final jwt = JWT.verify(data['data']['d'],);
      // Fimber.i("SecretKey = ${SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC(').key}");
      Fimber.i('Payload: ${jwt.payload}');
      // if(jwt)
    } on JWTExpiredError {
      Fimber.i('jwt expired');
    } on JWTError catch (ex) {
      Fimber.i(ex.message);
      Fimber.i("JWTError : ${ex.message}"); // ex: invalid signature
    }
    return null;
  }
}