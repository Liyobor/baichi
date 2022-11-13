


import 'dart:math';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'dart:typed_data';

import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

image.Image? decodeImage(Uint8List data){
  return image.decodeImage(data);
}

TensorImage preProcess(List param) {
  final _inputShape1 = param[0];
  final _inputShape2 = param[1];
  final inputImage = TensorImage(param[2]);
  inputImage.loadImage(param[3]);

  // int cropSize = min(_inputImage.height, _inputImage.width);
  return ImageProcessorBuilder()
  // .add(ResizeWithCropOrPadOp(cropSize, cropSize))
      .add(ResizeOp(
      _inputShape1, _inputShape2, ResizeMethod.BILINEAR))
      .add(NormalizeOp(0, 255))
      .build()
      .process(inputImage);
}


double? wmGetMoneyInIsolate(String html) {
  try{
    int index = html.indexOf("userBalance");
    String clip = html.substring(index);
    int startIndex = clip.indexOf("NTD")+4;
    String dollarStr = clip.substring(startIndex,clip.indexOf("</spa"));
    dollarStr = dollarStr.replaceAll(",", "");
    double dollar = double.parse(dollarStr);
    return dollar;
  }catch(e){
    Fimber.i("error :$e");
    return null;
  }

}


double? allbetGetMoneyInIsolate(String html) {

  try{

    int index = html.indexOf("username");


    String clip = html.substring(index);

    for(int i = 0;i<3;i++ ){
      clip = clip.substring(4);
      clip = clip.substring(clip.indexOf('span'));
    }

    clip = clip.substring(0,clip.indexOf('</span'));

    clip = clip.substring(clip.indexOf('>')+1);

    clip = clip.replaceAll(",","");
    double dollar = double.parse(clip);
    return dollar;
  }catch(e){
    if (kDebugMode) {
      print("error :$e");
    }
    return null;
  }

}




Map<String,dynamic> uiOutputProcess(List input){

  List bboxes = input[0];
  List outScore  = input[1];
  int width = input[2];
  int height = input[3];

  var classList = [];
  var xList = [];
  var yList = [];

  double playerButtonX = -1.0;
  double playerButtonY = -1.0;
  double bankButtonX = -1.0;
  double bankButtonY = -1.0;
  double confirmButtonX = -1.0;
  double confirmButtonY = -1.0;

  for(int i =0;i<2535;i++){
    double maxClass = 0;
    int detectedClass = -1;
    final classes = List<double>.filled(8, 0.0);
    for (int c = 0;c< 8;c++){
      classes [c] = outScore[0][i][c];
    }
    for (int c = 0;c<8;++c){
      if (classes[c] > maxClass){
        detectedClass = c;
        maxClass = classes[c];
      }
    }
    final double score = maxClass;
    if(score>0.9){


      final double xPos = bboxes[0][i][0];
      final double yPos = bboxes[0][i][1];
      final double w = bboxes[0][i][2];
      final double h = bboxes[0][i][3];

      final buttonClass = detectedClass;
      final x = ((max(0, xPos - w / 2)/416)+(min(width - 1, xPos + w / 2)/416))/2;
      final y = ((max(0, yPos - h / 2)/416)+(min(height - 1, yPos + h / 2)/416))/2;

      if(y<0.8){
      xList.add(x);
      yList.add(y);
      classList.add(buttonClass);
      }

      if(buttonClass==0){
        bankButtonX = x;
        bankButtonY = y;
      }else if(buttonClass==3){
        playerButtonX = x;
        playerButtonY = y;
      }

      if(buttonClass == 2){
        confirmButtonX = x;
        confirmButtonY = y;
      }

    }


  }
  var map = {
    'xList':xList,
    'yList':yList,
    'classList':classList,
    'playerButtonX':playerButtonX,
    'playerButtonY':playerButtonY,
    'bankButtonX':bankButtonX,
    'bankButtonY':bankButtonY,
    'confirmButtonX':confirmButtonX,
    'confirmButtonY':confirmButtonY
  };


  return map;
}


List<List> allbetCardOutputProcess(List input){

  List bboxes = input[0];
  List outScore  = input[1];
  List xList = [];
  List classList = [];
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
      // Fimber.i('x = $x');
      // Fimber.i('y = $y');
      if(y>0.5 && y<0.75){


        for(var value in xList){
          if((x - value).abs() <=0.02){
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
  return [xList,classList];
}

List<List> wmCardOutputProcess(List input){

  List bboxes = input[0];
  List outScore  = input[1];
  List xList = [];
  List classList = [];
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
      if(y>0.5 && y<0.75){


        for(var value in xList){
          if((x - value).abs() <=0.02){
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
  return [xList,classList];
}