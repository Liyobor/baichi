
import 'package:image/image.dart' as image;
import 'dart:typed_data';
// import 'dart:ui' as ui;

import 'package:fimber/fimber.dart';

class Converter{

  // Future<ui.Image> convertUInt8List2Image(Uint8List data) async {
  //   ui.Codec codec = await ui.instantiateImageCodec(data);
  //   ui.FrameInfo frame = await codec.getNextFrame();
  //   return frame.image;
  // }




  Uint8List cropImage(Uint8List data) {
    // Uint8List resizedData = data;
    Fimber.i('len of data before crop :${data.length}');
    Uint8List croppedData = data;
    image.Image img = image.decodeImage(data)!;
    image.Image cropped = image.copyCrop(img, 0, 0, 1400,1400);
    // image.Image resized = image.copyResize(img, width: img.width*2, height: img.height*2);
    croppedData = Uint8List.fromList(image.encodePng(cropped));
    // resizedData = Uint8List.fromList(image.encodePng(resized));
    // return resizedData;
    Fimber.i('len of data after crop :${croppedData.length}');
    return croppedData;
  }





// ui.Image convertUInt8List2Image(Uint8List data) {
  //   Fimber.i('${data.toList()}');
  //   Fimber.i('data len = ${data.length}');
  //   late ui.Image image;
  //   ui.decodeImageFromList(data, (result) {
  //     image = result;
  //     // Fimber.i('uiImage width = ${result.width}');
  //     // Fimber.i('uiImage height = ${result.height}');
  //
  //
  //   });
  //   return image;
  // }

}