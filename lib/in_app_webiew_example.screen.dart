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
import 'package:untitled/utils/api_handler.dart';
import 'package:untitled/utils/counter.dart';
import 'package:untitled/data_handler.dart';
import 'package:untitled/utils/isolate_function.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';
import 'package:untitled/utils/snackbar_controller.dart';
import 'package:untitled/detector/ui_detector.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:untitled/detector/card_detector.dart';
import 'package:image/image.dart' as image;
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

var _snackBarPresenting = false;

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({Key? key}) : super(key: key);

  @override
  _InAppWebViewExampleScreenState createState() =>
      _InAppWebViewExampleScreenState();
}

class _InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen>
    with WidgetsBindingObserver {
  final GlobalKey webViewKey = GlobalKey();
  Timer? timer;
  String? codeDialog;
  String? valueText;

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useOnLoadResource: true,
          javaScriptEnabled: true,
          useShouldInterceptAjaxRequest: true,
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
  String? imeiNo;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  CardDetector cardDetector = CardDetector();
  UIDetector uiDetector = UIDetector();
  DataHandler dataHandler = DataHandler();
  ApiHandler apiHandler = ApiHandler();

  final TextEditingController _textFieldController = TextEditingController();


  ScreenshotConfiguration config = ScreenshotConfiguration();
  late SnackBarController snackBarController;
  SelfEncryptedSharedPreference selfEncryptedSharedPreference = SelfEncryptedSharedPreference();

  bool isUIDetectorRunning = false;
  bool isShowProgress = true;
  bool cardDetectLock = false;
  String? html;


  double money = -1;
  double fee = 0;

  int paidTime = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
          child: WillPopScope(
            onWillPop: () async {
              if (_snackBarPresenting) {
                EasyLoading.show(status: '與伺服器同步狀態中...');
                await apiHandler.check2WhenCloseApp();
                // await apiHandler.debtApiWhenCloseApp();
                // EasyLoading.dismiss();
                return true;
              }
              _snackBarPresenting = true;
              var snackBar = const SnackBar(
                  content: Text('再次點擊back關閉app，若想在背景運行應用程式，請點擊home鍵'));
              ScaffoldMessenger.of(context)
                  .showSnackBar(snackBar)
                  .closed
                  .then((_) => _snackBarPresenting = false);
              return false;
            },
            child: Column(children: <Widget>[
              TextField(
                decoration:
                    const InputDecoration(prefixIcon: Icon(Icons.search)),
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
                          url:
                              Uri.parse("https://www.bl868.net/new_home2.php")),
                      // initialFile: "assets/index.html",
                      initialUserScripts: UnmodifiableListView<UserScript>([]),
                      initialOptions: options,
                      pullToRefreshController: pullToRefreshController,
                      onLoadResource: (controller, resource) {
                        // Fimber.i("onLoadResource");
                        // Fimber.i("resource.url = ${resource.url}");
                        if(resource.url.toString().contains("iframe_101")){

                          catchMoney().then((value) {
                            money = value.toDouble();
                            Fimber.i("value = $value");
                            Fimber.i('set money');
                            Fimber.i('money = $money');
                          });
                        }
                      },
                      onPageCommitVisible: (controller, url){
                        // Fimber.i("onPageCommitVisible");
                      },
                      onWindowFocus:(controller){
                        // Fimber.i("onWindowFocus");
                      },
                      onWindowBlur: (controller){
                        // Fimber.i("onWindowBlur");
                      },
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                        counter.initCount();
                      },
                      onLoadStart: (controller, url) {
                        // Fimber.i('onLoadStart');
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onAjaxProgress: (controller, ajaxRequest) async {
                        // Fimber.i('onAjaxProgress');
                        // Fimber.i('${ajaxRequest.status}');
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
                      // onAjaxReadyStateChange: (controller, ajaxRequest) async {
                      //   if (ajaxRequest.url.toString().contains('php')) {
                      //     final title = await controller.getTitle();
                      //     Fimber.i("AJAX DONE");
                      //     Fimber.i("title = $title");
                      //     catchMoney();
                      //   }
                      //   return AjaxRequestAction.PROCEED;
                      // },
                      onLoadStop: (controller, url) async {
                        // Fimber.i("onLoadStop");

                        // Fimber.i("url = ${url.toString()}");
                        // controller.getTitle().then((value) {
                        //   if (value == "WM") {
                        //     catchMoney().then((value) => money = value);
                        //   }
                        // });

                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onLoadError: (controller, url, code, message) {
                        pullToRefreshController.endRefreshing();
                      },
                      onProgressChanged: (controller, progress) {
                        // Fimber.i("onProgressChanged");
                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = url;
                        });
                      },

                      onTitleChanged: (controller, title) async {
                        // Fimber.i("onTitleChanged");
                        Fimber.i("title = $title");

                        // if(title=="WM"){
                        //   await controller.
                        //
                        // }

                        if (isUIDetectorRunning) {
                          apiHandler.isCalculatorRunning = 0;
                          apiHandler.routineCheck();
                          setState(() {
                            isUIDetectorRunning = false;
                          });
                          snackBarController.showRecognizeResult(
                              "偵測到網頁跳轉，停止辨識", 2000);
                          stopTimer();
                          dataHandler.reset();
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
                        html = null;
                        // Fimber.i('onConsoleMessage');
                        // Fimber.i("$consoleMessage");
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
                      height: MediaQuery.of(context).size.height * 0.83,
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
                            SizedBox(
                              height: 35,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Stack(
                                  children: [
                                    if (counter.count >= paidTime)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.blue),
                                        ),
                                      )
                                    else
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              color: Colors.grey),
                                        ),
                                      ),
                                    TextButton(
                                        onPressed: () {
                                          if (counter.count >= paidTime) {

                                            //do operation that calculate fee then call api to generate bills
                                            counter.resetTimer();
                                            selfEncryptedSharedPreference.saveRemainTime();
                                          }
                                        },
                                        child: const Text(
                                          "繳費",
                                          style: TextStyle(color: Colors.white),
                                        ))
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
                                        onPressed: () {
                                          setState(() {
                                            if (apiHandler.userPassCode !=
                                                null) {
                                              if (apiHandler.code == 1) {
                                                Fimber.i(
                                                    "code = ${apiHandler.code}");
                                                wmProcess();
                                              } else {
                                                Fimber.i(
                                                    "code = ${apiHandler.code}");
                                                apiHandler
                                                    .checkServeState()
                                                    .then((value) {
                                                  Fimber.i("value = $value");
                                                  if (value == "clear") {
                                                    wmProcess();
                                                  } else {
                                                    snackBarController
                                                        .showRecognizeResult(
                                                            apiHandler
                                                                .returnMsg,
                                                            3000);
                                                  }
                                                });
                                              }
                                            } else {
                                              _displayTextInputDialog(context);
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
                            ElevatedButton(
                              child: const Icon(Icons.refresh),
                              onPressed: () async {

                                // webViewController?.reload();
                              },
                            ),
                            ElevatedButton(
                              child: const Icon(Icons.not_started),
                              onPressed: () async {
                                apiHandler.routineCheck();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.topRight,
                        child:
                            // Text('使用時間剩餘:${(7200- counter.count)~/60}分鐘',
                            Text('使用時間剩餘:${(7200 - counter.count)}秒',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                    fontSize: 20.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        )));
  }

  void startTimer() {
    if (timer == null) {
      Fimber.i('Start Timer');
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          Provider.of<Counter>(context, listen: false).addCount();
        });
      });
    } else {
      Fimber.i('Stop Timer');
      timer?.cancel();
      timer = null;
    }
  }

  void stopTimer() {
    if (timer != null) {
      Fimber.i('Stop Timer');
      timer?.cancel();
      timer = null;
    }
  }

  void calculateFee() {}

  Future<double> catchMoney() async {
    if (html == null) {

      String? html = await webViewController?.getHtml();
      if(html!=null){
        final double? dollar = await compute(getMoneyInIsolate, html);
        if(dollar!=null){
          snackBarController.showRecognizeResult("現在金額:$dollar", 1500);
          html = null;
          return dollar;
        }else{
          snackBarController.showRecognizeResult("讀取不到金額", 1500);
          html = null;
          return -1;
        }
      }
    }
    return -1;
  }

  Future<void> startRoutineCheck() async {
    while (isUIDetectorRunning) {
      apiHandler.routineCheck();
      catchMoney().then((value) async {
        if(value <0){
          _stopWmProcess();
          return;
        }
        fee += (value - money) / 10;
        final tempFee = await selfEncryptedSharedPreference.getFee();
        Fimber.i("Fee = $fee");
        if(tempFee != null){
          double lastFee = double.parse(tempFee);
          Fimber.i("lastFee = $lastFee");
          fee += lastFee;
        }
        selfEncryptedSharedPreference.setFee(fee);
        Fimber.i("setFee = $fee");

        // if (!pref.containsKey('fee')) {
        //   encryptedSharedPreferences.setString('fee', fee.toString());
        // } else {
        //   Fimber.i("money = $money");
        //   // String tempFee = await encryptedSharedPreferences.getString('fee');
        //   Fimber.i(tempFee);
        //   // double lastFee = double.parse(await encryptedSharedPreferences.getString('fee'));
        //   Fimber.i("lastFee = $lastFee");
        //   fee += lastFee;
        //   encryptedSharedPreferences.remove('fee');
        //   encryptedSharedPreferences.setString('fee', fee.toString());
        //   Fimber.i("setFee = $fee");
        // }
      });


      await Future.delayed(const Duration(seconds: 600));
    }
  }

  void _stopWmProcess(){
    apiHandler.isCalculatorRunning = 0;
    apiHandler.routineCheck();
    setState(() {
      isUIDetectorRunning = false;
    });
    snackBarController.showRecognizeResult(
        "停止辨識", 2000);
    stopTimer();
    dataHandler.reset();
  }

  void wmProcess() async {
    isShowProgress = true;
    cardDetectLock = false;
    isUIDetectorRunning = !isUIDetectorRunning;
    if (!isUIDetectorRunning) {
      apiHandler.isCalculatorRunning = 0;
      apiHandler.routineCheck();
      snackBarController.showRecognizeResult("停止辨識ui", 2000);
      stopTimer();
      dataHandler.reset();
    } else {
      apiHandler.isCalculatorRunning = 1;
      startRoutineCheck();
      startTimer();
      // apiHandler.routineCheck();
    }
    while (isUIDetectorRunning) {
      if (apiHandler.code != 1) {
        _stopWmProcess();
        // apiHandler.isCalculatorRunning = 0;
        // apiHandler.routineCheck();
        // setState(() {
        //   isUIDetectorRunning = false;
        // });
        //
        // snackBarController.showRecognizeResult(
        //     "response_code !=1\n停止辨識ui", 2000);
        // stopTimer();
        // dataHandler.reset();
        break;
      }
      Counter counter = Counter();
      if (counter.count >= 7200) {
        _stopWmProcess();
        break;
      }

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
                await uiDetector.putImageIntoModel(imageData);

            dataHandler.playerButtonX =
                MediaQuery.of(context).size.width * uiDetector.playerButtonX;
            dataHandler.playerButtonY = MediaQuery.of(context).size.height -
                (dataHandler.webViewHeight * (1 - uiDetector.playerButtonY));

            dataHandler.bankButtonX =
                MediaQuery.of(context).size.width * uiDetector.bankButtonX;
            dataHandler.bankButtonY = MediaQuery.of(context).size.height -
                (dataHandler.webViewHeight * (1 - uiDetector.bankButtonY));

            dataHandler.confirmButtonX =
                MediaQuery.of(context).size.width * uiDetector.confirmButtonX;
            dataHandler.confirmButtonY = MediaQuery.of(context).size.height -
                (dataHandler.webViewHeight * (1 - uiDetector.confirmButtonY));
            int state = uiDetector.getCalculatorState();

            dataHandler.refreshState(state);
            if (state == 1 && cardDetectLock) {
              cardDetectLock = false;
            }

            if (isLaunchCardDetector && !cardDetectLock) {
              if (uiDetector.winSide == "bank") {
                snackBarController.showRecognizeResult("莊勝，開始辨識撲克牌", 1200);
              }
              if (uiDetector.winSide == "player") {
                snackBarController.showRecognizeResult("閒勝，開始辨識撲克牌", 1200);
              }
              if (uiDetector.winSide == "draw") {
                snackBarController.showRecognizeResult("和局，開始辨識撲克牌", 1200);
              }

              dataHandler.checkWinOrLose(uiDetector.winSide);
              uiDetector.winSide = null;

              List value = await cardDetector.putImageIntoModel(imageData);
              String cardResult = cardDetector.resultStr;
              dataHandler.insertCard(value);
              snackBarController.showRecognizeResult(cardResult, 2000);
              cardDetectLock = true;

              await ImageGallerySaver.saveImage(data, quality: 100);
            }
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 3500));
    }
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            // title: const Text('TextField in Dialog'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "輸入代碼"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                child: const Text('確認'),
                onPressed: () {
                  setState(() {
                    apiHandler.userPassCode = valueText;
                    Navigator.pop(context);
                    apiHandler.checkServeState().then((value) {
                      if (apiHandler.code == 0) {
                        snackBarController.showRecognizeResult(
                            apiHandler.returnMsg, 3000);
                      }

                      if (value == "clear") {
                        wmProcess();
                      }
                    });
                  });
                },
              ),
            ],
          );
        });
  }
}
