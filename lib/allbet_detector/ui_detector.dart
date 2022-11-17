

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fimber/fimber.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:untitled/utils/isolate_function.dart';



class AllbetUIDetector{
  final _modelFile = 'allbet_ui_detection.tflite';
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape0;
  late List<int> _outputShape1;
  late TfLiteType _inputType;
  // late TfLiteType _outputType;
  late TensorImage _inputImage;

  // double playerButtonX = 0.18;
  // double playerButtonY = 0.60;
  // double bankButtonX = 0.82;
  // double bankButtonY = 0.560;
  // double confirmButtonX = 0.50;
  // double confirmButtonY = 0.65;


  List output0 = List<double>.filled(2535*4, 0.0);
  List output1 = List<double>.filled(2535*8, 0.0);

  String resultStr = "";
  String? winSide;

  String errorStr = "";


  List label = [
    "莊家",
    "莊家勝",
    "確定",
    "閒家",
    "閒家勝",
    "平手",
    "洗牌中",
    "非下注時間",
  ];

  /*
  state
  0 = 辨識牌
  1 = 下注
  2 = 洗牌
  出現 莊勝或是閒勝時候 切換state = 0
  計算完再下注期間進行操作
   */
  int _state = 0;


  AllbetUIDetector() {
    _loadModel();

    Fimber.i("UIDetector init");

    // debugPrint("model init");
  }

  void _loadModel() async {
    _interpreter = await Interpreter.fromAsset(_modelFile);
    // debugPrint('Interpreter loaded successfully');

    Fimber.i('Interpreter loaded successfully');


    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape0 = _interpreter.getOutputTensor(0).shape;
    _outputShape1 = _interpreter.getOutputTensor(1).shape;
    _inputType = _interpreter.getInputTensor(0).type;
    // _outputType = _interpreter.getOutputTensor(0).type;
    output0 = output0.reshape([1,2535,4]);
    output1 = output1.reshape([1,2535,8]);
    Fimber.i('_inputType = $_inputType');
    Fimber.i('_inputShape = $_inputShape');
    Fimber.i('_outputShape0 = $_outputShape0');
    Fimber.i('_outputShape1 = $_outputShape1');

  }



  Future<bool> putImageIntoModel(img.Image image)  async {

    _inputImage = await compute(preProcess,[_inputShape[1], _inputShape[2],_inputType,image]);



    var outputs = {0: output0, 1: output1};

    var classList = [];
    var xList = [];
    var yList = [];

    _interpreter.runForMultipleInputs([_inputImage.buffer], outputs);
    List bboxes = outputs[0]!;
    List outScore  = outputs[1]!;

    Map processedOutput = await compute(allbetUiOutputProcess,[bboxes,outScore,_inputImage.width,_inputImage.height]);

    classList = processedOutput['classList'];
    xList = processedOutput['xList'];
    yList = processedOutput['yList'];

    // bankButtonX = processedOutput['bankButtonX'];
    // Fimber.i('bankButtonX = $bankButtonX');
    // bankButtonY = processedOutput['bankButtonY'];
    // Fimber.i('bankButtonY = $bankButtonY');
    // playerButtonX = processedOutput['playerButtonX'];
    // Fimber.i('playerButtonX = $playerButtonX');
    // playerButtonY = processedOutput['playerButtonY'];
    // Fimber.i('playerButtonY = $playerButtonY');
    // confirmButtonX = processedOutput['confirmButtonX'];
    // Fimber.i('confirmButtonX = $confirmButtonX');
    // confirmButtonY = processedOutput['confirmButtonY'];
    // Fimber.i('confirmButtonY = $confirmButtonY');




    // if (kDebugMode) {
    //   print("class list = $classList");
    //   print("xList = $xList");
    //   print("yList = $yList");
    // }




    if(classList.contains(7)||classList.contains(1)||classList.contains(4)||classList.contains(5)){
      _state = 0;
    }else if(classList.contains(6)){
      _state = 2;
    }else{
      _state = 1;
    }


    // Fimber.i("classList = $classList");
    // Fimber.i("xList = $xList");
    // Fimber.i("yList = $yList");

    if(classList.contains(1)){
      // Fimber.i("xList = $xList");
      winSide = "bank";
      return true;
    }
    if(classList.contains(4)){
      // Fimber.i("xList = $xList");
      winSide = "player";
      return true;
    }

    if(classList.contains(5)){
      // Fimber.i("xList = $xList");
      winSide = "draw";
      return true;
    }







    if(xList.isEmpty){
      Fimber.i("didn't find button");
      resultStr = "didn't find button";
      // showRecognizeResult(ctx,"didn't find card");
    }else{
      resultStr = "";
      for(int i = 0;i<classList.length;i++){
        resultStr += "${label[classList[i]]} x:${xList[i].toString().substring(0,4)} y:${yList[i].toString().substring(0,4)}\n";
        // Fimber.i('${classList.length}');

        // if(classList[i] == 3 && xList[i].toString().substring(0,4)!="0.20" &&yList[i].toString().substring(0,4)!="0.55"){
        //   Fimber.i("button error");
        //   resultStr = "button error";
        //   errorStr+=",bank";
        // }
        // if(classList[i] == 0 && xList[i].toString().substring(0,4)!="0.79" &&yList[i].toString().substring(0,4)!="0.55"){
        //   Fimber.i("button error");
        //   resultStr = "button error";
        //   errorStr+=",player";
        // }
        // if(classList[i] == 2 && xList[i].toString().substring(0,4)!="0.65" &&yList[i].toString().substring(0,4)!="0.75"){
        //   Fimber.i("button error");
        //   resultStr = "button error";
        //   errorStr+=",confirm";
        // }
      }



    }

    return false;



  }

  int getCalculatorState(){
    return _state;
  }

}

