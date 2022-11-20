import 'dart:async';
import 'dart:collection';
// import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:untitled/utils/api_handler.dart';
import 'package:untitled/utils/counter.dart';
import 'package:untitled/data_handler.dart';
import 'package:untitled/utils/isolate_function.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';
import 'package:untitled/utils/snackbar_controller.dart';

import 'package:url_launcher/url_launcher_string.dart';

import 'package:image/image.dart' as image;
import 'package:provider/provider.dart';

import 'allbet_detector/card_detector.dart';
import 'allbet_detector/ui_detector.dart';
import 'wm_detector/card_detector.dart';
import 'wm_detector/ui_detector.dart';

// var _snackBarPresenting = false;

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({Key? key}) : super(key: key);

  @override
  State<InAppWebViewExampleScreen> createState() =>
      _InAppWebViewExampleScreenState();
}

class _InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen>
    with WidgetsBindingObserver {
  final GlobalKey webViewKey = GlobalKey();
  // Timer? timer;
  String? codeDialog;
  String? valueText;

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(

    useOnLoadResource: true,
    javaScriptEnabled: true,
    // useShouldInterceptAjaxRequest: true,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
  );
  // InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
  //     crossPlatform: InAppWebViewOptions(
  //         useOnLoadResource: true,
  //         javaScriptEnabled: true,
  //         useShouldInterceptAjaxRequest: true,
  //         useShouldOverrideUrlLoading: true,
  //         mediaPlaybackRequiresUserGesture: false),
  //     android: AndroidInAppWebViewOptions(
  //       useHybridComposition: true,
  //     ),
  //     ios: IOSInAppWebViewOptions(
  //       allowsInlineMediaPlayback: true,
  //       useOnNavigationResponse: true
  //     ));

  late PullToRefreshController pullToRefreshController;
  late ContextMenu contextMenu;
  String? imeiNo;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  WmCardDetector wmCardDetector = WmCardDetector();
  WmUIDetector wmUiDetector = WmUIDetector();

  AllbetCardDetector allbetCardDetector = AllbetCardDetector();
  AllbetUIDetector allbetUiDetector = AllbetUIDetector();

  DataHandler dataHandler = DataHandler();
  ApiHandler apiHandler = ApiHandler();

  // final TextEditingController _textFieldController = TextEditingController();

  ScreenshotConfiguration config = ScreenshotConfiguration();
  late SnackBarController snackBarController;
  SelfEncryptedSharedPreference selfEncryptedSharedPreference =
      SelfEncryptedSharedPreference();

  bool isUIDetectorRunning = false;
  bool isShowProgress = true;
  bool cardDetectLock = false;
  String? html;

  double wmMoney = -1;
  double allbetMoney = -1;
  double fee = 0;

  String? casino;

  int clickStartTimes = 0;
  int paidTime = 6000;

  bool isWmInGame = false;
  // bool isAllbetInGame = false;
  int wmEnterPageConsoleLogTimes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    config.compressFormat = CompressFormat.JPEG;
    snackBarController = SnackBarController(context: context);


    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              id: 1,

              title: "Special",
              action: () async {
                Fimber.i("Menu item Special clicked!");
                // Fimber.i(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
        // options: ContextMenuOptions(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          Fimber.i("onCreateContextMenu");
          // Fimber.i("${hitTestResult.extra}");
          // Fimber.i("${await webViewController?.getSelectedText()}");
        },
        onHideContextMenu: () {
          Fimber.i("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = (Platform.isAndroid)
              ? contextMenuItemClicked.id
              : contextMenuItemClicked.id.toString();
          Fimber.i("onContextMenuActionItemClicked: $id ${contextMenuItemClicked.title}");
        });

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue
      ),
      // options: PullToRefreshOptions(
      //   color: Colors.blue,
      // ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var counter = Provider.of<Counter>(context);
    counter.count;
    return Scaffold(
        backgroundColor: Colors.white,
        // appBar: AppBar(title: const Text("InAppWebView")),
        // drawer: myDrawer(context: context),
        body: SafeArea(
            child: GestureDetector(
          onTapDown: (details) {
            Fimber.i("${details.globalPosition}");
          },

            child: Column(children: <Widget>[
              TextField(
                decoration:
                    const InputDecoration(prefixIcon: Icon(Icons.search)),
                controller: urlController,
                keyboardType: TextInputType.url,
                onSubmitted: (value) {
                  var url = WebUri(value);
                  if (url.scheme.isEmpty) {
                    url = WebUri("https://www.google.com/search?q=$value");
                  }
                  webViewController?.loadUrl(urlRequest: URLRequest(url: url));
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(

                      key: webViewKey,
                      // contextMenu: contextMenu,
                      initialUrlRequest: URLRequest(
                          url:
                          WebUri(apiHandler.defaultUrl)),
                      // initialFile: "assets/index.html",
                      initialUserScripts: UnmodifiableListView<UserScript>([]),
                      initialSettings: settings,
                      pullToRefreshController: pullToRefreshController,
                      onLoadResource: (controller, resource) {


                        if(resource.url.toString().contains("www.ab.games:8888/undefined")){

                          webViewController?.evaluateJavascript(source: 'document.getElementById("backBtn").addEventListener("touchstart",function(e){console.log("allbet_back")})');
                        }
                      },

                      onWebViewCreated: (controller) {
                        webViewController = controller;
                        counter.initCount();
                      },
                      onLoadStart: (controller, url) {
                        Fimber.i('onLoadStart');
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },

                      onPermissionRequest: (controller,request) async {
                        return PermissionResponse(resources: request.resources,action: PermissionResponseAction.GRANT);
                        }
                        ,


                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          if (await canLaunchUrlString(url)) {
                            // Launch the App
                            await launchUrlString(url);

                            // and cancel the request
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        return NavigationActionPolicy.ALLOW;
                      },

                      onLoadStop: (controller, url) async {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                        
                        
                      },
                      onReceivedError: (controller,request,error){
                        pullToRefreshController.endRefreshing();
                      },

                      onProgressChanged: (controller, progress) {

                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = url;
                        });
                      },

                      onTitleChanged: (controller, title) async {

                        Fimber.i("title = $title");

                        switch(title){
                          case "WM":{
                            casino = title;
                            webViewController?.evaluateJavascript(source: "document.getElementById('golobby_btn').addEventListener('click',function(e){console.log('wm_back')})");
                          }
                          break;

                          case "ALLBET":{
                            casino = title;
                          }
                          break;

                          default:{
                            casino = null;
                          }
                          break;
                        }



                        if (isUIDetectorRunning) {



                          switch(title){
                            case "WM":{
                              _stopWmProcess();
                            }
                            break;

                            case "ALLBET":{
                              _stopAllbetProcess();
                            }
                            break;

                          }

                          snackBarController.showRecognizeResult(
                              "偵測到網頁跳轉，停止辨識", 2000);

                          stop();

                        }
                      },
                      onCloseWindow: (controller) {
                        Fimber.i('onCloseWindow');
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        Fimber.i("consoleMessage = ${consoleMessage.message}");
                        html = null;

                        if(consoleMessage.message.contains("call start play url")&&casino=="ALLBET"){
                          String catchDown = "document.getElementsByClassName('mobile vue')[0].addEventListener('mousedown',function(e){tapdown = e})";
                          String catchUp = "document.getElementsByClassName('mobile vue')[0].addEventListener('mouseup',function(e){tapup = e})";
                          webViewController?.evaluateJavascript(source: 'var tapdown;');
                          webViewController?.evaluateJavascript(source: 'var tapup;');
                          webViewController?.evaluateJavascript(source: catchDown);
                          webViewController?.evaluateJavascript(source: catchUp);
                        }

                        switch(consoleMessage.message){
                          case "allbet_back":{
                            if (isUIDetectorRunning) {
                              apiHandler.routineCheck();
                              snackBarController.showRecognizeResult(
                                  "偵測到網頁跳轉，停止辨識", 2000);
                              stop();
                            }
                            // isAllbetInGame = false;
                          }
                          break;
                          case "wm_back":{
                            if (isUIDetectorRunning) {
                              apiHandler.routineCheck();
                              snackBarController.showRecognizeResult(
                                  "偵測到網頁跳轉，停止辨識", 2000);
                              stop();
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

                        
                      },
                      onCreateWindow: (controller, createWindowRequest) async {
                        Fimber.i("onCreateWindow");
                        return null;
                      },
                    ),
                    progress < 1.0
                        ? LinearProgressIndicator(value: progress)
                        : Container(),

                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).size.height*0.15),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height*0.15,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    child: const Icon(Icons.arrow_back),
                                    onPressed: () {
                                      webViewController?.goBack();
                                    },
                                  ),
                                  ElevatedButton(
                                    child: const Icon(Icons.refresh),
                                    onPressed: () async {
                                      webViewController?.reload();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).size.height*0.15),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height*0.15,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    height: 35,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                  color: Colors.blue),
                                            ),
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                setState(() {

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

                                                      case "ALLBET":{
                                                        webViewController?.evaluateJavascript(source: 'document.getElementById("amount")').then((value) {
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

                                                });
                                              },
                                              child: (isUIDetectorRunning)
                                                  ? const Text("停止辨識",
                                                  style: TextStyle(
                                                      color: Colors.white))
                                                  : const Text("開始辨識",
                                                  style: TextStyle(
                                                      color: Colors.white)))
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: 35,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                  color: Colors.blue),
                                            ),
                                          ),
                                          TextButton(
                                              onPressed: () async {
                                                launchUrlString(
                                                    'https://line.me/ti/p/@516wvzjp');
                                              },
                                              child: const Text(
                                                "聯繫客服",
                                                style: TextStyle(color: Colors.white),
                                              ))
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),




                    // IgnorePointer(
                    //   child: Align(
                    //     alignment: Alignment.bottomCenter,
                    //     child:
                    //         // Text('使用時間剩餘:${(7200- counter.count)~/60}分鐘',
                    //         Text('使用時間剩餘:${(7200 - counter.count)}秒',
                    //             style: const TextStyle(
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Colors.red,
                    //                 fontSize: 20.0)),
                    //   ),
                    // ),
                    IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height*0.1,
                            child: Padding(
                              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.05),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child:
                                    // Text('使用時間剩餘:${(7200- counter.count)~/60}分鐘',
                                    Stack(
                                      children: [
                                        Positioned.fill(child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white
                                          ),
                                        )),
                                        Text('莊家機率:${(dataHandler.pointOfBank*100).toStringAsFixed(4)}%',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                                fontSize: 20.0)),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child:
                                    // Text('使用時間剩餘:${(7200- counter.count)~/60}分鐘',
                                    Stack(
                                      children: [
                                        Positioned.fill(child: Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.white
                                          ),
                                        )),
                                        Text('閒家機率:${(dataHandler.pointOfPlayer*100).toStringAsFixed(4)}%',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                                fontSize: 20.0)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            width: MediaQuery.of(context).size.width*0.35,
                            child: Stack(
                              children: [
                                Positioned.fill(child: Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.white
                                  ),
                                )),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Text('下注數:${dataHandler.betTimes}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 20.0)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),


                  ],
                ),
              ),
            ]),
          // ),
        )));
  }

  // void startTimer() {
  //   if (timer == null) {
  //     Fimber.i('Start Timer');
  //     timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //       setState(() {
  //         Provider.of<Counter>(context, listen: false).addCount();
  //       });
  //     });
  //   } else {
  //     Fimber.i('Stop Timer');
  //     timer?.cancel();
  //     timer = null;
  //   }
  // }

  // void stopTimer() {
  //   if (timer != null) {
  //     Fimber.i('Stop Timer');
  //     timer?.cancel();
  //     timer = null;
  //   }
  // }

  void stop(){
    setState(() {
      isUIDetectorRunning = false;
    });
    // stopTimer();
    dataHandler.reset();
    clickStartTimes = 0;
  }

  Future<double> allbetCatchMoneyJS() async {

    String temp = await webViewController?.evaluateJavascript(source: 'document.getElementById("amount").textContent');
    temp = temp.replaceAll(",", "");
    double moneyTemp = double.parse(temp);
    Fimber.i("moneyTemp = $moneyTemp");
    return moneyTemp;
  }

  // Future<double> allbetCatchMoney() async {
  //   if (html == null) {
  //     String? html = await webViewController?.getHtml();
  //     if (html != null) {
  //       // Fimber.i("html = $html");
  //       // Fimber.i("str len = ${html.length}");
  //
  //       final double? dollar = await compute(allbetGetMoneyInIsolate, html);
  //       Fimber.i("dollar = $dollar");
  //       if (dollar != null) {
  //         snackBarController.showRecognizeResult("現在金額:$dollar", 1500);
  //         html = null;
  //         return dollar;
  //       } else {
  //         snackBarController.showRecognizeResult("讀取不到金額", 1500);
  //         html = null;
  //         return -1;
  //       }
  //     }
  //   }
  //   return -1;
  // }

  // Future<double> wmCatchMoney() async {
  //   if (html == null) {
  //     String? html = await webViewController?.getHtml();
  //     if (html != null) {
  //       final double? dollar = await compute(wmGetMoneyInIsolate, html);
  //       if (dollar != null) {
  //         snackBarController.showRecognizeResult("現在金額:$dollar", 1500);
  //         html = null;
  //         return dollar;
  //       } else {
  //         snackBarController.showRecognizeResult("讀取不到金額", 1500);
  //         html = null;
  //         return -1;
  //       }
  //     }
  //   }
  //   return -1;
  // }

  // Future<void> wmStartRoutineCheck() async {
  //   var timeCount = 449;
  //   while (isUIDetectorRunning) {
  //     timeCount += 1;
  //     if (timeCount == 450) {
  //       apiHandler.routineCheck();
  //       wmCatchMoney().then((value) async {
  //         if (value < 0) {
  //           _stopWmProcess();
  //           return;
  //         }
  //         Fimber.i("wmMoney = $wmMoney");
  //         Fimber.i("value = $value");
  //         fee += (value - wmMoney) / 10;
  //         final tempFee = await selfEncryptedSharedPreference.getFee();
  //         Fimber.i("Fee = $fee");
  //         if (tempFee != null) {
  //           double lastFee = double.parse(tempFee);
  //           Fimber.i("lastFee = $lastFee");
  //           fee += lastFee;
  //         }
  //         selfEncryptedSharedPreference.setFee(fee);
  //         Fimber.i("setFee = $fee");
  //         fee = 0;
  //         wmMoney = value;
  //         timeCount = 0;
  //       });
  //     }
  //     await Future.delayed(const Duration(seconds: 1));
  //   }
  // }

  void _stopWmProcess() {
    // apiHandler.isCalculatorRunning = 0;
    // apiHandler.routineCheck().then((value) {
    //   if (value == 0) {
    //     Fimber.i('routineCheck 2 returnMsg show');
    //     _showReturnMessageDialog(apiHandler.returnMsg);
    //   }
    //   apiHandler.returnMsg = "出錯了! 請聯繫客服";
    // });
    snackBarController.showRecognizeResult("停止辨識", 2000);
    stop();
  }

  void wmProcess() async {
    isShowProgress = true;
    cardDetectLock = false;
    setState(() {
      isUIDetectorRunning = !isUIDetectorRunning;
    });
    if (!isUIDetectorRunning) {
      // apiHandler.isCalculatorRunning = 0;
      // apiHandler.routineCheck();
      snackBarController.showRecognizeResult("停止辨識ui", 2000);
      stop();
    } else {
      // apiHandler.isCalculatorRunning = 1;
      // wmStartRoutineCheck();
      // startTimer();
      // apiHandler.routineCheck();
    }
    while (isUIDetectorRunning) {
      // if (apiHandler.code != 1) {
      //   _stopWmProcess();
      //   break;
      // }
      // Counter counter = Counter();
      // if (counter.count >= 7200) {
      //   selfEncryptedSharedPreference.getFee().then((value) async {
      //     if (value != null) {
      //       final feeInt = int.parse(value);
      //       if (feeInt >= 1000) {
      //         _stopWmProcess();
      //         bool ifDebtApiSuccess = await apiHandler.debtApi(feeInt);
      //         if(ifDebtApiSuccess){
      //           selfEncryptedSharedPreference.setFee(0.0);
      //         }
      //         return;
      //       } else if (feeInt <= 0) {
      //         counter.resetTimer();
      //         selfEncryptedSharedPreference.setFee(0.0);
      //       } else {
      //         counter.resetTimer();
      //       }
      //     }
      //   });
      // }

      if (isShowProgress) {
        snackBarController.showRecognizeResult("開始辨識ui!", 2000);
      }
      isShowProgress = false;

      if (!dataHandler.isBetting) {
        config.quality = 50;

        Fimber.i("take screen shot");

        Uint8List? data = await webViewController?.takeScreenshot(
            screenshotConfiguration: config);

        Fimber.i("screen shot finished");
        await webViewController?.getContentHeight().then((value) => {
              dataHandler.mobileWidth = MediaQuery.of(context).size.width,
              dataHandler.mobileHeight = MediaQuery.of(context).size.height,
              dataHandler.webViewHeight = value!.toDouble(),
            });

        if (data != null) {
          image.Image? imageData = await compute(decodeImage, data);

          if (imageData != null) {
            bool isLaunchCardDetector =
                await wmUiDetector.putImageIntoModel(imageData);
            // if (uiDetector.resultStr == "didn't find button") {
            //   ImageGallerySaver.saveImage(data, quality: 100);
            // } else if (uiDetector.resultStr == "button error") {
            //   // Fimber.i("resultStr = ${uiDetector.resultStr}");
            //   // debugPrint(uiDetector.resultStr);
            //   int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            //   String fileNameTime = time.toString();
            //   ImageGallerySaver.saveImage(data,
            //       quality: 100, name: uiDetector.errorStr + ",$fileNameTime}");
            //   uiDetector.errorStr = "";
            // } else {
            //   Fimber.i("resultStr = ${uiDetector.resultStr}");
            // }

            // if(mounted){
            //   dataHandler.playerButtonX =
            //       MediaQuery.of(context).size.width * wmUiDetector.playerButtonX;
            //   dataHandler.playerButtonY = MediaQuery.of(context).size.height -
            //       (dataHandler.webViewHeight * (1 - wmUiDetector.playerButtonY));
            //
            //   dataHandler.bankButtonX =
            //       MediaQuery.of(context).size.width * wmUiDetector.bankButtonX;
            //   dataHandler.bankButtonY = MediaQuery.of(context).size.height -
            //       (dataHandler.webViewHeight * (1 - wmUiDetector.bankButtonY));
            //
            //   dataHandler.confirmButtonX =
            //       MediaQuery.of(context).size.width * wmUiDetector.confirmButtonX;
            //   dataHandler.confirmButtonY = MediaQuery.of(context).size.height -
            //       (dataHandler.webViewHeight * (1 - wmUiDetector.confirmButtonY));
            // }




            int state = wmUiDetector.getCalculatorState();

            dataHandler.refreshState(state,webViewController!,casino!);
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

              dataHandler.checkWinOrLose(wmUiDetector.winSide);
              wmUiDetector.winSide = null;

              List value = await wmCardDetector.putImageIntoModel(imageData);
              String cardResult = wmCardDetector.resultStr;
              setState(() {
                dataHandler.insertCard(value);
              });
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


  // Future<void> allbetStartRoutineCheck() async {
  //   var timeCount = 449;
  //   while (isUIDetectorRunning) {
  //     timeCount += 1;
  //     if (timeCount == 450) {
  //       apiHandler.routineCheck();
  //       allbetCatchMoney().then((value) async {
  //         if (value < 0) {
  //           _stopAllbetProcess();
  //           return;
  //         }
  //         Fimber.i("allbetMoney = $allbetMoney");
  //         Fimber.i("value = $value");
  //         fee += (value - allbetMoney) / 10;
  //         final tempFee = await selfEncryptedSharedPreference.getFee();
  //         Fimber.i("Fee = $fee");
  //         if (tempFee != null) {
  //           double lastFee = double.parse(tempFee);
  //           Fimber.i("lastFee = $lastFee");
  //           fee += lastFee;
  //         }
  //         selfEncryptedSharedPreference.setFee(fee);
  //         Fimber.i("setFee = $fee");
  //         fee = 0;
  //         allbetMoney = value;
  //         timeCount = 0;
  //       });
  //     }
  //     await Future.delayed(const Duration(seconds: 1));
  //   }
  // }


  void _stopAllbetProcess() {
    // apiHandler.isCalculatorRunning = 0;
    // apiHandler.routineCheck().then((value) {
    //   if (value == 0) {
    //     Fimber.i('routineCheck 2 returnMsg show');
    //     _showReturnMessageDialog(apiHandler.returnMsg);
    //   }
    //   apiHandler.returnMsg = "出錯了! 請聯繫客服";
    // });

    snackBarController.showRecognizeResult("停止辨識", 2000);
    stop();
  }

  void allbetProcess() async {
    isShowProgress = true;
    cardDetectLock = false;
    setState(() {
      isUIDetectorRunning = !isUIDetectorRunning;
    });
    if (!isUIDetectorRunning) {
      // apiHandler.isCalculatorRunning = 0;
      // apiHandler.routineCheck();
      snackBarController.showRecognizeResult("停止辨識ui", 2000);
      stop();
    } else {
      // apiHandler.isCalculatorRunning = 1;
      // allbetStartRoutineCheck();
      // startTimer();
      // apiHandler.routineCheck();
    }
    while (isUIDetectorRunning) {
      // if (apiHandler.code != 1) {
      //   _stopAllbetProcess();
      //   break;
      // }
      // Counter counter = Counter();
      // if (counter.count >= 7200) {
      //   selfEncryptedSharedPreference.getFee().then((value) async {
      //     if (value != null) {
      //       final feeInt = int.parse(value);
      //       if (feeInt >= 1000) {
      //         _stopAllbetProcess();
      //         bool ifDebtApiSuccess = await apiHandler.debtApi(feeInt);
      //         if(ifDebtApiSuccess){
      //           selfEncryptedSharedPreference.setFee(0.0);
      //         }
      //         return;
      //       } else if (feeInt <= 0) {
      //         counter.resetTimer();
      //         selfEncryptedSharedPreference.setFee(0.0);
      //       } else {
      //         counter.resetTimer();
      //       }
      //     }
      //   });
      // }

      if (isShowProgress) {
        snackBarController.showRecognizeResult("開始辨識ui!", 2000);
      }
      isShowProgress = false;

      if (!dataHandler.isBetting) {
        config.quality = 50;

        Fimber.i("take screen shot");

        Uint8List? data = await webViewController?.takeScreenshot(
            screenshotConfiguration: config);

        Fimber.i("screen shot finished");

        await webViewController?.getContentHeight().then((value) => {
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

            dataHandler.refreshState(state,webViewController!,casino!);
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

              dataHandler.checkWinOrLose(allbetUiDetector.winSide);
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

  // Future<void> _showReturnMessageDialog(String message) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false, // user must tap button!
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(message),
  //         content: SingleChildScrollView(
  //           child: TextButton(
  //             onPressed: () {
  //               launchUrlString('https://line.me/ti/p/@516wvzjp');
  //             },
  //             child: const Text('點我加入官方line好友'),
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('確定'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Future<void> _displayTextInputDialog(BuildContext context) async {
  //   return showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           // title: const Text('TextField in Dialog'),
  //           content: TextField(
  //             onChanged: (value) {
  //               setState(() {
  //                 valueText = value;
  //               });
  //             },
  //             controller: _textFieldController,
  //             decoration: const InputDecoration(hintText: "輸入代碼"),
  //           ),
  //           actions: <Widget>[
  //             TextButton(
  //               child: const Text('取消'),
  //               onPressed: () {
  //                 setState(() {
  //                   Navigator.pop(context);
  //                 });
  //               },
  //             ),
  //             TextButton(
  //               child: const Text('確認'),
  //               onPressed: () {
  //                 setState(() {
  //                   apiHandler.userPassCode = valueText;
  //                   Navigator.pop(context);
  //                   apiHandler.checkServeState().then((value) {
  //                     if (apiHandler.code == 0) {
  //                       Fimber.i('checkServeState 3 returnMsg show');
  //                       _showReturnMessageDialog(apiHandler.returnMsg);
  //                     }
  //
  //                     if (value == "clear") {
  //
  //                       switch(casino){
  //                         case "WM":{
  //                           wmProcess();
  //                         }
  //                         break;
  //
  //                         case "ALLBET":{
  //                           allbetProcess();
  //                         }
  //                         break;
  //
  //                         default:{
  //                           snackBarController.showRecognizeResult("讀取不到場地", 1500);
  //                           Fimber.i('casino = null');
  //                         }
  //                         break;
  //                       }
  //                     }
  //                   });
  //                 });
  //               },
  //             ),
  //           ],
  //         );
  //       });
  // }
}
