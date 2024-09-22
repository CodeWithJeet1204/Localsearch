// ignore_for_file: unused_field
import 'package:localsearch/page/main/vendor/shorts_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/providers/main_page_provider.dart';
import 'package:provider/provider.dart';
// import 'package:preload_page_view/preload_page_view.dart';
import 'package:video_player/video_player.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({
    super.key,
    required this.bottomNavIndex,
  });

  final int bottomNavIndex;

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final store = FirebaseFirestore.instance;
  // final _pageController = PreloadPageController();
  final _pageController = PageController();
  int _currentPage = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};

  // INIT STATE
  @override
  void initState() {
    super.initState();
    _pageController.addListener(onPageChanged);
  }

  // DISPOSE
  @override
  void dispose() {
    _pageController.dispose();
    _videoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // ON PAGE CHANGED
  void onPageChanged() {
    final pageIndex = _pageController.page?.round() ?? 0;
    setState(() {
      _currentPage = pageIndex;
    });

    preloadNearbyVideos(pageIndex);
  }

  // PRELOAD NEARBY VIDEOS
  void preloadNearbyVideos(int currentPage) {
    final preloadRange = 3;
    for (var i = currentPage - preloadRange;
        i <= currentPage + preloadRange;
        i++) {
      if (i < 0 || i >= _videoControllers.length) continue;
      if (!_videoControllers.containsKey(i)) {
        initVideoControllerForPage(i);
      }
    }
  }

  // INIT VIDEO CONTROLLER FOR PAGE
  Future<void> initVideoControllerForPage(int pageIndex) async {
    final shortsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Shorts')
        .orderBy('datetime', descending: true)
        .get();

    final shortData = shortsSnap.docs[pageIndex].data();
    final videoUrl = shortData['shortsURL'] as String;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller.initialize();
    _videoControllers[pageIndex] = controller;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mainPageProvider = Provider.of<MainPageProvider>(context);
    final shortsStream = store
        .collection('Business')
        .doc('Data')
        .collection('Shorts')
        .orderBy('datetime', descending: true)
        .snapshots();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        mainPageProvider.goToHomePage();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
              stream: shortsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Some Error Occurred',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  final shortsSnap = snapshot.data!;
                  if (shortsSnap.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Shorts Available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // return PreloadPageView.builder(
                  return PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      mainPageProvider.goToHomePage();
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: shortsSnap.docs.length,
                      // preloadPagesCount: 2,
                      itemBuilder: (context, index) {
                        final currentShort = shortsSnap.docs[index];
                        final currentShortData = currentShort.data();
                        (currentShortData as Map<String, dynamic>).addAll({
                          'shortsId': currentShort.id,
                        });
                        final data = currentShortData;

                        // final controller = _videoControllers[index];

                        return PopScope(
                          canPop: false,
                          onPopInvokedWithResult: (didPop, result) {
                            mainPageProvider.goToHomePage();
                          },
                          child: ShortsTile(
                            data: data,
                            snappedPageIndex: _currentPage,
                            currentIndex: index,
                            bottomNavIndex: widget.bottomNavIndex,
                          ),
                        );
                      },
                    ),
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ),
      ),
    );
  }
}
