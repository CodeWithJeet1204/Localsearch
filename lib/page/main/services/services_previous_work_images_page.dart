import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class ServicesPreviousWorkImagesPage extends StatefulWidget {
  const ServicesPreviousWorkImagesPage({
    super.key,
    required this.imagesData,
  });

  final Map<String, dynamic> imagesData;

  @override
  State<ServicesPreviousWorkImagesPage> createState() =>
      _ServicesPreviousWorkImagesPageState();
}

class _ServicesPreviousWorkImagesPageState
    extends State<ServicesPreviousWorkImagesPage> {
  // SHOW IMAGE
  Future<void> showImage(String imageUrl) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: ((context) {
        return Dialog(
          elevation: 20,
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Work Images'),
        actions: [
          IconButton(
            onPressed: () async {
              await showYouTubePlayerDialog(
                context,
                getYoutubeVideoId(
                  '',
                ),
              );
            },
            icon: const Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.006125,
          ),
          child: SizedBox(
            width: width,
            height: MediaQuery.of(context).size.height,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.imagesData.length,
              itemBuilder: ((context, index) {
                final subCategory = widget.imagesData.keys.toList()[index];
                final images = widget.imagesData.values.toList()[index];

                return Container(
                  width: width,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 0.5,
                      color: primaryDark,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.0225,
                    vertical: width * 0.033,
                  ),
                  margin: EdgeInsets.all(width * 0.0125),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subCategory,
                        style: TextStyle(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: width,
                        height: width * 0.33,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: ((context, index) {
                            final imageUrl = images[index];

                            return GestureDetector(
                              onTap: () async {
                                await showImage(imageUrl);
                              },
                              child: Container(
                                width: width * 0.33,
                                height: width * 0.33,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                margin: EdgeInsets.all(width * 0.0125),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
