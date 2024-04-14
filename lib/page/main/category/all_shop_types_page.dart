import 'package:find_easy_user/models/business_categories.dart';
import 'package:find_easy_user/models/household_categories.dart';
import 'package:find_easy_user/page/main/category/shop_categories_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class AllShopTypesPage extends StatefulWidget {
  const AllShopTypesPage({super.key});

  @override
  State<AllShopTypesPage> createState() => _AllShopTypesPageState();
}

class _AllShopTypesPageState extends State<AllShopTypesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Shop Types'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.0125,
          vertical: MediaQuery.of(context).size.width * 0.0166,
        ),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BUSINESS
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.0375,
                      vertical: width * 0.0125,
                    ),
                    child: Text(
                      "Business",
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // BUSINESS SHOPS
                  SizedBox(
                    width: width,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.125,
                      ),
                      itemCount: businessCategories.length,
                      itemBuilder: ((context, index) {
                        final String name = businessCategories[index][0];
                        final String imageUrl = businessCategories[index][1];

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.025,
                            vertical: width * 0.015,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ShopCategoriesPage(
                                    shopName: name,
                                  ),
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
                                borderRadius: BorderRadius.circular(4),
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
                                        fit: BoxFit.cover,
                                        width: width * 0.15,
                                        height: width * 0.15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const Divider(),

                  // HOME
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.0375,
                      vertical: width * 0.0125,
                    ),
                    child: Text(
                      "Household",
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // HOME SHOPS
                  SizedBox(
                    width: width,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.125,
                      ),
                      itemCount: householdCategories.length,
                      itemBuilder: ((context, index) {
                        final String name = householdCategories[index][0];
                        final String imageUrl = householdCategories[index][1];

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.015,
                            vertical: width * 0.015,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ShopCategoriesPage(
                                    shopName: name,
                                  ),
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
                                borderRadius: BorderRadius.circular(4),
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
                                        fit: BoxFit.cover,
                                        width: width * 0.15,
                                        height: width * 0.15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
