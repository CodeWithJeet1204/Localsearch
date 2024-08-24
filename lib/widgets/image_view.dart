import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    required this.imagesUrl,
    this.shortsURL,
    this.shortsThumbnail,
  });

  final List imagesUrl;
  final String? shortsURL;
  final String? shortsThumbnail;

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  final controller = CarouselSliderController();
  late FlickManager flickManager;
  int currentIndex = 0;

  // INIT STATE
  @override
  void initState() {
    super.initState();

    if (widget.shortsURL != null) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(
            widget.shortsURL!,
          ),
        ),
      );
    }
  }

  // DISPOSE
  @override
  void dispose() {
    if (widget.shortsURL != null) {
      flickManager.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
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
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double width = constraints.maxWidth;

          if (widget.shortsURL == '' || widget.shortsURL == null) {
            if (widget.imagesUrl.contains(widget.shortsURL)) {
              widget.imagesUrl.remove(widget.shortsURL);
            }
            if (widget.imagesUrl.contains(widget.shortsThumbnail)) {
              widget.imagesUrl.remove(widget.shortsThumbnail);
            }
          }

          return Column(
            children: [
              CarouselSlider(
                carouselController: controller,
                items: widget.imagesUrl
                    .map((e) => e == widget.shortsURL
                        ? AspectRatio(
                            aspectRatio: 9 / 16,
                            child: FlickVideoPlayer(
                              flickManager: flickManager,
                            ),
                          )
                        : SizedBox(
                            height: width * 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: InteractiveViewer(
                                child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(e),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                    .toList(),
                options: CarouselOptions(
                  enableInfiniteScroll: false,
                  aspectRatio: 0.6125,
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      // controller.animateTo(
                      //   index.toDouble(),
                      //   duration: Duration(milliseconds: 100),
                      //   curve: Curves.bounceInOut,
                      // );
                      controller.animateToPage(index);
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.0125,
                ),
                child: SizedBox(
                  width: width,
                  height: width * 0.2,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.imagesUrl.length,
                    physics: ClampingScrollPhysics(),
                    itemBuilder: ((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              // controller.animateTo(
                              //   index.toDouble(),
                              //   duration: Duration(milliseconds: 100),
                              //   curve: Curves.bounceInOut,
                              // );
                              controller.animateToPage(index);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: primaryDark,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                widget.imagesUrl[index] == widget.shortsURL
                                    ? widget.shortsThumbnail
                                    : widget.imagesUrl[index],
                                height: width * 0.175,
                                width: width * 0.175,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
