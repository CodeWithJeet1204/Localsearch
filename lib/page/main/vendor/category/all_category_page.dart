import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/main/vendor/category/category_page.dart';
import 'package:localsearch/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class AllCategoryPage extends StatefulWidget {
  const AllCategoryPage({
    super.key,
    required this.categoryData,
  });

  final Map<String, dynamic> categoryData;

  @override
  State<AllCategoryPage> createState() => _AllCategoryPageState();
}

class _AllCategoryPageState extends State<AllCategoryPage> {
  final store = FirebaseFirestore.instance;
  int noOf = 12;
  int? total;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    // getTotal();
    scrollController.addListener(scrollListener);
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // SCROLL LISTENER
  Future<void> scrollListener() async {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      setState(() {
        isLoadMore = true;
      });
      noOf = noOf + 8;
      setState(() {
        isLoadMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Categories'),
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
        child: GridView.builder(
          controller: scrollController,
          cacheExtent: height * 1.5,
          addAutomaticKeepAlives: true,
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.775,
          ),
          itemCount: noOf > widget.categoryData.length
              ? widget.categoryData.length
              : noOf,
          physics: const ClampingScrollPhysics(),
          itemBuilder: ((context, index) {
            final name = widget.categoryData.keys.toList()[isLoadMore
                ? index == 0
                    ? 0
                    : index - 1
                : index];
            final imageUrl = widget.categoryData.values.toList()[isLoadMore
                ? index == 0
                    ? 0
                    : index - 1
                : index];

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: ((context) => CategoryPage(
                          categoryName: name,
                        )),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 0.25,
                  ),
                ),
                margin: EdgeInsets.all(width * 0.0125),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(),
                    ),
                    AutoSizeText(
                      name.toString().trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: width * 0.05125,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: SizedBox(),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        imageUrl.toString().trim(),
                        width: width * 0.475,
                        height: width * 0.475,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
