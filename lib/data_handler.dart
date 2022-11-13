import 'package:fimber/fimber.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DataHandler{


  double playerButtonX = -1.0;
  double playerButtonY = -1.0;
  double bankButtonX = -1.0;
  double bankButtonY = -1.0;
  double confirmButtonX = -1.0;
  double confirmButtonY = -1.0;
  GestureBinding taper = GestureBinding.instance;

  double mobileHeight = -1.0;
  double mobileWidth = -1.0;
  double webViewHeight = -1.0;

  String? betSide;
  String? winSide;
  int betTimes = 1 ;


  bool isBetting = false;
  int _point = 0;



  /*
  state
  0 = 辨識牌
  1 = 下注
  2 = 洗牌
  出現 莊勝或是閒勝時候 切換state = 0
  計算完再下注期間進行操作
   */
  int _state = -1;

  var pointMap = <int,int>{
    0:0,
    1:1,
    2:1,
    3:2,
    4:3,
    5:-2,
    6:-2,
    7:-2,
    8:-1,
    9:0,
  };

  DataHandler();

  void insertCard(List cardList){
    for(var card in cardList){
      Fimber.i("card = $card");
      _point += pointMap[card]!;
    }
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
    }else if(_state ==1){
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
      if(_point>0){
        Fimber.i('betBank');
        for (int i = 0; i < betTimes; i++){
          clickBank(webViewController, casino);

          // await betBank();
        }
        betSide="bank";
      }else if(_point<0){
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
      if(betSide!=null){
        clickConfirm(webViewController, casino);
        // await bettingConfirm();
      }

      // betTimes = 31;
      isBetting = false;
    }
  }
  void _reset(){
    Fimber.i("reset");
    _point = 0;
    betTimes=1;
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
    // webViewController.evaluateJavascript(source: 'document.getElementById("multiBetAreaBtn").dispatchEvent(tapdown);');
    // webViewController.evaluateJavascript(source: 'document.getElementById("multiBetAreaBtn").dispatchEvent(tapup);');


    webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapdown);');
    webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapup);');
  }

  void clickBank(InAppWebViewController webViewController,String casino) async {
    switch(casino){
      case "WM":{
        // ContentWorld.world(name: webViewController.getIFrameId());

        webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101');");
        webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document;");
        webViewController.evaluateJavascript(source: "var form = doc.getElementById('playbetboxBanker').click();");
        // document.getElementById('playbetboxBanker').click()
      }
      break;

      case "ALLBET":{
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapdown);');
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer banker enabled")[0].dispatchEvent(tapup);');
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
        webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101');");
        webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document;");
        webViewController.evaluateJavascript(source: "var form = doc.getElementById('playbetboxPlayer').click();");
      }
      break;

      case "ALLBET":{
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer player enabled")[0].dispatchEvent(tapdown);');
        webViewController.evaluateJavascript(source: 'document.getElementsByClassName("betTypeAreaContainer player enabled")[0].dispatchEvent(tapup);');
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
        webViewController.evaluateJavascript(source: "var win = document.getElementById('iframe_101');");
        webViewController.evaluateJavascript(source: "var doc = win.contentDocument? win.contentDocument : win.contentWindow.document;");
        webViewController.evaluateJavascript(source: "var form = doc.getElementById('bet_btn').click();");
      }
      break;

      case "ALLBET":{
        webViewController.evaluateJavascript(source: 'document.getElementById("confirmBtn").dispatchEvent(tapdown);');
        webViewController.evaluateJavascript(source: 'document.getElementById("confirmBtn").dispatchEvent(tapup);');
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

  void checkWinOrLose(String? winSide){
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
  }

  void noBet(){
    return;
  }
}


