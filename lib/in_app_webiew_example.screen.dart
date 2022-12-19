import 'dart:collection';
// import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:untitled/custom_Button.dart';
import 'package:untitled/logic.dart';
import 'package:untitled/utils/api_handler.dart';
import 'package:untitled/data_handler.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';
import 'package:untitled/utils/snackbar_controller.dart';

import 'package:url_launcher/url_launcher_string.dart';

import 'package:provider/provider.dart';

import 'allbet_detector/card_detector.dart';
import 'allbet_detector/ui_detector.dart';
import 'wm_detector/card_detector.dart';
import 'wm_detector/ui_detector.dart';

class InAppWebViewExampleScreen extends StatefulWidget {
  const InAppWebViewExampleScreen({Key? key}) : super(key: key);

  @override
  State<InAppWebViewExampleScreen> createState() =>
      _InAppWebViewExampleScreenState();
}

class _InAppWebViewExampleScreenState extends State<InAppWebViewExampleScreen>
    with WidgetsBindingObserver {
  final GlobalKey webViewKey = GlobalKey();


  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    useOnLoadResource: true,
    javaScriptEnabled: true,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
  );

  late PullToRefreshController pullToRefreshController;
  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  ApiHandler apiHandler = ApiHandler();

  ScreenshotConfiguration config = ScreenshotConfiguration();
  Logic logic = Logic();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    config.compressFormat = CompressFormat.JPEG;

    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              id: 1,
              title: "Special",
              action: () async {
                Fimber.i("Menu item Special clicked!");

                await webViewController?.clearFocus();
              })
        ],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),

        onCreateContextMenu: (hitTestResult) async {
          Fimber.i("onCreateContextMenu");

        },
        onHideContextMenu: () {
          Fimber.i("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = (Platform.isAndroid)
              ? contextMenuItemClicked.id
              : contextMenuItemClicked.id.toString();
          Fimber.i(
              "onContextMenuActionItemClicked: $id ${contextMenuItemClicked.title}");
        });

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.blue),

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
    Provider.of<DataHandler>(context);

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
            // TextField(
            //   decoration:
            //       const InputDecoration(prefixIcon: Icon(Icons.search)),
            //   controller: urlController,
            //   keyboardType: TextInputType.url,
            //   onSubmitted: (value) {
            //     var url = WebUri(value);
            //     if (url.scheme.isEmpty) {
            //       url = WebUri("https://www.google.com/search?q=$value");
            //     }
            //     webViewController?.loadUrl(urlRequest: URLRequest(url: url));
            //   },
            // ),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,

                    initialUrlRequest:
                        URLRequest(url: WebUri(apiHandler.defaultUrl)),

                    initialUserScripts: UnmodifiableListView<UserScript>([]),
                    initialSettings: settings,
                    pullToRefreshController: pullToRefreshController,
                    onLoadResource: (controller, resource) {
                      if (resource.url
                          .toString()
                          .contains("www.ab.games:8888/undefined")) {
                        webViewController?.evaluateJavascript(
                            source:
                                'document.getElementById("backBtn").addEventListener("touchstart",function(e){console.log("allbet_back")})');
                      }
                    },

                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      logic.setup(context, controller);
                    },
                    onLoadStart: (controller, url) {
                      Fimber.i('onLoadStart');
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },

                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT);
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
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onReceivedError: (controller, request, error) {
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

                      logic.filterCasinoFromTitle(title);
                      logic.urlChangeDetect(title);
                    },
                    onCloseWindow: (controller) {
                      Fimber.i('onCloseWindow');
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      this.url = url.toString();
                      urlController.text = this.url;
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      Fimber.i("consoleMessage = ${consoleMessage.message}");
                      logic.consoleMessageFilter(consoleMessage.message);
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
                        padding: EdgeInsets.fromLTRB(
                            0, 0, 0, MediaQuery.of(context).size.height * 0.15),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
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
                        padding: EdgeInsets.fromLTRB(
                            0, 0, 0, MediaQuery.of(context).size.height * 0.15),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
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
                                        Consumer<DataHandler>(
                                          builder: (context, dh, _) =>
                                              TextButton(
                                                  onPressed: () {
                                                    logic.start();
                                                  },
                                                  child: (dh.isUiRunning)
                                                      ? const Text("停止辨識",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white))
                                                      : const Text("開始辨識",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white))),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                CustomButton(
                                    onPressed: () async {
                                      launchUrlString(
                                          'https://line.me/ti/p/@516wvzjp');
                                    },
                                    text: '聯繫客服'),
                                CustomButton(
                                    onPressed: () async {
                                      logic.swapKeepOneMode();
                                    },
                                    text: '均注'),
                                // CustomButton(
                                //     onPressed: () async {
                                //       selfEncryptedSharedPreference.clear();
                                //     },
                                //     text: 'reset'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.35,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                          child: Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.white),
                                      )),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Consumer<DataHandler>(
                                          builder: (context, dh, _) => Text(
                                              '均注模式 : ${(dh.keepOneMode) ? "on" : "off"}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                  fontSize: 20.0)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.35,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                          child: Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.white),
                                      )),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Consumer<DataHandler>(
                                          builder: (context, dh, _) => Text(
                                              '下注數:${dh.betTime}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                  fontSize: 20.0)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
}
