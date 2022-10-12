import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
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

}