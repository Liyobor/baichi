import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:fimber/fimber.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:untitled/utils/counter.dart';
// import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';


class ApiHandler{

  final _httpClient = HttpClient();


  String? userPassCode;
  int code = 0;
  String? uuid;
  String returnMsg = "請聯繫客服" ;



  bool isRoutineCheckRunning = false;
  Counter counter = Counter();


  SelfEncryptedSharedPreference selfEncryptedSharedPreference = SelfEncryptedSharedPreference();
  // EncryptedSharedPreferences encryptedSharedPreferences = EncryptedSharedPreferences();
  dynamic pref;


  // 1 is running,0 is stop
  int isCalculatorRunning = 0;


  // String _generateUuid(){
  //   var uuidGenerator = const Uuid();
  //   return uuidGenerator.v4().toString();
  // }

  // ApiHandler()  {
  //   encryptedSharedPreferences.getInstance().then((value) => pref=value);
  // }

  // Future<void> getUuid() async {
  //
  //   if(!pref.containsKey('uuid')){
  //     uuid = _generateUuid();
  //     await encryptedSharedPreferences.setString('uuid', uuid!);
  //   }else{
  //     uuid = await encryptedSharedPreferences.getString('uuid');
  //   }
  //   // uuid = await encryptedSharedPreferences.getString('uuid');
  //   // uuid = prefs.getString('uuid');
  //   if(uuid==null){
  //     uuid = _generateUuid();
  //     await encryptedSharedPreferences.setString('uuid', uuid!);
  //     // await prefs.setString('uuid', uuid!);
  //   }
  //   Fimber.i("uuid = $uuid");
  // }


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

    var uri = Uri.http('bigwinners.cc', '/api/baccarat/debt', {'code': userPassCode,'debt':"0"});
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    Fimber.i("data = $data");
    if(data['code']==1){

    }
    // debugPrint("data = $data");
  }


  Future<void> debtApi (int fee) async{

    var uri = Uri.http('bigwinners.cc', '/api/baccarat/debt', {'code': userPassCode,'debt':fee});
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    Fimber.i("data = $data");
    if(data['code'] == 1){
      final Uri _url = Uri.parse(data["data"]["checkout_link"]);
      _launchUrl(_url);
    }


    // debugPrint("data = $data");
  }

  Future<void> check2WhenCloseApp() async{
    int timestamp = DateTime.now().millisecondsSinceEpoch~/1000;
    // await getUuid();
    uuid = await selfEncryptedSharedPreference.getUuidString();
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
    Fimber.i("counter.count = ${counter.count}");
    int timestamp = DateTime.now().millisecondsSinceEpoch~/1000;
    uuid = await selfEncryptedSharedPreference.getUuidString();
    final jwt = JWT(
        {
          'code': userPassCode,
          'uid': uuid,
          'iat': timestamp,
          'exp': timestamp+120,
          'exps': 120,
          'act': isCalculatorRunning
        });
    Fimber.i("isCalculatorRunning = $isCalculatorRunning");
    final token = jwt.sign(SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC('));
    var uri = Uri.http('bigwinners.cc', '/api/baccarat/check2', {'d': token});
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    Map data = json.decode(responseBody);
    try {
      // Verify a token
      final jwt = JWT.verify(data['data']['d'], SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC('));
      code = jwt.payload["response_code"];
      // final jwt = JWT.verify(data['data']['d'],);
      // Fimber.i("SecretKey = ${SecretKey(r'G"cUpXG*2s}~&XLg$Bo#h8wnwl!>r7sX2vC(').key}");
      Fimber.i('Payload: ${jwt.payload}');

      Fimber.i("${jwt.payload["response_code"]}");
      Fimber.i("code =$code");
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