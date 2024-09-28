import 'package:localsearch/page/main/vendor/vendor_page.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/utils/colors.dart';

class StatusPageView extends StatefulWidget {
  const StatusPageView({
    super.key,
    required this.currentIndex,
    required this.posts,
  });

  final int currentIndex;
  final Map<String, Map<String, dynamic>> posts;

  @override
  State<StatusPageView> createState() => _StatusPageViewState();
}

class _StatusPageViewState extends State<StatusPageView> {
  final PageController _pageController = PageController();
  late int index;
  int currentImageIndex = 0;

  // INIT STATE
  @override
  void initState() {
    index = widget.currentIndex;
    super.initState();
  }

  // SHOW TEXT DIALOG
  Future<void> showTextDialog(String text, double width) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: primary2,
          child: Container(
            padding: EdgeInsets.all(width * 0.033),
            child: SingleChildScrollView(
              child: Text(
                text,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  // FLATTEN POSTS
  List<Map<String, dynamic>> flattenPosts() {
    List<Map<String, dynamic>> postsList = [];

    widget.posts.forEach((vendorId, vendorData) {
      String vendorName = vendorData['vendorName'] ?? '';
      String vendorImageUrl = vendorData['vendorImageUrl'] ?? '';

      Map<String, dynamic> vendorPosts = vendorData['posts'] ?? {};

      vendorPosts.forEach((postId, post) {
        if (post is Map<String, dynamic>) {
          postsList.add({
            'vendorId': vendorId,
            'vendorName': vendorName,
            'vendorImageUrl': vendorImageUrl,
            'postId': postId,
            'postText': post['postText'] ?? '',
            'postImage': post['postImage'] ?? '',
            'postViews': post['postViews'] ?? '',
            'isViewed': post['isViewed'] ?? false,
          });
        }
      });
    });

    return postsList;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    List<Map<String, dynamic>> flattenedPosts = flattenPosts();

    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              FeatherIcons.x,
              color: white,
            ),
            color: white,
            tooltip: 'CLOSE',
          ),
        ],
        automaticallyImplyLeading: false,
        foregroundColor: white,
        backgroundColor: black,
        shadowColor: black,
        surfaceTintColor: black,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: flattenedPosts.length,
        itemBuilder: (context, index) {
          final post = flattenedPosts[index];
          final vendorId = post['vendorId'];
          final postText = post['postText'];
          final postImageUrl = post['postImage'];

          return Padding(
            padding: EdgeInsets.all(width * 0.006125),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => VendorPage(
                          vendorId: vendorId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.0125),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: width * 0.05,
                          backgroundImage: NetworkImage(
                            post['vendorImageUrl'],
                          ),
                          backgroundColor: Colors.black,
                        ),
                        SizedBox(width: width * 0.0125),
                        Text(
                          post['vendorName'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.055,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Center(
                      child: Image.network(
                        postImageUrl,
                        width: width,
                        height: width,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        index == 0
                            ? Container()
                            : Container(
                                decoration: BoxDecoration(
                                  color: primaryDark2,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.arrow_left,
                                    color: Colors.white,
                                    size: width * 0.09,
                                  ),
                                  padding: EdgeInsets.all(width * 0.025),
                                ),
                              ),
                        index == (flattenedPosts.length - 1)
                            ? Container()
                            : Container(
                                decoration: BoxDecoration(
                                  color: primaryDark2,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.arrow_right,
                                    color: Colors.white,
                                    size: width * 0.09,
                                  ),
                                  padding: EdgeInsets.all(width * 0.025),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: width * 0.025),
                    child: GestureDetector(
                      onTap: () async {
                        await showTextDialog(postText, width);
                      },
                      child: Text(
                        postText,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
