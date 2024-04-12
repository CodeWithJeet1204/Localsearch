import 'package:find_easy_user/models/shop_categories.dart';
import 'package:find_easy_user/utils/colors.dart';
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
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.0125,
          vertical: MediaQuery.of(context).size.width * 0.0166,
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: currentShopCategories.length,
          itemBuilder: ((context, index) {
            final name = currentShopCategories.keys.toList()[index];
            final imageUrl = currentShopCategories.values.toList()[index];
            print("Name: $name");
            print("Image: $imageUrl");

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.015,
                vertical: width * 0.015,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: white,
                  border: Border.all(
                    color: primaryDark,
                    width: 0.25,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.0125,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: width * 0.33,
                          height: width * 0.33,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
