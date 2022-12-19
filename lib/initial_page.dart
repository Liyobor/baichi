import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:untitled/data_handler.dart';
import 'package:untitled/in_app_webiew_example.screen.dart';
import 'package:untitled/utils/api_handler.dart';



class InitPage extends StatefulWidget {
  const InitPage({Key? key}) : super(key: key);

  @override
  State<InitPage> createState() =>
      _InitPageState();
}

class _InitPageState extends State<InitPage> {


  final TextEditingController _moneyTextFieldController = TextEditingController();
  final TextEditingController  _baseQuantityEditingController = TextEditingController();
  late TextEditingController _urlTextController;


  @override
  Widget build(BuildContext context) {
    ApiHandler apiHandler = ApiHandler();
    _urlTextController = TextEditingController(text:apiHandler.defaultUrl);
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("擊敗莊家1.0"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: TextFormField(
                controller: _urlTextController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link),
                  // suffixIcon: Icon(Icons.remove_red_eye),
                  labelText: "網址",
                  hintText: "輸入提示(可改)",
                ),
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            //   child: TextFormField(
            //     controller: _moneyTextFieldController,
            //     keyboardType: TextInputType.number,
            //     inputFormatters: [
            //       FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
            //     ],
            //     decoration: const InputDecoration(
            //       prefixIcon: Icon(Icons.money),
            //       labelText: "金額",
            //       hintText: "輸入提示(可改)",
            //     ),
            //   ),
            // ),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            //   child: TextFormField(
            //     controller: _baseQuantityEditingController,
            //     keyboardType: TextInputType.number,
            //     inputFormatters: [
            //       FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
            //     ],
            //     decoration: const InputDecoration(
            //       prefixIcon: Icon(Icons.money),
            //       labelText: "基數金額",
            //       hintText: "輸入提示(可改)",
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // SizedBox(
                  //   height: 48.0,
                  //   child: TextButton(
                  //     child: const Text("自行登入"),
                  //     onPressed: () async {
                  //       String urlStr = "https://www.bl868.net/new_home2.php";
                  //
                  //       // bool urlCheck = Uri.tryParse(_urlTextController.text)?.hasAbsolutePath ?? false;
                  //       // if(_passCodeFieldController.text == ""){
                  //       //   _showDialog("代碼不可為空!");
                  //       // }else{
                  //       //   apiHandler.userPassCode = _passCodeFieldController.text;
                  //         apiHandler.defaultUrl = urlStr;
                  //         // EasyLoading.show(status: '檢查代碼...');
                  //         // String? result = await apiHandler.checkServeState();
                  //         // EasyLoading.dismiss();
                  //         // if(mounted){
                  //           Navigator.push(context, MaterialPageRoute(builder: (context)=> const InAppWebViewExampleScreen()));
                  //         // }
                  //         // else{
                  //         //   _showDialog("代碼出錯!");
                  //         // }
                  //       // }
                  //       // Fimber.i(_textFieldController.text);
                  //     },
                  //   ),
                  // ),
                  SizedBox(
                    height: 48.0,
                    child: TextButton(
                      child: const Text("登入"),
                      onPressed: () async {
                        String urlStr;
                        if(_urlTextController.text.contains("https://")){
                          urlStr = _urlTextController.text;
                        }else {
                          urlStr = "https://${_urlTextController.text}";
                        }
                        bool validURL = Uri.parse(urlStr).isAbsolute;
                        // bool urlCheck = Uri.tryParse(_urlTextController.text)?.hasAbsolutePath ?? false;
                        // if(_passCodeFieldController.text == ""){
                        //   _showDialog("代碼不可為空!");
                        // }
                        if(!validURL){
                          _showDialog("網址格式錯誤!");
                        } else{
                          // DataHandler dataHandler = DataHandler();
                          // dataHandler.money = double.parse(_moneyTextFieldController.text);
                          // dataHandler.baseQuantity = int.parse(_baseQuantityEditingController.text);
                          // apiHandler.userPassCode = _passCodeFieldController.text;
                          apiHandler.defaultUrl = urlStr;
                          // Fimber.i("dataHandler.baseQuantity = ${dataHandler.baseQuantity}");

                          // EasyLoading.show(status: '檢查代碼...');
                          // String? result = await apiHandler.checkServeState();
                          // EasyLoading.dismiss();
                          // if(mounted){
                            // apiHandler.getDefaultUrl().then((value) => _showDialog(value));

                            Navigator.push(context, MaterialPageRoute(builder: (context)=> const InAppWebViewExampleScreen()));
                          // }
                          // else{
                          //   _showDialog("代碼出錯!");
                          // }
                        }
                        // Fimber.i(_textFieldController.text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Text(message)
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('確定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

