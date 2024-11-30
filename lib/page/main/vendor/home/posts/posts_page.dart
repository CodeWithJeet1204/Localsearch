import 'package:flutter/material.dart';
import 'package:localsearch/page/main/vendor/home/posts/discover_posts_page.dart';
import 'package:localsearch/page/main/vendor/home/posts/followed_posts_page.dart';
import 'package:localsearch/providers/main_page_provider.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:provider/provider.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final mainPageProvider = Provider.of<MainPageProvider>(context);
    final width = MediaQuery.sizeOf(context).width;
    final TabController tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 400),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        mainPageProvider.goToHomePage();
      },
      child: Scaffold(
        backgroundColor: primary,
        appBar: AppBar(
          title: const Text(
            'Posts',
          ),
          // actions: [
          //   IconButton(
          //     onPressed: () async {
          //       await showYouTubePlayerDialog(
          //         context,
          //         getYoutubeVideoId(
          //           '',
          //         ),
          //       );
          //     },
          //     icon: const Icon(
          //       Icons.question_mark_outlined,
          //     ),
          //     tooltip: 'Help',
          //   ),
          // ],
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          bottom: PreferredSize(
            preferredSize: Size(
              width,
              width * 0.1,
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: primary2,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: primaryDark.withOpacity(0.75),
                ),
              ),
              isScrollable: false,
              indicatorPadding: EdgeInsets.only(
                bottom: width * 0.0166,
                top: width * 0.015,
                left: -width * 0.045,
                right: -width * 0.045,
              ),
              automaticIndicatorColorAdjustment: false,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: primaryDark,
              labelStyle: const TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                letterSpacing: 0,
              ),
              dividerColor: white,
              indicatorColor: primaryDark,
              controller: tabController,
              tabs: const [
                Tab(
                  text: 'Discover',
                ),
                Tab(
                  text: 'Followed',
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: tabController,
          physics: NeverScrollableScrollPhysics(),
          children: const [
            DiscoverPostsPage(),
            FollowedPostsPage(),
          ],
        ),
      ),
    );
  }
}
