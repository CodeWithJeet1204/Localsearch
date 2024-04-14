import 'package:flutter/material.dart';

class ImageShow extends StatefulWidget {
  const ImageShow({
    super.key,
    required this.imageUrl,
    required this.width,
  });

  final String imageUrl;
  final double width;

  @override
  State<ImageShow> createState() => _ImageShowState();
}

class _ImageShowState extends State<ImageShow> {
  @override
  Widget build(BuildContext context) {
    final width = widget.width;

    return Dialog(
      shape: const CircleBorder(),
      child: InteractiveViewer(
        child: Container(
          width: width * 0.8,
          height: width * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(
                widget.imageUrl,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
