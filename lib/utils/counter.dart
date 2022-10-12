import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/utils/self_encrypted_shared_preferences.dart';

class Counter with ChangeNotifier{

  static final Counter _singleton = Counter._internal();

  late SelfEncryptedSharedPreference selfEncryptedSharedPreference;
  factory Counter() {
    return _singleton;
  }
  Counter._internal();


  int _count = 0;
  get count => _count;

  bool isExpired = false;

  Future<void> initCount() async {
    selfEncryptedSharedPreference = SelfEncryptedSharedPreference();
    String? remainTime = await selfEncryptedSharedPreference.getRemainTime();
    if(remainTime!=null){
      _count = int.parse(remainTime);
    }
  }

  void addCount(){
    selfEncryptedSharedPreference.saveRemainTime();
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