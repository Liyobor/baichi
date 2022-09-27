import 'dart:collection';
import 'dart:ffi';
// import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'dart:typed_data';
import 'package:fimber/fimber.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:untitled/converter.dart';
import 'package:untitled/ui_detector.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'card_detector.dart';
import 'package:image/image.dart' as image;



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

  ScreenshotConfiguration config = ScreenshotConfiguration();

  bool isUIDetectorRunning = false;








  @override
  void initState() {

    super.initState();
    config.compressFormat = CompressFormat.JPEG;


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
                // TextField(
                //   decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
                //   controller: urlController,
                //   keyboardType: TextInputType.url,
                //   onSubmitted: (value) {
                //     var url = Uri.parse(value);
                //     if (url.scheme.isEmpty) {
                //       url = Uri.parse("https://www.google.com/search?q=" + value);
                //     }
                //     webViewController?.loadUrl(urlRequest: URLRequest(url: url));
                //   },
                // ),
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

                          if(await Permission.storage.request().isGranted){

                            Uint8List? data = await webViewController?.takeScreenshot();
                            // Uint8List? croppedData;
                            if(data!=null){
                              debugPrint("save");
                              // Converter().convertUInt8List2Image(data).then((value) => image = value);
                              // await Converter().cropImage(data, 500, 500).then((value) async {
                              //   Fimber.i("croppedData = $croppedData");
                              //   croppedData = value;
                              // });

                              // if(croppedData!=null) {
                              //   await ImageGallerySaver.saveImage(croppedData!);
                              //   Fimber.i("croppedData!=null");
                              // }
                              await ImageGallerySaver.saveImage(data);
                              // await ImageGallerySaver.saveImage(Converter().cropImage(data));

                            }else{
                              debugPrint("data is null");
                            }
                          }

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
                                  bool isShowProgress = true;


                                  isUIDetectorRunning = !isUIDetectorRunning;
                                  if(!isUIDetectorRunning) {
                                    showRecognizeResult(context, "停止辨識ui", 2000);
                                  }
                                  while(isUIDetectorRunning){
                                    if(isShowProgress) {
                                      showRecognizeResult(
                                          context, "開始辨識ui!", 2000);
                                    }
                                    isShowProgress = false;
                                    var start = DateTime.now();
                                    config.quality = 50;
                                    Uint8List? data = await webViewController?.takeScreenshot(screenshotConfiguration: config);
                                    var end = DateTime.now();
                                    Fimber.i("time of take screen shot : ${end.difference(start).inMilliseconds/1000}s");
                                    // final ByteData bytes = await rootBundle.load('assets/images/img1.png');
                                    // final Uint8List data = bytes.buffer.asUint8List();

                                    Fimber.i("width = ${MediaQuery.of(context).size.width}");
                                    Fimber.i("height = ${MediaQuery.of(context).size.height}");
                                    webViewController?.getContentHeight().then((value) => Fimber.i("web view height = $value}"));


                                    //position =
                                    if(data!=null){
                                      // Fimber.i("data len = ${data.length}");
                                      start = DateTime.now();
                                      image.Image? imageData = image.decodeImage(data);
                                      end = DateTime.now();
                                      Fimber.i("time of decodeImage : ${end.difference(start).inMilliseconds/1000}s");
                                      if(imageData!=null){
                                        // Fimber.i("len = ${imageData.length}");
                                        start = DateTime.now();
                                        String resultStr = uiDetector.putImageIntoModel(imageData);
                                        end = DateTime.now();
                                        Fimber.i("time of putImageIntoModel : ${end.difference(start).inMilliseconds/1000}s");
                                        showRecognizeResult(context, resultStr,2000);
                                      }
                                      // detector.putImageIntoModel(image.decodeImage(data));


                                      // Fimber.i("height = ${Converter().convertUInt8List2Image(data).height}");
                                      // Fimber.i("width = ${Converter().convertUInt8List2Image(data).width}");
                                    }
                                    await Future.delayed(const Duration(seconds: 5));
                                  }


                              // webViewController?.reload();
                                },
                              ),
                              ElevatedButton(
                                child: const Icon(Icons.not_started),
                                onPressed: () async {
                                  var start = DateTime.now();

                                  config.quality = 30;
                                  Uint8List? data = await webViewController?.takeScreenshot(screenshotConfiguration: config);
                                  var end = DateTime.now();
                                  Fimber.i("time of take screen shot : ${end.difference(start).inMilliseconds/1000}s");
                                  // final ByteData bytes = await rootBundle.load('assets/images/img1.png');
                                  // final Uint8List data = bytes.buffer.asUint8List();
                                  Fimber.i("web view height = ${webViewController?.getContentHeight()}");

                                  Fimber.i("width = ${MediaQuery.of(context).size.width}");
                                  Fimber.i("height = ${MediaQuery.of(context).size.height}");

                                  if(data!=null){
                                    Fimber.i("data len = ${data.length}");
                                    start = DateTime.now();
                                    image.Image? imageData = image.decodeImage(data);
                                    end = DateTime.now();
                                    Fimber.i("time of decodeImage : ${end.difference(start).inMilliseconds/1000}s");
                                    if(imageData!=null){
                                      Fimber.i("len = ${imageData.length}");
                                      start = DateTime.now();
                                      String resultStr = cardDetector.putImageIntoModel(imageData);
                                      end = DateTime.now();
                                      Fimber.i("time of putImageIntoModel : ${end.difference(start).inMilliseconds/1000}s");
                                      showRecognizeResult(context, resultStr,3500);
                                    }
                                    // detector.putImageIntoModel(image.decodeImage(data));


                                    // Fimber.i("height = ${Converter().convertUInt8List2Image(data).height}");
                                    // Fimber.i("width = ${Converter().convertUInt8List2Image(data).width}");
                                  }


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
  void showRecognizeResult(BuildContext context,String text,int milliseconds) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: Duration(milliseconds: milliseconds),
        action: SnackBarAction(label: '關閉', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }


}

