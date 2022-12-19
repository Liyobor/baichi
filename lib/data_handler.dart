import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';


enum Strategy{
  base,
  martingale,
  keepOne,
}
class DataHandler extends ChangeNotifier{


  static final DataHandler _singleton = DataHandler._internal();
  factory DataHandler() {
    return _singleton;
  }




  DataHandler._internal();


  // double playerButtonX = -1.0;
  // double playerButtonY = -1.0;
  // double bankButtonX = -1.0;
  // double bankButtonY = -1.0;
  // double confirmButtonX = -1.0;
  // double confirmButtonY = -1.0;
  GestureBinding taper = GestureBinding.instance;

  double mobileHeight = -1.0;
  double mobileWidth = -1.0;
  double webViewHeight = -1.0;

  String? betSide;
  String? winSide;
  int betTimes = 1 ;
  bool _isUiRunning = false;

  int get betTime => betTimes;
  bool get isUiRunning => _isUiRunning;


  bool isBetting = false;
  int _point = 0;


  double pointOfPlayer = -0.23508/100;
  double pointOfBank = -0.05791/100;

  int baseQuantity = 1000;

  double money = 0;

  var pointMap = <int,double>{
    0:0,
    1:0.0018/100,
    2:0.0045/100,
    3:0.0054/100,
    4:0.0120/100,
    5:-0.0084/100,
    6:-0.0113/100,
    7:-0.0082/100,
    8:-0.0053/100,
    9:-0.0025/100,
  };


  /*
  state
  0 = 辨識牌
  1 = 下注
  2 = 洗牌
  出現 莊勝或是閒勝時候 切換state = 0
  計算完再下注期間進行操作
   */
  int _state = -1;

  // var pointMap = <int,int>{
  //   0:0,
  //   1:1,
  //   2:1,
  //   3:2,
  //   4:3,
  //   5:-2,
  //   6:-2,
  //   7:-2,
  //   8:-1,
  //   9:0,
  // };



  Strategy betStrategy = Strategy.martingale;

  void insertCard(List cardList){
    for(var card in cardList){
      // Fimber.i("card = $card");
      pointOfBank += pointMap[card]!;
      pointOfPlayer -= pointMap[card]!;
      // _point += pointMap[card]!;
    }
    calculateBetTimes(betStrategy);
    notifyListeners();
  }

  void setUiRunning(bool isRunning){
    _isUiRunning = isRunning;
    notifyListeners();
  }

  bool bar(){
    if(_point>0){
      return true;
    }
    return false;
  }

  bool refreshState(int state,InAppWebViewController webViewController,String casino){
    if(_state == state){
      return false;
    }
    _state =state;
    Fimber.i("state change to $_state");
    if(_state==2){
      _reset();
    }else if(_state == 1){
      _bet(webViewController,casino);
    }else if(_state==0){
      Fimber.i("stop betting!");
    }
    return true;
  }

  Future<void> _bet(InAppWebViewController webViewController,String casino) async {
    Fimber.i("bet");
    // if(bankButtonY < 0 || bankButtonX<0 ||playerButtonY<0 || playerButtonX<0 || confirmButtonX<0 || confirmButtonY<0 || webViewHeight<0 || mobileHeight<0 || mobileWidth<0){
    //   Fimber.i("Button pos error!");
    //   return;
    // }
    if(_state == 1){
    //  do bet operation

      isBetting = true;


      await Future.delayed(const Duration(milliseconds: 100));

      if(pointOfPlayer<pointOfBank){
        Fimber.i('betBank');
        for (int i = 0; i < betTimes; i++){
          clickBank(webViewController, casino);
        }
        betSide="bank";
      }else if(pointOfPlayer>=pointOfBank){
        Fimber.i('betPlayer');
        for (int i = 0; i < betTimes; i++) {
          clickPlayer(webViewController, casino);

          // await betPlayer();
        }
        betSide = "player";
      }else{
        Fimber.i("_point = 0");
        betSide = null;
      }

      // if(_point>0){
      //   Fimber.i('betBank');
      //   for (int i = 0; i < betTimes; i++){
      //     clickBank(webViewController, casino);
      //
      //     // await betBank();
      //   }
      //   betSide="bank";
      // }else if(_point<0){
      //   Fimber.i('betPlayer');
      //   for (int i = 0; i < betTimes; i++) {
      //     clickPlayer(webViewController, casino);
      //
      //     // await betPlayer();
      //   }
      //   betSide = "player";
      // }else{
      //   Fimber.i("_point = 0");
      //   betSide = null;
      // }

      if(betSide!=null){
        await Future.delayed(const Duration(milliseconds: 100));
        clickConfirm(webViewController, casino);
        // await bettingConfirm();
      }

      // betTimes = 31;
      isBetting = false;
    }
  }


  bool _keepOneMode = false;
  bool get keepOneMode => _keepOneMode;
  void swapKeepOneMode(){

    _keepOneMode=!_keepOneMode;
    notifyListeners();
  }


  void calculateBetTimes(Strategy strategy){


    if(keepOneMode){
      strategy = Strategy.keepOne;
    }

    switch(strategy){
      case Strategy.keepOne:{
        betTimes = 1;
      }
      break;
      case Strategy.base:{
        if(pointOfBank <0 && pointOfPlayer<0){
          betTimes = 1;
          return;
        }
        if(pointOfBank>pointOfPlayer){
          betTimes = (money*pointOfBank*0.76/baseQuantity).round();
        }else{
          betTimes = (money*pointOfPlayer*0.76/baseQuantity).round();
        }
        if(betTimes<0){
          betTimes = 1;
        }
      }
      break;
      case Strategy.martingale:{
        if(winSide==null || betSide==null){
          Fimber.i("winSide or betSide = null");
          Fimber.i("betTimes didn't change!");
          Fimber.i("betTimes = $betTimes");
          return;
        }
        Fimber.i("winSide = $winSide");
        Fimber.i("betSide = $betSide");
        if(winSide == "draw"){
          winSide = null;
          betSide = null;
          return;
        }
        if(winSide == betSide || betTimes > 32){
          betTimes = 1;
          Fimber.i("betTimes = 1");
        }else{

          Fimber.i("betTimes = ${betTimes * 2 + 1}");
          betTimes = betTimes*2+1;
        }
        winSide=null;
      }
      break;
    }



  }
  void _reset(){
    Fimber.i("reset");
    _point = 0;
    betTimes=1;
    winSide = null;
    betSide = null;
    pointOfPlayer = -0.23508/100;
    pointOfBank = -0.05791/100;
  }
  void reset(){
    Fimber.i("public reset");
    _reset();
    _state = -1;
  }

  void clickTest(InAppWebViewController webViewController){
    // webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101');");
    // webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document;");
    // webViewController.evaluateJavascript(source: "var form = doc.getElementById('playbetboxPlayer').click();");
    // webViewController.evaluateJavascript(source: 'document.getElementsByClassName("btn login-btn")[0].click()',contentWorld: );
    webViewController.evaluateJavascript(source: 'document.getElementById("multiBetAreaBtn").dispatchEvent(tapdown);');
    webViewController.evaluateJavascript(source: 'document.getElementById("multiBetAreaBtn").dispatchEvent(tapup);');


    // webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapdown);');
    // webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapup);');
  }

  void clickBank(InAppWebViewController webViewController,String casino) async {
    switch(casino){
      case "WM":{
        // ContentWorld.world(name: webViewController.getIFrameId());

        webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101')");
        webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document");
        webViewController.evaluateJavascript(source: "var form = doc.getElementById('playbetboxBanker').click()");
        // document.getElementById('playbetboxBanker').click()
      }
      break;

      case "ALLBET":
      case "CaliBet":{
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapdown)');
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapup)');
        // await betBank();
      }
      break;

      default:{}
      break;
    }



  }

  Future<void> clickPlayer(InAppWebViewController webViewController,String casino) async {

    switch(casino){
      case "WM":{
        // webViewController.evaluateJavascript(source: "document.getElementById('playbetboxPlayer').click()");
        webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101')");
        webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document");
        webViewController.evaluateJavascript(source: "var form = doc.getElementById('playbetboxPlayer').click()");
      }
      break;

      case "ALLBET":
      case "CaliBet":{
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer player enabled")[0].dispatchEvent(tapdown)');
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer player enabled")[0].dispatchEvent(tapup)');
        // await betPlayer();
      }
      break;

      default:{}
      break;
    }

  }



  Future<void> clickConfirm(InAppWebViewController webViewController,String casino) async {
    switch(casino){
      case "WM":{
        // webViewController.evaluateJavascript(source: "document.getElementById('bet_btn').click()");
        webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101')");
        webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document");
        webViewController.evaluateJavascript(source: "var form = doc.getElementById('bet_btn').click()");
      }
      break;

      case "ALLBET":
      case "CaliBet":{
        webViewController.evaluateJavascript(source: 'document.getElementById("confirmBtn").dispatchEvent(tapdown)');
        webViewController.evaluateJavascript(source: 'document.getElementById("confirmBtn").dispatchEvent(tapup)');
        // bettingConfirm();
      }
      break;

      default:{}
      break;
    }
  }

  // Future<void> betBank() async {
  //   Fimber.i("betBank");
  //
  //   Fimber.i("bankButton pos :$bankButtonX,$bankButtonY");
  //   await Future.delayed(const Duration(milliseconds: 50));
  //   taper.handlePointerEvent(PointerDownEvent(
  //     position: Offset(bankButtonX, bankButtonY),
  //   ));
  //   await Future.delayed(const Duration(milliseconds: 50));
  //   taper.handlePointerEvent(PointerUpEvent(
  //     position: Offset(bankButtonX, bankButtonY),
  //   ));
  //   betSide = "bank";
  //
  // }

  // Future<void> betPlayer() async {
  //   Fimber.i("betPlayer");
  //
  //   Fimber.i("playerButton pos :$playerButtonX,$playerButtonY");
  //   await Future.delayed(const Duration(milliseconds: 50));
  //   taper.handlePointerEvent(PointerDownEvent(
  //     position: Offset(playerButtonX, playerButtonY),
  //   ));
  //   await Future.delayed(const Duration(milliseconds: 50));
  //   taper.handlePointerEvent( PointerUpEvent(
  //     position: Offset(playerButtonX, playerButtonY),
  //   ));
  //   betSide = "player";
  // }

  // Future<void> bettingConfirm() async {
  //   Fimber.i("bettingConfirm");
  //
  //   await Future.delayed(const Duration(milliseconds: 300));
  //
  //   Fimber.i("confirmButton pos :$confirmButtonX,$confirmButtonY");
  //   taper.handlePointerEvent(PointerDownEvent(
  //     position: Offset(confirmButtonX, confirmButtonY),
  //   ));
  //   await Future.delayed(const Duration(milliseconds: 50));
  //   taper.handlePointerEvent(PointerUpEvent(
  //     position: Offset(confirmButtonX, confirmButtonY),
  //   ));
  //
  // }


  void setWinSide(String? side){
    winSide = side;
  }

  // int winTimes = 0;
  int limitedWinTimesDaily = 5 ;

  Future<void> calculateWinTimes(bool isWin) async {
    SelfEncryptedSharedPreference selfEncryptedSharedPreference = SelfEncryptedSharedPreference();
    String? winTimesStr = await selfEncryptedSharedPreference.getWinTimes();
    if (kDebugMode) {
      print("winTimes = $winTimesStr");
    }
    if(isWin){


      if(winTimesStr!=null){
        int winTimes = int.parse(winTimesStr);
        selfEncryptedSharedPreference.setWinTimes(winTimes+betTimes);
        if (kDebugMode) {
          print("set winTimes = ${winTimes+betTimes}");
        }
        return;
      }
      selfEncryptedSharedPreference.setWinTimes(betTimes);
      if (kDebugMode) {
        print("set winTimes = $betTimes");
      }
      return;
    }else{

      if(winTimesStr!=null){
        int winTimes = int.parse(winTimesStr);
        selfEncryptedSharedPreference.setWinTimes(winTimes-betTimes);
        if (kDebugMode) {
          print("set winTimes = ${winTimes-betTimes}");
        }
        return;

      }
      selfEncryptedSharedPreference.setWinTimes(-1*betTimes);
      if (kDebugMode) {
        print("set winTimes = ${-1*betTimes}");
      }
      return;
    }


  }

  Future<bool> checkIfReachLimit() async {
    SelfEncryptedSharedPreference selfEncryptedSharedPreference = SelfEncryptedSharedPreference();
    String? winTimesStr = await selfEncryptedSharedPreference.getWinTimes();
    if(winTimesStr!=null){
      return int.parse(winTimesStr) >= limitedWinTimesDaily;
    }

    return false;

  }

  void checkWinOrLose(){
    if(winSide==null || betSide==null){
      Fimber.i("winSide or betSide = null");
      // Fimber.i("betTimes didn't change!");
      // Fimber.i("betTimes = $betTimes");
      return;
    }
    Fimber.i("winSide = $winSide");
    Fimber.i("betSide = $betSide");

    if(winSide == "draw"){
      winSide = null;
      betSide = null;
      return;
    }

    if(winSide==betSide){
      calculateWinTimes(true);
    }

    if(winSide!=betSide){
      calculateWinTimes(false);
    }


    // if(winSide == betSide || betTimes > 32){
    //   betTimes = 1;
    //   Fimber.i("betTimes = 1");
    // }else{
    //
    //   Fimber.i("betTimes = ${betTimes * 2 + 1}");
    //   betTimes = betTimes*2+1;
    // }
  }

  void noBet(){
    return;
  }
}


