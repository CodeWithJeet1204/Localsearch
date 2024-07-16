import 'package:localy_user/models/business_sub_categories.dart';
import 'package:localy_user/page/main/vendor/category/category_products_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
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
        shopCategories[widget.shopName]!;

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
          ),
          itemCount: currentShopCategories.length,
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
                    color: white,
                    border: Border.all(
                      color: primaryDark,
                      width: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(
                    width * 0.006125,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: width * 0.5,
                          height: width * 0.5,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(width * 0.0125),
                        child: Text(
                          name.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width * 0.0475,
                            fontWeight: FontWeight.w600,
                          ),
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
