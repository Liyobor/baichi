import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class Counter with ChangeNotifier{

  static final Counter _singleton = Counter._internal();
  factory Counter() {
    return _singleton;
  }
  Counter._internal();


  int _count = 0;
  get count => _count;

  bool isExpired = false;

  void addCount(){
    if(_count != 7200){
      _count++;
    }else{
      isExpired = true;
    }
    notifyListeners();
  }

  void resetTimer(){
    _count = 0;
    isExpired = false;
    notifyListeners();
  }
}