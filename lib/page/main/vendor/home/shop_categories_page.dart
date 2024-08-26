import 'package:Localsearch_User/models/household_sub_category.dart';
import 'package:Localsearch_User/page/main/vendor/category/category_products_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShopCategoriesPage extends StatefulWidget {
  const ShopCategoriesPage({
    super.key,
    required this.shopName,
  });

  final String shopName;

  @override
  State<ShopCategoriesPage> createState() => _ShopCategoriesPageState();
}

class _ShopCategoriesPageState extends State<ShopCategoriesPage> {
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    Map<String, String> currentShopCategories =
        householdSubCategories[widget.shopName]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.825,
          ),
          itemCount: currentShopCategories.length,
          physics: const ClampingScrollPhysics(),
          itemBuilder: ((context, index) {
            final name = currentShopCategories.keys.toList()[index];
            final imageUrl = currentShopCategories.values.toList()[index];

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.015,
                vertical: width * 0.015,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: ((context) => CategoryProductsPage(
                            categoryName: name,
                            shopType: widget.shopName,
                          )),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: black,
                            ),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
