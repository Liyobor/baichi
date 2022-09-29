import 'dart:collection';
import 'dart:ffi';
// import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

// import 'dart:typed_data';
import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:untitled/card_calculator.dart';
import 'package:untitled/converter.dart';
import 'package:untitled/main.dart';
import 'package:untitled/snackbar_controller.dart';
import 'package:untitled/ui_detector.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'card_detector.dart';
import 'package:image/image.dart' as image;

Future<void> isolateFun(SendPort p) async {
  Fimber.clearAll();
  Fimber.plantTree(DebugTree());
  Fimber.i("zzz8787");

  final port =ReceivePort();
  p.send(port.sendPort);
  final message = await port.first as List;
  final str = message[0] as UIDetector;
  // final uiDetector = message[1];
  final send = message[1] as SendPort;
  send.send("QQ MENTAL");
  // Isolate.exit(p,"zzz");
}

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({Key? key}) : super(key: key);


  @override
  _InAppWebViewExampleScreenState createState() =>
      _InAppWebViewExampleScreenState();
}

class _InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen> {
  final GlobalKey webViewKey = GlobalKey();






  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  CardDetector cardDetector = CardDetector();
  UIDetector uiDetector = UIDetector();
  CardCalculator cardCalculator = CardCalculator();

  ScreenshotConfiguration config = ScreenshotConfiguration();
  late SnackBarController snackBarController;

  bool isUIDetectorRunning = false;
  bool isShowProgress = true;
  bool cardDetectLock = false;




  @override
  void initState() {


    super.initState();

    config.compressFormat = CompressFormat.JPEG;
    snackBarController = SnackBarController(context: context);


    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              androidId: 1,
              iosId: "1",
              title: "Special",
              action: () async {
                debugPrint("Menu item Special clicked!");
                // debugPrint(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        options: ContextMenuOptions(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          debugPrint("onCreateContextMenu");
          debugPrint(hitTestResult.extra);
          debugPrint(await webViewController?.getSelectedText());
        },
        onHideContextMenu: () {
          debugPrint("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = (Platform.isAndroid)
              ? contextMenuItemClicked.androidId
              : contextMenuItemClicked.iosId;
          debugPrint("onContextMenuActionItemClicked: " +
              id.toString() +
              " " +
              contextMenuItemClicked.title);
        });

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        // appBar: AppBar(title: const Text("InAppWebView")),
        // drawer: myDrawer(context: context),
        body: SafeArea(
            child: GestureDetector(
              onTapDown: (details){
                debugPrint("${details.globalPosition}");
              },
              child: Column(children: <Widget>[
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  onSubmitted: (value) {
                    var url = Uri.parse(value);
                    if (url.scheme.isEmpty) {
                      url = Uri.parse("https://www.google.com/search?q=" + value);
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
                        initialUrlRequest:
                        URLRequest(url: Uri.parse("https://www.bl868.net/new_home2.php")),
                        // initialFile: "assets/index.html",
                        initialUserScripts: UnmodifiableListView<UserScript>([]),
                        initialOptions: options,
                        pullToRefreshController: pullToRefreshController,
                        onWebViewCreated: (controller) {
                          debugPrint('onWebViewCreated');
                          webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          debugPrint('onLoadStart');
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onAjaxProgress: (controller,ajaxRequest)async{
                          debugPrint('onAjaxProgress');
                          debugPrint('${ajaxRequest.status}');
                          return AjaxRequestAction.PROCEED;

                        },
                        androidOnPermissionRequest:
                            (controller, origin, resources) async {
                          return PermissionRequestResponse(
                              resources: resources,
                              action: PermissionRequestResponseAction.GRANT);
                        },
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
                              await launchUrlString(
                                  url
                              );

                              // and cancel the request
                              return NavigationActionPolicy.CANCEL;
                            }
                          }

                          return NavigationActionPolicy.ALLOW;
                        },
                        onLoadStop: (controller, url) async {


                          debugPrint("finished");
                          // debugPrint("width = ${MediaQuery.of(context).size.width}");
                          // debugPrint("height = ${MediaQuery.of(context).size.height}");
                          debugPrint("url = ${url.toString()}");
                          // if(url.toString() == "https://www.bl868.net/mobile/"){



                            // GestureBinding taper = GestureBinding.instance;
                            // await Future.delayed(const Duration(milliseconds: 1000));
                            // debugPrint("tap");
                            // taper.handlePointerEvent(const PointerDownEvent(
                            //   position: Offset(285.4, 425.7),
                            // ));
                            // await Future.delayed(const Duration(milliseconds: 300));
                            // taper.handlePointerEvent(const PointerUpEvent(
                            //   position: Offset(285.4, 425.7),
                            // ));
                          // }

                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onLoadError: (controller, url, code, message) {


                          pullToRefreshController.endRefreshing();
                        },
                        onProgressChanged: (controller, progress) {
                          debugPrint("onProgressChanged");
                          if (progress == 100) {
                            pullToRefreshController.endRefreshing();

                          }
                          setState(() {
                            this.progress = progress / 100;
                            urlController.text = url;
                          });
                        },

                        onTitleChanged: (controller,title){
                          debugPrint("onTitleChanged");
                          debugPrint("$title");
                        },
                        onCloseWindow: (controller){
                          debugPrint('onCloseWindow');
                        },
                        onUpdateVisitedHistory: (controller, url, androidIsReload) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          debugPrint('onConsoleMessage');
                          debugPrint("$consoleMessage");
                        },
                        onCreateWindow: (controller, createWindowRequest) async {
                          debugPrint("onCreateWindow");
                          return null;
                        },
                      ),
                      progress < 1.0
                          ? LinearProgressIndicator(value: progress)
                          : Container(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height*0.9,
                        child: Align(
                          alignment:Alignment.bottomCenter,

                          child: ButtonBar(

                            alignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  webViewController?.goBack();
                                },
                              ),
                              ElevatedButton(
                                child: const Icon(Icons.refresh),
                                onPressed: () async {



                                  isShowProgress = true;
                                  cardDetectLock = false;

                                  isUIDetectorRunning = !isUIDetectorRunning;
                                  if(!isUIDetectorRunning) {
                                    snackBarController.showRecognizeResult("停止辨識ui", 2000);
                                    cardCalculator.reset();
                                  }





                                  // final port = ReceivePort();
                                  // final message = await port.first as List;





                                  while(isUIDetectorRunning){
                                    if(isShowProgress) {
                                      snackBarController.showRecognizeResult(
                                          "開始辨識ui!", 2000);
                                    }
                                    isShowProgress = false;

                                    if(!cardCalculator.isBetting){
                                      var start = DateTime.now();
                                      config.quality = 50;


                                      Uint8List? data = await webViewController?.takeScreenshot(screenshotConfiguration: config);

                                      var end = DateTime.now();
                                      // Fimber.i("time of take screen shot : ${end.difference(start).inMilliseconds/1000}s");
                                      // final ByteData bytes = await rootBundle.load('assets/images/img1.png');
                                      // final Uint8List data = bytes.buffer.asUint8List();


                                      // Fimber.i("width = ${MediaQuery.of(context).size.width}");
                                      // Fimber.i("height = ${MediaQuery.of(context).size.height}");
                                      await webViewController?.getContentHeight().then((value) => {
                                        cardCalculator.mobileWidth = MediaQuery.of(context).size.width,
                                        cardCalculator.mobileHeight = MediaQuery.of(context).size.height,
                                        cardCalculator.webViewHeight = value!.toDouble(),
                                      });


                                      //position =
                                      if(data!=null){


                                        // final result = await ImageGallerySaver.saveImage(data,quality: 100);

                                        // Fimber.i("result  = $result");
                                        start = DateTime.now();
                                        image.Image? imageData = image.decodeImage(data);
                                        end = DateTime.now();
                                        // Fimber.i("time of decodeImage : ${end.difference(start).inMilliseconds/1000}s");
                                        if(imageData!=null){
                                          // Fimber.i("len = ${imageData.length}");
                                          start = DateTime.now();


                                          bool isLaunchCardDetector = uiDetector.putImageIntoModel(imageData);
                                          String resultStr = uiDetector.resultStr;
                                          cardCalculator.playerButtonX = MediaQuery.of(context).size.width * uiDetector.playerButtonX;
                                          cardCalculator.playerButtonY = MediaQuery.of(context).size.height - (cardCalculator.webViewHeight*(1-uiDetector.playerButtonY));

                                          // playerButtonX = uiDetector.playerButtonX;
                                          // playerButtonY = uiDetector.playerButtonY;

                                          cardCalculator.bankButtonX = MediaQuery.of(context).size.width * uiDetector.bankButtonX;
                                          cardCalculator.bankButtonY = MediaQuery.of(context).size.height - (cardCalculator.webViewHeight*(1-uiDetector.bankButtonY));

                                          // bankButtonX = uiDetector.bankButtonX;
                                          // bankButtonY = uiDetector.bankButtonY;

                                          cardCalculator.confirmButtonX = MediaQuery.of(context).size.width * uiDetector.confirmButtonX;
                                          cardCalculator.confirmButtonY =  MediaQuery.of(context).size.height - (cardCalculator.webViewHeight*(1-uiDetector.confirmButtonY));

                                          // cardCalculator.confirmButtonX = uiDetector.confirmButtonX;
                                          // cardCalculator.confirmButtonY = uiDetector.confirmButtonY;



                                          // if(cardCalculator.playerButtonY<0 || cardCalculator.playerButtonX<0){
                                          //   cardCalculator.playerButtonX = uiDetector.playerButtonX;
                                          //   cardCalculator.playerButtonY = uiDetector.playerButtonY;
                                          // }else if(cardCalculator.bankButtonX<0 || cardCalculator.bankButtonY<0){
                                          //   cardCalculator.bankButtonX = uiDetector.bankButtonX;
                                          //   cardCalculator.bankButtonY = uiDetector.bankButtonY;
                                          // }

                                          end = DateTime.now();
                                          // Fimber.i("time of putImageIntoModel : ${end.difference(start).inMilliseconds/1000}s");
                                          int state = uiDetector.getCalculatorState();
                                          // Fimber.i("state = $state");
                                          cardCalculator.refreshState(state);
                                          if(state == 1 && cardDetectLock){
                                            cardDetectLock = false;
                                          }

                                          // snackBarController.showRecognizeResult(resultStr, 2000);

                                          if(isLaunchCardDetector && !cardDetectLock){
                                            if(uiDetector.winSide == "bank"){
                                              snackBarController.showRecognizeResult("莊勝，開始辨識撲克牌", 1200);
                                            }
                                            if(uiDetector.winSide == "player"){
                                              snackBarController.showRecognizeResult("閒勝，開始辨識撲克牌", 1200);
                                            }
                                            if(uiDetector.winSide == "draw"){
                                              snackBarController.showRecognizeResult("和局，開始辨識撲克牌", 1200);
                                            }

                                            cardCalculator.checkWinOrLose(uiDetector.winSide);
                                            uiDetector.winSide = null;


                                            List results = cardDetector.putImageIntoModel(imageData);
                                            String cardResult = cardDetector.resultStr;
                                            cardCalculator.insertCard(results);
                                            // await Future.delayed(const Duration(milliseconds: 1500));
                                            snackBarController.showRecognizeResult(cardResult, 2000);
                                            cardDetectLock = true;


                                          }

                                        }
                                        // detector.putImageIntoModel(image.decodeImage(data));

                                        // Fimber.i("height = ${Converter().convertUInt8List2Image(data).height}");
                                        // Fimber.i("width = ${Converter().convertUInt8List2Image(data).width}");
                                      }
                                    }
                                    await Future.delayed(const Duration(milliseconds: 3500));
                                  }









                              // webViewController?.reload();
                                },
                              ),
                              ElevatedButton(
                                child: const Icon(Icons.not_started),
                                onPressed: () async {


                                  // final p = ReceivePort();
                                  // await Isolate.spawn(isolateFun,p.sendPort);
                                  // final sendPort = await p.first as SendPort;
                                  // final answer = ReceivePort();
                                  // sendPort.send([uiDetector,answer.sendPort]);
                                  // Fimber.i(await answer.first);

                                  await Future.delayed(const Duration(milliseconds: 1000));
                                  betBank();
                                  bettingConfirm();


                                  // var start = DateTime.now();
                                  //
                                  // config.quality = 30;
                                  // Uint8List? data = await webViewController?.takeScreenshot(screenshotConfiguration: config);
                                  // var end = DateTime.now();
                                  // Fimber.i("time of take screen shot : ${end.difference(start).inMilliseconds/1000}s");
                                  // // final ByteData bytes = await rootBundle.load('assets/images/img1.png');
                                  // // final Uint8List data = bytes.buffer.asUint8List();
                                  // Fimber.i("web view height = ${webViewController?.getContentHeight()}");
                                  //
                                  // Fimber.i("width = ${MediaQuery.of(context).size.width}");
                                  // Fimber.i("height = ${MediaQuery.of(context).size.height}");
                                  //
                                  // if(data!=null){
                                  //   Fimber.i("data len = ${data.length}");
                                  //   start = DateTime.now();
                                  //   image.Image? imageData = image.decodeImage(data);
                                  //   end = DateTime.now();
                                  //   Fimber.i("time of decodeImage : ${end.difference(start).inMilliseconds/1000}s");
                                  //   if(imageData!=null){
                                  //     Fimber.i("len = ${imageData.length}");
                                  //     start = DateTime.now();
                                  //     String resultStr = cardDetector.putImageIntoModel(imageData);
                                  //     end = DateTime.now();
                                  //     Fimber.i("time of putImageIntoModel : ${end.difference(start).inMilliseconds/1000}s");
                                  //     showRecognizeResult(context, resultStr,3500);
                                  //   }
                                  //   // detector.putImageIntoModel(image.decodeImage(data));
                                  //
                                  //
                                  //   // Fimber.i("height = ${Converter().convertUInt8List2Image(data).height}");
                                  //   // Fimber.i("width = ${Converter().convertUInt8List2Image(data).width}");
                                  // }


                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ]),
            )));
  }


  GestureBinding taper = GestureBinding.instance;
  double playerButtonX = -1.0;
  double playerButtonY = -1.0;
  double bankButtonX = -1.0;
  double bankButtonY = -1.0;
  double confirmButtonX = -1.0;
  double confirmButtonY = -1.0;

  Future<void> betBank() async {
    Fimber.i("betBank");
    Fimber.i("x = $bankButtonX, y = $bankButtonY}");
    await Future.delayed(const Duration(milliseconds: 500));
    taper.handlePointerEvent(PointerDownEvent(
      position: Offset(bankButtonX, bankButtonY),
    ));
    await Future.delayed(const Duration(milliseconds: 800));
    taper.handlePointerEvent(PointerUpEvent(
      position: Offset(bankButtonX, bankButtonY),
    ));

  }

  Future<void> betPlayer() async {
    Fimber.i("betPlayer");

    taper.handlePointerEvent(PointerDownEvent(
      position: Offset(playerButtonX, playerButtonY),
    ));
    await Future.delayed(const Duration(milliseconds: 800));
    taper.handlePointerEvent( PointerUpEvent(
      position: Offset(playerButtonX, playerButtonY),
    ));
  }

  Future<void> bettingConfirm() async {
    Fimber.i("bettingConfirm");

    taper.handlePointerEvent(PointerDownEvent(
      position: Offset(confirmButtonX, confirmButtonY),
    ));
    await Future.delayed(const Duration(milliseconds: 800));
    taper.handlePointerEvent(PointerUpEvent(
      position: Offset(confirmButtonX, confirmButtonY),
    ));
  }



  // Future<Uint8List?>? getScreenShot() async {
  //   Uint8List? data = await webViewController?.takeScreenshot(screenshotConfiguration: config);
  //   return data;
  // }











  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



}

