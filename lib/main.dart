import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:untitled/in_app_webiew_example.screen.dart';
import 'package:untitled/initial_page.dart';
import 'data_handler.dart';
import 'utils/api_handler.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

Future<void> _checkPermissions() async {
  if (Platform.isAndroid) {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    statuses.forEach((key, value) async {
      if (value.isDenied) {
        if (await key.request().isGranted) {
          debugPrint("$key is granted");
        }
      }
    });
  }
}




Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fimber.clearAll();
  // Fimber.plantTree(DebugTree());
  await _checkPermissions();
  WebView.debugLoggingSettings.enabled = false;

  if(Platform.isAndroid) {

    await InAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);
    if (swAvailable && swInterceptAvailable) {
      ServiceWorkerController serviceWorkerController =
          ServiceWorkerController.instance();
      await serviceWorkerController.setServiceWorkerClient(
          ServiceWorkerClient(shouldInterceptRequest: (request) async {
        return null;
      }));
    }
  }



  ApiHandler apiHandler = ApiHandler();
  await apiHandler.getDefaultUrl();
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataHandler(),
      child: MaterialApp(
        builder: EasyLoading.init(),
        debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
        'init': (context) => const InitPage(),
        '/': (context) => const InAppWebViewExampleScreen(),
      }
      ),
    );
  }
}