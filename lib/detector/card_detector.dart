
// import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';
import 'package:fimber/fimber.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:untitled/utils/isolate_function.dart';

// import 'package:image_gallery_saver/image_gallery_saver.dart';








class CardDetector{
  final _modelFile = 'card_detection.tflite';
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



  // late TensorBuffer _outputBuffer;

  // CardDetector({required this.ctx}) {
  //   _loadModel();
  //   if (kDebugMode) {
  //     print("model init");
  //   }
  //   // debugPrint("model init");
  // }

  CardDetector() {
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

  // TensorImage _preProcess() {
  //   // int cropSize = min(_inputImage.height, _inputImage.width);
  //   return ImageProcessorBuilder()
  //       // .add(ResizeWithCropOrPadOp(cropSize, cropSize))
  //       .add(ResizeOp(
  //       _inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR))
  //       .add(NormalizeOp(0, 255))
  //       .build()
  //       .process(_inputImage);
  // }

  Future<List> putImageIntoModel(img.Image image)  async {
    // _inputImage = TensorImage(_inputType);

    // _inputImage.loadImage(image);
    // Fimber.i("_inputImage.height = ${_inputImage.height}");
    // Fimber.i("_inputImage.width = ${_inputImage.width}");
    // Fimber.i("_inputImage.image len= ${_inputImage.image.getBytes().length}");
    // Fimber.i("_inputImage.image data= ${_inputImage.buffer.asFloat32List()}");

    // _inputImage = _preProcess();


    _inputImage = await compute(preProcess,[_inputShape[1], _inputShape[2],_inputType,image]);


    // Fimber.i("_inputImage.image data= ${_inputImage.buffer.asFloat32List()}");



    // Fimber.i("_inputImage.image len= ${_inputImage.image.getBytes().length}");
    // Fimber.i("_inputImage.height = ${_inputImage.height}");
    // Fimber.i("_inputImage.width = ${_inputImage.width}");
    // Fimber.i("_outputBuffer = ${_outputBuffer.getBuffer()}");
    // Fimber.i("_inputImage = ${_inputImage.buffer.asFloat32List()}");




    var outputs = {0: output0, 1: output1};

    var classList = [];
    var xList = [];
    // _interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    _interpreter.runForMultipleInputs([_inputImage.buffer], outputs);
    List bboxes = outputs[0]!;
    List outScore  = outputs[1]!;
    for(int i =0;i<2535;i++){
      double maxClass = 0;
      int detectedClass = -1;
      final classes = List<double>.filled(10, 0.0);
      for (int c = 0;c< 10;c++){
        classes [c] = outScore[0][i][c];
      }
      for (int c = 0;c<10;++c){
        if (classes[c] > maxClass){
          detectedClass = c;
          maxClass = classes[c];
        }
      }
      final double score = maxClass;
      if(score>0.7){


        final double xPos = bboxes[0][i][0];
        final double yPos = bboxes[0][i][1];
        final double w = bboxes[0][i][2];
        final double h = bboxes[0][i][3];

        final cardClass = detectedClass;
        final x = max(0, xPos - w / 2)/416;
        final y = max(0, yPos - h / 2)/416;



        // Fimber.i('---');
        // Fimber.i('class = $cardClass');
        // Fimber.i('score = $score');
        // Fimber.i('x = $x');
        // Fimber.i('y = $y');


        var isDuplicate = false;
        if(y>0.63 && y<0.65){


          for(var value in xList){
            if(x - value <=0.02){
              isDuplicate = true;
            }
          }

          if(!isDuplicate) {
            xList.add(x);
            classList.add(cardClass);
          }
        }
        // resultList.add([detectedClass+1,])
        // Fimber.i('${min(_inputImage.width - 1, xPos + w / 2)/416}');
        // Fimber.i('${min(_inputImage.height - 1, yPos + h / 2)/416}');
      }




    }

    List result = [];

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
      resultStr = "偵測到撲克牌:$cardClass";


    }

    return result;



  }





}