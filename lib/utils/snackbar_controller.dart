
import 'package:flutter/material.dart';

class SnackBarController{

  BuildContext context;
  SnackBarController({required this.context});


  void showRecognizeResult(String text,int milliseconds) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: Duration(milliseconds: milliseconds),
        action: SnackBarAction(label: '關閉', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}