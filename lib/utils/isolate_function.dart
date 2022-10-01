


import 'package:fimber/fimber.dart';
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
      _inputShape1, _inputShape2, ResizeMethod.NEAREST_NEIGHBOUR))
      .add(NormalizeOp(0, 255))
      .build()
      .process(inputImage);
}


double? getMoneyInIsolate(String html) {
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