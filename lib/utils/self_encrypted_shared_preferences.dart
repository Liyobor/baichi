import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/utils/counter.dart';
import 'package:uuid/uuid.dart';


class SelfEncryptedSharedPreference {
  static final SelfEncryptedSharedPreference _singleton = SelfEncryptedSharedPreference._internal();
  EncryptedSharedPreferences encryptedSharedPreferences = EncryptedSharedPreferences();
  Counter counter = Counter();
  late SharedPreferences pref;
  factory SelfEncryptedSharedPreference() {
    return _singleton;
  }
  SelfEncryptedSharedPreference._internal(){
    encryptedSharedPreferences.getInstance().then((value) => pref = value);
  }

  String _generateUuid(){
    var uuidGenerator = const Uuid();
    return uuidGenerator.v4().toString();
  }

  Future<String> getUuidString() async {
    String uuid;
    if(!pref.containsKey('uuid')){
      uuid = _generateUuid();
      await encryptedSharedPreferences.setString('uuid', uuid);
    }else{
      uuid = await encryptedSharedPreferences.getString('uuid');
    }
    return uuid;
  }

  void removeFee(){
    encryptedSharedPreferences.remove("fee");
  }

  void setFee(double fee){
    encryptedSharedPreferences.setString('fee', fee.toInt().toString());
  }

  void saveRemainTime(){
    encryptedSharedPreferences.setString("remainTime",counter.count.toString());
  }


  Future<String?> getRemainTime() async {
    if(pref.containsKey('remainTime')){
      return await encryptedSharedPreferences.getString('remainTime');
    }else{
      return null;
    }
  }

  Future<String?> getFee() async {
    if(pref.containsKey('fee')){
      return await encryptedSharedPreferences.getString('fee');
    }else{
      return null;
    }
  }

  Future<String?> getWinTimes() async {
    if(pref.containsKey('WinTimes')){
      return await encryptedSharedPreferences.getString('WinTimes');
    }else{
      return null;
    }
  }

  void setWinTimes(int winTimes){
    encryptedSharedPreferences.setString('WinTimes', winTimes.toString());
  }


  Future<void> setReachLimitation()async {

    DateTime nowTime = DateTime.now();
    if (kDebugMode) {
      print("nowTime.year = ${nowTime.year}");
      print("nowTime.month = ${nowTime.month}");
      print("nowTime.day = ${nowTime.day}");
    }
    var str = "${nowTime.year}${nowTime.month}${nowTime.day}";
    encryptedSharedPreferences.setString('Limitation',str);
    setWinTimes(0);

  }

  void setLastPlayTimeDays(){
    DateTime nowTime = DateTime.now();
    encryptedSharedPreferences.setString('LastPlayTimeDay', nowTime.day.toString());
  }

  Future<int?> getLastPlayTimeDay() async {
    if(pref.containsKey('LastPlayTimeDay')){
      return int.parse(await encryptedSharedPreferences.getString('LastPlayTimeDay'));
    }else{
      return null;
    }
  }


  Future<bool> checkIfReachLimitation()async {
    DateTime nowTime = DateTime.now();
    if(pref.containsKey('Limitation')){

      String? day = await encryptedSharedPreferences.getString('Limitation');
      if (kDebugMode) {
        print("nowTime.year = ${nowTime.year}");
        print("nowTime.month = ${nowTime.month}");
        print("nowTime.day = ${nowTime.day}");
      }
      var str = "${nowTime.year}${nowTime.month}${nowTime.day}";
      if(str == day){
        return true;
      }
    }
    int? lastPlayTimeDay = await getLastPlayTimeDay();
    if(lastPlayTimeDay!=nowTime.day){
      setWinTimes(0);
    }
    return false;
  }

  clear() {
    pref.remove('Limitation');
    setWinTimes(0);
  }


}