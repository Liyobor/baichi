
// import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fimber/fimber.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:untitled/utils/isolate_function.dart';

class WmCardDetector{
  final _modelFile = 'wm_card_detection.tflite';
  late Interpreter _interpreter;
  late List<int> _inputShape;
  // late List<int> _outputShape0;
  // late List<int> _outputShape1;
  late TfLiteType _inputType;
  // late TfLiteType _outputType;
  late TensorImage _inputImage;
  String resultStr = "";


  List output0 = List<double>.filled(2535*4, 0.0);
  List output1 = List<double>.filled(2535*10, 0.0);



  WmCardDetector() {
    _loadModel();

    Fimber.i("CardDetector init");

    // debugPrint("model init");
  }

  void _loadModel() async {
    _interpreter = await Interpreter.fromAsset(_modelFile);
    // debugPrint('Interpreter loaded successfully');
    if (kDebugMode) {
      print('Interpreter loaded successfully');
    }
    // inputTensors = _interpreter.getInputTensors();
    // outputTensors = _interpreter.getOutputTensors();

    _inputShape = _interpreter.getInputTensor(0).shape;
    // _outputShape0 = _interpreter.getOutputTensor(0).shape;
    // _outputShape1 = _interpreter.getOutputTensor(1).shape;
    _inputType = _interpreter.getInputTensor(0).type;
    // _outputType = _interpreter.getOutputTensor(0).type;
    output0 = output0.reshape([1,2535,4]);
    output1 = output1.reshape([1,2535,10]);
    // Fimber.i('_inputType = $_inputType');
    // Fimber.i('_inputShape = $_inputShape');
    // Fimber.i('_outputShape0 = $_outputShape0');
    // Fimber.i('_outputShape1 = $_outputShape1');

    // _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);

  }

  Future<List> putImageIntoModel(img.Image image)  async {

    _inputImage = await compute(preProcess,[_inputShape[1], _inputShape[2],_inputType,image]);



    var outputs = {0: output0, 1: output1};

    // var classList = [];
    // var xList = [];
    // _interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    _interpreter.runForMultipleInputs([_inputImage.buffer], outputs);
    List bboxes = outputs[0]!;
    List outScore  = outputs[1]!;
    List processedOutput = await compute(wmCardOutputProcess,[bboxes,outScore]);

    var xList = processedOutput[0];
    var classList = processedOutput[1];


    List result = [];

    Fimber.i('count = ${xList.size}');

    if(xList.isEmpty){
      Fimber.i("didn't find card");
      resultStr = "didn't find card";
      // showRecognizeResult(ctx,"didn't find card");
    }else{
      resultStr = "";
      String cardClass = "";
      // String carPos = "";
      for(int i = 0;i<classList.length;i++){

        result.add(classList[i]);


        cardClass += classList[i].toString()+",";
        // carPos += xList[i].toString().substring(0,4)+",";
      }

      // showRecognizeResult(ctx,"偵測到撲克牌:$cardClass  x位置分別在$carPos");
      resultStr = "偵測結果:$cardClass";


    }

    return result;



  }





}