// import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';
import 'package:fimber/fimber.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'package:image_gallery_saver/image_gallery_saver.dart';

class CardDetector{
  final _modelFile = 'card_detection.tflite';
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape0;
  late List<int> _outputShape1;
  late TfLiteType _inputType;
  late TfLiteType _outputType;
  // BuildContext ctx;
  late TensorImage _inputImage;



  late TensorBuffer _outputBuffer;
  // CardDetector({required this.ctx}) {
  //   _loadModel();
  //   if (kDebugMode) {
  //     print("model init");
  //   }
  //   // debugPrint("model init");
  // }

  CardDetector() {
    _loadModel();
    if (kDebugMode) {
      print("model init");
    }
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
    _outputShape0 = _interpreter.getOutputTensor(0).shape;
    _outputShape1 = _interpreter.getOutputTensor(1).shape;
    _inputType = _interpreter.getInputTensor(0).type;
    _outputType = _interpreter.getOutputTensor(0).type;
    Fimber.i('_inputType = $_inputType');
    Fimber.i('_inputShape = $_inputShape');
    Fimber.i('_outputShape0 = $_outputShape0');
    Fimber.i('_outputShape1 = $_outputShape1');

    // _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);

    // showModelTensor(ctx);
  }

  TensorImage _preProcess() {
    int cropSize = min(_inputImage.height, _inputImage.width);
    return ImageProcessorBuilder()
        // .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(
        _inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR))
        .add(NormalizeOp(0, 255))
        .build()
        .process(_inputImage);
  }

  void putImageIntoModel(img.Image image)  {
    _inputImage = TensorImage(_inputType);

    _inputImage.loadImage(image);
    Fimber.i("_inputImage.height = ${_inputImage.height}");
    Fimber.i("_inputImage.width = ${_inputImage.width}");
    Fimber.i("_inputImage.image len= ${_inputImage.image.getBytes().length}");
    // Fimber.i("_inputImage.image data= ${_inputImage.buffer.asFloat32List()}");

    _inputImage = _preProcess();
    // Fimber.i("_inputImage.image data= ${_inputImage.buffer.asFloat32List()}");



    Fimber.i("_inputImage.image len= ${_inputImage.image.getBytes().length}");
    Fimber.i("_inputImage.height = ${_inputImage.height}");
    Fimber.i("_inputImage.width = ${_inputImage.width}");
    // Fimber.i("_outputBuffer = ${_outputBuffer.getBuffer()}");
    Fimber.i("_inputImage = ${_inputImage.buffer.asFloat32List()}");

    List output0 = List<double>.filled(2535*4, 0.0);
    List output1 = List<double>.filled(2535*13, 0.0);
    output0 = output0.reshape([1,2535,4]);
    output1 = output1.reshape([1,2535,13]);




    var outputs = {0: output0, 1: output1};
    // _interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    _interpreter.runForMultipleInputs([_inputImage.buffer], outputs);
    List bboxes = outputs[0]!;
    List out_score  = outputs[1]!;
    for(int i =0;i<2535;i++){
      double maxClass = 0;
      int detectedClass = -1;
      final classes = List<double>.filled(13, 0.0);
      for (int c = 0;c< 13;c++){
        classes [c] = out_score[0][i][c];
      }
      for (int c = 0;c<13;++c){
        if (classes[c] > maxClass){
          detectedClass = c;
          maxClass = classes[c];
        }
      }
      final double score = maxClass;
      if(score>0.5){

        final double xPos = bboxes[0][i][0];
        final double yPos = bboxes[0][i][1];
        final double w = bboxes[0][i][2];
        final double h = bboxes[0][i][3];

        Fimber.i('---');
        Fimber.i('class = $detectedClass');
        Fimber.i('score = $score');
        Fimber.i('${max(0, xPos - w / 2)/416}');
        Fimber.i('${max(0, yPos - h / 2)/416}');
        Fimber.i('${min(_inputImage.width - 1, xPos + w / 2)/416}');
        Fimber.i('${min(_inputImage.height - 1, yPos + h / 2)/416}');
      }



    }

    // Fimber.i("_outputBuffer = $_outputBuffer");




  }











  // void showModelTensor(BuildContext context) {
  //   final scaffold = ScaffoldMessenger.of(context);
  //   scaffold.showSnackBar(
  //     SnackBar(
  //       content: Text("InputTensors = $inputTensors\nOutputTensors = $outputTensors"),
  //       action: SnackBarAction(label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
  //     ),
  //   );
  // }


}