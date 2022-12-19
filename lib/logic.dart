

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:untitled/utils/isolate_function.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:untitled/data_handler.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';
import 'package:untitled/utils/snackbar_controller.dart';
import 'package:untitled/wm_detector/card_detector.dart';
import 'package:untitled/wm_detector/ui_detector.dart';

import 'allbet_detector/card_detector.dart';
import 'allbet_detector/ui_detector.dart';


class Logic{



  late SnackBarController snackBarController;
  late InAppWebViewController webViewController;
  late BuildContext context;
  DataHandler dataHandler = DataHandler();
  SelfEncryptedSharedPreference selfEncryptedSharedPreference = SelfEncryptedSharedPreference();
  WmCardDetector wmCardDetector = WmCardDetector();
  WmUIDetector wmUiDetector = WmUIDetector();
  AllbetCardDetector allbetCardDetector = AllbetCardDetector();
  AllbetUIDetector allbetUiDetector = AllbetUIDetector();

  bool isUIDetectorRunning = false;
  bool isShowProgress = true;
  bool cardDetectLock = false;
  int clickStartTimes = 0;

  bool isWmInGame = false;
  bool isAllbetInGame = false;

  ScreenshotConfiguration config = ScreenshotConfiguration();
  String? casino;


  Logic(){
    config.compressFormat = CompressFormat.JPEG;
  }


  void setup(BuildContext context,InAppWebViewController webViewController){
    this.context = context;
    this.webViewController = webViewController;
    snackBarController = SnackBarController(context: context);
  }


  void filterCasinoFromTitle(String? title){
    switch(title){
      case "WM":{
        // casino = title;
        setCasino(title);
        webViewController.evaluateJavascript(source: "document.getElementById('golobby_btn').addEventListener('click',function(e){console.log('wm_back')})");
      }
      break;

      case "ALLBET":
      case "CaliBet":{
      setCasino(title);
        // casino = title;
      }
      break;

      default:{
        setCasino(null);
        // casino = null;
      }
      break;
    }
  }

  void urlChangeDetect(String? title){
    if (isUIDetectorRunning) {



      switch(title){
        case "WM":{
          stopWmProcess();
          // _stopWmProcess();
        }
        break;

        case "ALLBET":
        case "CaliBet":{
        stopAllbetProcess();
          // _stopAllbetProcess();
        }
        break;

      }

      snackBarController.showRecognizeResult(
          "偵測到網頁跳轉，停止辨識", 2000);

      stop();
      // stop();

    }
  }

  void consoleMessageFilter(String? message){
    switch(message){
      case "console.groupEnd":{
        try{
          String catchDown =
              "document.getElementsByClassName('mobile vue')[0].addEventListener('mousedown',function(e){tapdown = e})";
          String catchUp =
              "document.getElementsByClassName('mobile vue')[0].addEventListener('mouseup',function(e){tapup = e})";
          webViewController.evaluateJavascript(
              source: 'var tapdown;');
          webViewController.evaluateJavascript(
              source: 'var tapup;');
          webViewController.evaluateJavascript(
              source: catchDown);
          webViewController.evaluateJavascript(
              source: catchUp);
          // webViewController?.evaluateJavascript(source: 'document.getElementById("backBtn").addEventListener("touchstart",function(e){console.log("allbet_back")})');
          webViewController.evaluateJavascript(source: 'document.getElementById("topBar-target").addEventListener("touchstart",function(e){console.log("allbet_back")})');
        }catch(error){
          Fimber.i("error = $error");
        }
      }
      break;
      case "allbet_back":{
        if (isUIDetectorRunning) {
          // apiHandler.routineCheck();
          snackBarController.showRecognizeResult(
              "偵測到網頁跳轉，停止辨識", 2000);
          stop();
          // stop();
        }
        isAllbetInGame = false;
      }
      break;
      case "wm_back":{
        if (isUIDetectorRunning) {
          // apiHandler.routineCheck();
          snackBarController.showRecognizeResult(
              "偵測到網頁跳轉，停止辨識", 2000);
          stop();
          // stop();
        }
        isWmInGame = false;
      }
      break;

      case "[FLVDemuxer] > Parsed onMetaData":{
        Fimber.i("isWmInGame = true");
        isWmInGame = true;
      }
      break;


    }
  }

  void setCasino(String? casino){
    this.casino = casino;
  }

  void stop(){
    isUIDetectorRunning = false;
    dataHandler.setUiRunning(isUIDetectorRunning);
    // stopTimer();
    dataHandler.reset();
    clickStartTimes = 0;

  }

  void start(){


    if(!isUIDetectorRunning){
      if(clickStartTimes != 0){
        Fimber.i("return");
        return;
      }
      Fimber.i("+=1");
      clickStartTimes += 1;
    }

    if(casino!=null){


      switch(casino){
        case "WM":{
          if(isWmInGame){
            wmProcess();
          }else{
            snackBarController.showRecognizeResult("偵測不到賭桌", 2000);
            stop();
          }

        }
        break;

        case "ALLBET":
        case "CaliBet":{
          webViewController.evaluateJavascript(source: 'document.getElementById("amount")').then((value) {
            if(value==null){
              allbetProcess();
            }else{
              snackBarController.showRecognizeResult("偵測不到賭桌", 2000);
              stop();
            }
          });

        }
        break;

        default:{
          snackBarController.showRecognizeResult("讀取不到場地", 1500);
          Fimber.i('casino = null');
          stop();
        }
        break;
      }

    }else{
      snackBarController.showRecognizeResult("讀取不到場地", 1500);
      Fimber.i('casino = null');
      stop();
    }
  }



  void stopWmProcess() {

    snackBarController.showRecognizeResult("停止辨識", 2000);
    stop();
  }



  void wmProcess() async {
    if(await selfEncryptedSharedPreference.checkIfReachLimitation()){
      snackBarController.showRecognizeResult("到達每日贏取上限", 2000);
      stop();
      return;
    }
    isShowProgress = true;
    cardDetectLock = false;

    isUIDetectorRunning = !isUIDetectorRunning;
    dataHandler.setUiRunning(isUIDetectorRunning);

    if (!isUIDetectorRunning) {
      // apiHandler.isCalculatorRunning = 0;
      // apiHandler.routineCheck();
      snackBarController.showRecognizeResult("停止辨識ui", 2000);
      stop();
    }
    while (isUIDetectorRunning) {

      if(await dataHandler.checkIfReachLimit()){
        stop();
        snackBarController.showRecognizeResult("到達每日贏取上限", 2000);
        selfEncryptedSharedPreference.setReachLimitation();
        return;
      }
      selfEncryptedSharedPreference.setLastPlayTimeDays();

      if (isShowProgress) {
        snackBarController.showRecognizeResult("開始辨識ui!", 2000);
      }
      isShowProgress = false;

      if (!dataHandler.isBetting) {
        config.quality = 50;

        Fimber.i("take screen shot");

        Uint8List? data = await webViewController.takeScreenshot(
            screenshotConfiguration: config);

        Fimber.i("screen shot finished");
        await webViewController.getContentHeight().then((value) => {
          dataHandler.mobileWidth = MediaQuery.of(context).size.width,
          dataHandler.mobileHeight = MediaQuery.of(context).size.height,
          dataHandler.webViewHeight = value!.toDouble(),
        });

        if (data != null) {
          image.Image? imageData = await compute(decodeImage, data);

          if (imageData != null) {
            bool isLaunchCardDetector =
            await wmUiDetector.putImageIntoModel(imageData);




            int state = wmUiDetector.getCalculatorState();

            dataHandler.refreshState(state,webViewController,casino!);
            if (state == 1 && cardDetectLock) {
              cardDetectLock = false;
            }

            if (isLaunchCardDetector && !cardDetectLock) {
              if (wmUiDetector.winSide == "bank") {
                Fimber.i("莊勝，開始辨識撲克牌");
                // snackBarController.showRecognizeResult("莊勝，開始辨識撲克牌", 1200);
              }
              if (wmUiDetector.winSide == "player") {
                Fimber.i("閒勝，開始辨識撲克牌");
                // snackBarController.showRecognizeResult("閒勝，開始辨識撲克牌", 1200);
              }
              if (wmUiDetector.winSide == "draw") {
                Fimber.i("和局，開始辨識撲克牌");
                // snackBarController.showRecognizeResult("和局，開始辨識撲克牌", 1200);
              }

              dataHandler.setWinSide(wmUiDetector.winSide);
              dataHandler.checkWinOrLose();
              wmUiDetector.winSide = null;

              List value = await wmCardDetector.putImageIntoModel(imageData);
              String cardResult = wmCardDetector.resultStr;
              dataHandler.insertCard(value);


              if (cardResult == "card error") {
                Fimber.i("card error");
                // ImageGallerySaver.saveImage(data, quality: 100);
              }else{
                snackBarController.showRecognizeResult(cardResult, 2000);
              }

              cardDetectLock = true;

              // await ImageGallerySaver.saveImage(data, quality: 100);
            }
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 3500));
    }
  }




  void stopAllbetProcess() {


    snackBarController.showRecognizeResult("停止辨識", 2000);
    stop();
  }

  void allbetProcess() async {

    if(await selfEncryptedSharedPreference.checkIfReachLimitation()){
      snackBarController.showRecognizeResult("到達每日贏取上限", 2000);
      stop();
      return;
    }

    isShowProgress = true;
    cardDetectLock = false;
    isUIDetectorRunning = !isUIDetectorRunning;
    dataHandler.setUiRunning(isUIDetectorRunning);

    if (!isUIDetectorRunning) {
      // apiHandler.isCalculatorRunning = 0;
      // apiHandler.routineCheck();
      snackBarController.showRecognizeResult("停止辨識ui", 2000);
      stop();
      return;
    }
    while (isUIDetectorRunning) {

      if(await dataHandler.checkIfReachLimit()){
        stop();
        snackBarController.showRecognizeResult("到達每日贏取上限", 2000);
        selfEncryptedSharedPreference.setReachLimitation();
        return;
      }

      selfEncryptedSharedPreference.setLastPlayTimeDays();


      if (isShowProgress) {
        snackBarController.showRecognizeResult("開始辨識ui!", 2000);
      }
      isShowProgress = false;

      if (!dataHandler.isBetting) {
        config.quality = 50;

        Fimber.i("take screen shot");

        Uint8List? data = await webViewController.takeScreenshot(
            screenshotConfiguration: config);

        Fimber.i("screen shot finished");

        await webViewController.getContentHeight().then((value) => {
          dataHandler.mobileWidth = MediaQuery.of(context).size.width,
          dataHandler.mobileHeight = MediaQuery.of(context).size.height,
          dataHandler.webViewHeight = value!.toDouble(),
        });

        if (data != null) {
          image.Image? imageData = await compute(decodeImage, data);

          if (imageData != null) {
            bool isLaunchCardDetector =
            await allbetUiDetector.putImageIntoModel(imageData);





            int state = allbetUiDetector.getCalculatorState();

            dataHandler.refreshState(state,webViewController,casino!);
            if (state == 1 && cardDetectLock) {
              cardDetectLock = false;
            }
            if (isLaunchCardDetector && !cardDetectLock) {
              if (allbetUiDetector.winSide == "bank") {
                Fimber.i("莊勝，開始辨識撲克牌");
                // snackBarController.showRecognizeResult("莊勝，開始辨識撲克牌", 1200);
              }
              if (allbetUiDetector.winSide == "player") {
                Fimber.i("閒勝，開始辨識撲克牌");
                // snackBarController.showRecognizeResult("閒勝，開始辨識撲克牌", 1200);
              }
              if (allbetUiDetector.winSide == "draw") {
                Fimber.i("和局，開始辨識撲克牌");
                // snackBarController.showRecognizeResult("和局，開始辨識撲克牌", 1200);
              }

              dataHandler.setWinSide(allbetUiDetector.winSide);
              dataHandler.checkWinOrLose();
              allbetUiDetector.winSide = null;

              List value = await allbetCardDetector.putImageIntoModel(imageData);
              String cardResult = allbetCardDetector.resultStr;
              dataHandler.insertCard(value);

              if (cardResult == "card error") {
                Fimber.i("card error");
              }else{
                snackBarController.showRecognizeResult(cardResult, 2000);
              }


              cardDetectLock = true;

              // await ImageGallerySaver.saveImage(data, quality: 100);
            }
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 3500));
    }
  }

  void swapKeepOneMode() {
    dataHandler.swapKeepOneMode();
  }


}