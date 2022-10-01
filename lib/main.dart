import 'dart:async';
import 'dart:io';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:untitled/in_app_webiew_example.screen.dart';

import 'utils/counter.dart';
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
  // await Permission.camera.request();
  // await Permission.microphone.request();
  // await Permission.storage.request();
  await _checkPermissions();
  Fimber.clearAll();
  Fimber.plantTree(DebugTree());

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

    if (swAvailable && swInterceptAvailable) {
      AndroidServiceWorkerController serviceWorkerController =
      AndroidServiceWorkerController.instance();

      await serviceWorkerController
          .setServiceWorkerClient(AndroidServiceWorkerClient(
        shouldInterceptRequest: (request) async {
          debugPrint("$request");
          return null;
        },
      ));
    }
  }



  runApp(const MyApp());
}



Drawer myDrawer({required BuildContext context}) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        const DrawerHeader(
          child: Text('flutter_inappbrowser example'),
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
        ),
        ListTile(
          title: const Text('InAppBrowser'),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/InAppBrowser');
          },
        ),
        ListTile(
          title: const Text('ChromeSafariBrowser'),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/ChromeSafariBrowser');
          },
        ),
        ListTile(
          title: const Text('InAppWebView'),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        ListTile(
          title: const Text('HeadlessInAppWebView'),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/HeadlessInAppWebView');
          },
        ),
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Counter(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
          initialRoute: '/', routes: {
        '/': (context) => const InAppWebViewExampleScreen(),
      }
      ),
    );
  }
}