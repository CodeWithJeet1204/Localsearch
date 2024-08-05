import 'package:Localsearch_User/page/main/vendor/post_page_view.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:flutter/material.dart';

class VendorPostsTabPage extends StatefulWidget {
  const VendorPostsTabPage({
    super.key,
    required this.posts,
    required this.width,
  });

  final double width;
  final Map<String, List> posts;

  @override
  State<VendorPostsTabPage> createState() => _VendorPostsTabPageState();
}

class _VendorPostsTabPageState extends State<VendorPostsTabPage> {
  // Map<String, dynamic> currentPosts = {};
  Map<String, dynamic> textPosts = {};
  Map<String, dynamic> imagePosts = {};
  String type = 'Image';

  // INIT STATE
  @override
  void initState() {
    widget.posts.forEach((key, value) {
      if (value[1] == true) {
        textPosts.addAll({key: value});
      } else {
        imagePosts.addAll({key: value});
      }
    });
    // updateCurrentPosts();
    setState(() {});
    super.initState();
  }

  // GET SCREEN HEIGHT
  double getScreenHeight() {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    final availableHeight = screenHeight - paddingTop - paddingBottom;
    return availableHeight;
  }

  // // UPDATE CURRENT POSTS
  // void updateCurrentPosts() {
  //   setState(() {
  //     if (type == 'Image') {
  //       currentPosts = imagePosts;
  //     } else {
  //       currentPosts = textPosts;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(widget.width * 0.0125),
                child: ActionChip(
                  label: Text(
                    'Image',
                    style: TextStyle(
                      color: type == 'Image' ? white : primaryDark,
                    ),
                  ),
                  tooltip: 'Select Image',
                  onPressed: () {
                    setState(() {
                      type = 'Image';
                    });
                  },
                  backgroundColor: type == 'Image' ? primaryDark : primary2,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(widget.width * 0.0125),
                child: ActionChip(
                  label: Text(
                    'Text',
                    style: TextStyle(
                      color: type == 'Text' ? white : primaryDark,
                    ),
                  ),
                  tooltip: 'Select Text',
                  onPressed: () {
                    setState(() {
                      type = 'Text';
                    });
                  },
                  backgroundColor: type == 'Text' ? primaryDark : primary2,
                ),
              ),
            ],
          ),
          SizedBox(
            width: widget.width,
            height: getScreenHeight() * 0.606125,
            child: type == 'Image'
                ? imagePosts.isEmpty
                    ? SizedBox(
                        height: 80,
                        child: Center(
                          child: Text('No Image Posts'),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: imagePosts.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final postId = imagePosts.keys.toList()[index];
                          final postImage =
                              imagePosts.values.toList()[index][2][0];

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PostPageView(
                                    currentIndex: imagePosts.keys
                                        .toList()
                                        .indexOf(postId),
                                    posts: imagePosts,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryDark2,
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    postImage,
                                  ),
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.none,
                                ),
                              ),
                              margin: EdgeInsets.all(widget.width * 0.006125),
                            ),
                          );
                        },
                      )
                : textPosts.isEmpty
                    ? SizedBox(
                        height: 80,
                        child: Center(
                          child: Text('No Text Posts'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: textPosts.length,
                        itemBuilder: (context, index) {
                          final postText = textPosts.values.toList()[index][0];

                          return Container(
                            decoration: BoxDecoration(
                              color: primary2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.width * 0.025,
                              vertical: widget.width * 0.033,
                            ),
                            margin: EdgeInsets.all(widget.width * 0.0125),
                            child: Text(
                              postText,
                              style: TextStyle(
                                fontSize: widget.width * 0.0475,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
