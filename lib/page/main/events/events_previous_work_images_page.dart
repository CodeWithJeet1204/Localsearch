import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class EventsPreviousWorkImagesPage extends StatefulWidget {
  const EventsPreviousWorkImagesPage({
    super.key,
    required this.workImages,
  });

  final List workImages;

  @override
  State<EventsPreviousWorkImagesPage> createState() =>
      _EventsPreviousWorkImagesPageState();
}

class _EventsPreviousWorkImagesPageState
    extends State<EventsPreviousWorkImagesPage> {
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
        title: const Text('Work Images'),
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
      body: widget.workImages.isEmpty
          ? const Center(
              child: Text('No Images'),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  width * 0.006125,
                ),
                child: SizedBox(
                  width: width,
                  height: MediaQuery.of(context).size.height,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                    ),
                    itemCount: widget.workImages.length,
                    itemBuilder: ((context, index) {
                      final imageUrl = widget.workImages[index];

                      return GestureDetector(
                        onTap: () async {
                          await showImage(imageUrl);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.25,
                              color: primaryDark,
                            ),
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
              ),
            ),
    );
  }
}
