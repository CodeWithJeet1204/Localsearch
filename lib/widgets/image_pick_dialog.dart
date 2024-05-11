// ignore_for_file: unnecessary_null_comparison
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/image_pick.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?>? showImagePickDialog(BuildContext context) async {
  XFile? im;

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final image = await pickCompressedImage(ImageSource.camera);
                if (image != null) {
                  im = image;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                alignment: Alignment.centerLeft,
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: primaryDark2,
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(27),
                    topRight: Radius.circular(27),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    'Choose Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final image = await pickCompressedImage(ImageSource.gallery);
                if (image != null) {
                  im = image;
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                alignment: Alignment.centerLeft,
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: primaryDark2,
                    width: 1,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(27),
                    bottomRight: Radius.circular(27),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  return im;
}
