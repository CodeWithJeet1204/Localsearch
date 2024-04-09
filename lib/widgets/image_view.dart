import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class ImageView extends StatefulWidget {
  const ImageView({
    super.key,
    required this.imagesUrl,
  });

  final List imagesUrl;

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  final controller = CarouselController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double width = constraints.maxWidth;

          return Column(
            children: [
              CarouselSlider(
                carouselController: controller,
                items: widget.imagesUrl
                    .map((e) => SizedBox(
                          height: width * 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: e,
                                imageBuilder: (context, imageProvider) {
                                  return Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ))
                    .toList(),
                options: CarouselOptions(
                  enableInfiniteScroll: false,
                  aspectRatio: 0.6,
                  viewportFraction: 0.95,
                  enlargeCenterPage: false,
                  onPageChanged: (index, reason) {
                    setState(() {
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
                    itemBuilder: ((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
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
                                widget.imagesUrl[index],
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
