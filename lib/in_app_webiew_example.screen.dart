import 'dart:async';
import 'dart:collection';
// import 'dart:convert';
import 'dart:io';

// import 'dart:typed_data';
import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:untitled/utils/counter.dart';
import 'package:untitled/data_handler.dart';
import 'package:untitled/utils/isolate_function.dart';
import 'package:untitled/utils/snackbar_controller.dart';
import 'package:untitled/detector/ui_detector.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:untitled/detector/card_detector.dart';
import 'package:image/image.dart' as image;
import 'package:provider/provider.dart';

Future<Uint8List?> takeScreenShot(List config) async {
  return null;

  // var id = (Platform.isAndroid) ? contextMenuItemClicked.androidId : contextMenuItemClicked.iosId;

  // InAppWebViewController webViewController = config[0];
  // final screenshotConfiguration = config[1];
  // return await webViewController.takeScreenshot(screenshotConfiguration: screenshotConfiguration);
}

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({Key? key}) : super(key: key);

  @override
  _InAppWebViewExampleScreenState createState() =>
      _InAppWebViewExampleScreenState();
}

class _InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen> {
  final GlobalKey webViewKey = GlobalKey();
  Timer? timer;

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
  DataHandler dataHandler = DataHandler();

  ScreenshotConfiguration config = ScreenshotConfiguration();
  late SnackBarController snackBarController;

  bool isUIDetectorRunning = false;
  bool isShowProgress = true;
  bool cardDetectLock = false;
  String? html;

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
                Fimber.i("Menu item Special clicked!");
                // Fimber.i(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        options: ContextMenuOptions(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          Fimber.i("onCreateContextMenu");
          Fimber.i("${hitTestResult.extra}");
          Fimber.i("${await webViewController?.getSelectedText()}");
        },
        onHideContextMenu: () {
          Fimber.i("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = (Platform.isAndroid)
              ? contextMenuItemClicked.androidId
              : contextMenuItemClicked.iosId;
          Fimber.i("onContextMenuActionItemClicked: " +
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
                    initialUrlRequest: URLRequest(
                        url: Uri.parse("https://www.bl868.net/new_home2.php")),
                    // initialFile: "assets/index.html",
                    initialUserScripts: UnmodifiableListView<UserScript>([]),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      Fimber.i('onWebViewCreated');
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      Fimber.i('onLoadStart');
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onAjaxProgress: (controller, ajaxRequest) async {
                      Fimber.i('onAjaxProgress');
                      Fimber.i('${ajaxRequest.status}');
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
                          await launchUrlString(url);

                          // and cancel the request
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      Fimber.i("finished");
                      // Fimber.i("width = ${MediaQuery.of(context).size.width}");
                      // Fimber.i("height = ${MediaQuery.of(context).size.height}");
                      Fimber.i("url = ${url.toString()}");
                      // if(url.toString() == "https://www.bl868.net/mobile/"){

                      // GestureBinding taper = GestureBinding.instance;
                      // await Future.delayed(const Duration(milliseconds: 1000));
                      // Fimber.i("tap");
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
                      Fimber.i("onProgressChanged");
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = url;
                      });
                    },

                    onTitleChanged: (controller, title) {
                      Fimber.i("onTitleChanged");
                      Fimber.i("$title");
                    },
                    onCloseWindow: (controller) {
                      Fimber.i('onCloseWindow');
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      html = null;
                      Fimber.i('onConsoleMessage');
                      Fimber.i("$consoleMessage");
                    },
                    onCreateWindow: (controller, createWindowRequest) async {
                      Fimber.i("onCreateWindow");
                      return null;
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: Align(
                      alignment: Alignment.bottomCenter,
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
                              if (!isUIDetectorRunning) {
                                snackBarController.showRecognizeResult(
                                    "停止辨識ui", 2000);
                                dataHandler.reset();
                              }

                              // final port = ReceivePort();
                              // final message = await port.first as List;

                              while (isUIDetectorRunning) {
                                if (isShowProgress) {
                                  snackBarController.showRecognizeResult(
                                      "開始辨識ui!", 2000);
                                }
                                isShowProgress = false;

                                if (!dataHandler.isBetting) {
                                  // var start = DateTime.now();
                                  config.quality = 50;

                                  // final setting = [webViewController.,config];
                                  // final data = await compute(takeScreenShot,setting);
                                  Uint8List? data =
                                      await webViewController?.takeScreenshot(
                                          screenshotConfiguration: config);

                                  // var end = DateTime.now();
                                  // Fimber.i("time of take screen shot : ${end.difference(start).inMilliseconds/1000}s");
                                  // final ByteData bytes = await rootBundle.load('assets/images/img1.png');
                                  // final Uint8List data = bytes.buffer.asUint8List();

                                  // Fimber.i("width = ${MediaQuery.of(context).size.width}");
                                  // Fimber.i("height = ${MediaQuery.of(context).size.height}");
                                  await webViewController
                                      ?.getContentHeight()
                                      .then((value) => {
                                            dataHandler.mobileWidth =
                                                MediaQuery.of(context)
                                                    .size
                                                    .width,
                                            dataHandler.mobileHeight =
                                                MediaQuery.of(context)
                                                    .size
                                                    .height,
                                            dataHandler.webViewHeight =
                                                value!.toDouble(),
                                          });

                                  //position =
                                  if (data != null) {
                                    // final result = await ImageGallerySaver.saveImage(data,quality: 100);

                                    // Fimber.i("result  = $result");
                                    // start = DateTime.now();

                                    // image.Image? imageData = image.decodeImage(data);

                                    image.Image? imageData =
                                        await compute(decodeImage, data);
                                    // end = DateTime.now();
                                    // Fimber.i("time of decodeImage : ${end.difference(start).inMilliseconds/1000}s");
                                    if (imageData != null) {
                                      // Fimber.i("len = ${imageData.length}");
                                      // start = DateTime.now();

                                      bool isLaunchCardDetector =
                                          await uiDetector
                                              .putImageIntoModel(imageData);

                                      // String resultStr = uiDetector.resultStr;
                                      dataHandler.playerButtonX =
                                          MediaQuery.of(context).size.width *
                                              uiDetector.playerButtonX;
                                      dataHandler.playerButtonY =
                                          MediaQuery.of(context).size.height -
                                              (dataHandler.webViewHeight *
                                                  (1 -
                                                      uiDetector
                                                          .playerButtonY));

                                      // playerButtonX = uiDetector.playerButtonX;
                                      // playerButtonY = uiDetector.playerButtonY;

                                      dataHandler.bankButtonX =
                                          MediaQuery.of(context).size.width *
                                              uiDetector.bankButtonX;
                                      dataHandler.bankButtonY =
                                          MediaQuery.of(context).size.height -
                                              (dataHandler.webViewHeight *
                                                  (1 - uiDetector.bankButtonY));

                                      // bankButtonX = uiDetector.bankButtonX;
                                      // bankButtonY = uiDetector.bankButtonY;

                                      dataHandler.confirmButtonX =
                                          MediaQuery.of(context).size.width *
                                              uiDetector.confirmButtonX;
                                      dataHandler.confirmButtonY =
                                          MediaQuery.of(context).size.height -
                                              (dataHandler.webViewHeight *
                                                  (1 -
                                                      uiDetector
                                                          .confirmButtonY));

                                      // cardCalculator.confirmButtonX = uiDetector.confirmButtonX;
                                      // cardCalculator.confirmButtonY = uiDetector.confirmButtonY;

                                      // if(cardCalculator.playerButtonY<0 || cardCalculator.playerButtonX<0){
                                      //   cardCalculator.playerButtonX = uiDetector.playerButtonX;
                                      //   cardCalculator.playerButtonY = uiDetector.playerButtonY;
                                      // }else if(cardCalculator.bankButtonX<0 || cardCalculator.bankButtonY<0){
                                      //   cardCalculator.bankButtonX = uiDetector.bankButtonX;
                                      //   cardCalculator.bankButtonY = uiDetector.bankButtonY;
                                      // }

                                      // end = DateTime.now();
                                      // Fimber.i("time of putImageIntoModel : ${end.difference(start).inMilliseconds/1000}s");
                                      int state =
                                          uiDetector.getCalculatorState();
                                      // Fimber.i("state = $state");
                                      dataHandler.refreshState(state);
                                      if (state == 1 && cardDetectLock) {
                                        cardDetectLock = false;
                                      }

                                      // snackBarController.showRecognizeResult(resultStr, 2000);

                                      if (isLaunchCardDetector &&
                                          !cardDetectLock) {
                                        if (uiDetector.winSide == "bank") {
                                          snackBarController
                                              .showRecognizeResult(
                                                  "莊勝，開始辨識撲克牌", 1200);
                                        }
                                        if (uiDetector.winSide == "player") {
                                          snackBarController
                                              .showRecognizeResult(
                                                  "閒勝，開始辨識撲克牌", 1200);
                                        }
                                        if (uiDetector.winSide == "draw") {
                                          snackBarController
                                              .showRecognizeResult(
                                                  "和局，開始辨識撲克牌", 1200);
                                        }

                                        dataHandler
                                            .checkWinOrLose(uiDetector.winSide);
                                        uiDetector.winSide = null;

                                        List value = await cardDetector
                                            .putImageIntoModel(imageData);
                                        String cardResult =
                                            cardDetector.resultStr;
                                        dataHandler.insertCard(value);
                                        snackBarController.showRecognizeResult(
                                            cardResult, 2000);
                                        cardDetectLock = true;

                                        await ImageGallerySaver.saveImage(data,
                                            quality: 100);

                                        // String cardResult = cardDetector.resultStr;
                                        // cardCalculator.insertCard(results);
                                        // // await Future.delayed(const Duration(milliseconds: 1500));
                                        // snackBarController.showRecognizeResult(cardResult, 2000);
                                        // cardDetectLock = true;

                                      }
                                    }
                                    // detector.putImageIntoModel(image.decodeImage(data));

                                    // Fimber.i("height = ${Converter().convertUInt8List2Image(data).height}");
                                    // Fimber.i("width = ${Converter().convertUInt8List2Image(data).width}");
                                  }
                                }
                                await Future.delayed(
                                    const Duration(milliseconds: 3500));
                              }

                              // webViewController?.reload();
                            },
                          ),
                          ElevatedButton(
                            child: const Icon(Icons.not_started),
                            onPressed: () async {
                              if (html == null) {
                                webViewController
                                    ?.getHtml()
                                    .then((value) async {
                                  // html = value;
                                  if (value != null) {
                                    final double? dollar =
                                        await compute(getMoneyInIsolate, value);
                                    if (dollar != null) {
                                      dataHandler.dollar = dollar;
                                      snackBarController.showRecognizeResult(
                                          "現在金額:$dollar", 1500);
                                    } else {
                                      snackBarController.showRecognizeResult(
                                          "讀取不到金額", 1500);
                                    }
                                  }
                                });
                              }

                              if (timer == null) {
                                Fimber.i('Start Timer');
                                timer = Timer.periodic(
                                    const Duration(seconds: 1), (_) {
                                  setState(() {
                                    Provider.of<Counter>(context, listen: false)
                                        .addCount();
                                  });
                                });
                              } else {
                                Fimber.i('Stop Timer');
                                timer?.cancel();
                                timer = null;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text('時間剩餘:xx - ${counter.count}秒',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 20.0)),
                      ),
                      const Align(
                        alignment: Alignment.topRight,
                        child: Text('服務費:xx',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 20.0)),
                      ),
                    ],

                  ),
                ],
              ),
            ),
          ]),
        )));
  }
}
