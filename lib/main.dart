import 'dart:async';
import 'dart:io';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:untitled/initial_page.dart';
import 'utils/api_handler.dart';
import 'utils/counter.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:shared_preferences/shared_preferences.dart';
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
  Fimber.clearAll();
  Fimber.plantTree(DebugTree());
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

  // if (Platform.isAndroid) {
  //   // await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  //
  //   // var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
  //   //     AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
  //   // var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
  //   //     AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);
  //
  //   if (swAvailable && swInterceptAvailable) {
  //     // AndroidServiceWorkerController serviceWorkerController =
  //     // AndroidServiceWorkerController.instance();
  //
  //     await serviceWorkerController
  //         .setServiceWorkerClient(AndroidServiceWorkerClient(
  //       shouldInterceptRequest: (request) async {
  //         // debugPrint("$request");
  //         return null;
  //       },
  //     ));
  //   }
  // }

  //
  // Workmanager().initialize(
  //     callbackDispatcher, // The top level function, aka callbackDispatcher
  //     isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  // );

  ApiHandler apiHandler = ApiHandler();
  await apiHandler.getDefaultUrl();
  runApp(const MyApp());
}

// void callbackDispatcher() {
//   ApiHandler apiHandler = ApiHandler();
//   Workmanager().executeTask((task, inputData) async {
//     switch(task){
//       case "callApiWhenDispose" :
//         debugPrint("callApiWhenDispose");
//         apiHandler.check2WhenDispose();
//         apiHandler.debtApiWhenDispose();
//     }
//     return Future.value(true);
//   });
// }


// Drawer myDrawer({required BuildContext context}) {
//   return Drawer(
//     child: ListView(
//       padding: EdgeInsets.zero,
//       children: <Widget>[
//         const DrawerHeader(
//           decoration: BoxDecoration(
//             color: Colors.blue,
//           ),
//           child: Text('flutter_inappbrowser example'),
//         ),
//         ListTile(
//           title: const Text('InAppBrowser'),
//           onTap: () {
//             Navigator.pushReplacementNamed(context, '/InAppBrowser');
//           },
//         ),
//         ListTile(
//           title: const Text('ChromeSafariBrowser'),
//           onTap: () {
//             Navigator.pushReplacementNamed(context, '/ChromeSafariBrowser');
//           },
//         ),
//         ListTile(
//           title: const Text('InAppWebView'),
//           onTap: () {
//             Navigator.pushReplacementNamed(context, '/');
//           },
//         ),
//         ListTile(
//           title: const Text('HeadlessInAppWebView'),
//           onTap: () {
//             Navigator.pushReplacementNamed(context, '/HeadlessInAppWebView');
//           },
//         ),
//       ],
//     ),
//   );
// }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Counter(),
      child: MaterialApp(
        builder: EasyLoading.init(),
        debugShowCheckedModeBanner: false,
          initialRoute: 'init',
          routes: {
        'init': (context) => const InitPage(),
        // '/': (context) => const InAppWebViewExampleScreen(),
      }
      ),
    );
  }
}