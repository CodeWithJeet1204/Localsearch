import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as pp;

Future<XFile?> pickCompressedImage(ImageSource source) async {
  XFile? image;

  image = await ImagePicker().pickImage(source: source);

  if (image != null) {
    final bytes = await image.readAsBytes();
    final kb = bytes.length / 1024;
    final mb = kb / 1024;

    if (kDebugMode) {
      print("Original: ${mb.toString()}");
    }

    final dir = await pp.getTemporaryDirectory();
    final targetPath = '${dir.absolute.path}/temp.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 50,
    );

    final data = await result!.readAsBytes();

    final newKb = data.length / 1024;
    final newMb = newKb / 1024;

    if (kDebugMode) {
      print("Compressed: ${newMb.toString()}");
    }

    return result;
  } else {
    return null;
  }
}
