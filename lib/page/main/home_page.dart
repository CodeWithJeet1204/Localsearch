import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/models/business_categories.dart';
import 'package:find_easy_user/page/main/product/product_page.dart';
import 'package:find_easy_user/page/main/search/search_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/text_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String recentShop = '';
  List<String> recentShopProducts = [];
  List<String> recentShopProductsImages = [];
  List<String> recentShopProductsNames = [];
  List<Map<String, dynamic>> recentShopProductsData = [];

  List<int> numbers = [0, 1, 2, 3];
  List<int> reverseNumbers = [4, 5, 6, 7];

  // INIT STATE
  @override
  void initState() {
    super.initState();
    getRecentShop();
  }

  // DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getRecentShop();
  }

  // GET RECENT SHOP
  Future<void> getRecentShop() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    setState(() {
      recentShop = userData['recentShop'];
    });

    await getNoOfProductsOfRecentShop();
  }

  // GET NO OF PRODUCTS OF RECENT SHOP
  Future<void> getNoOfProductsOfRecentShop() async {
    final recentProducts = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('vendorId', isEqualTo: recentShop)
        .get();

    for (final doc in recentProducts.docs) {
      if (!recentShopProducts.contains(doc['productId'])) {
        recentShopProducts.add(doc['productId']);
      }
    }

    await getRecentShopProductInfo(false);
  }

  // GET RECENT SHOP PRODUCT INFO
  Future<int> getRecentShopProductInfo(bool fromRecent) async {
    List<String> temporaryNameList = [];
    List<String> temporaryImageList = [];
    List<Map<String, dynamic>> temporaryDataList = [];
    // ignore: avoid_function_literals_in_foreach_calls
    recentShopProducts.forEach((productId) async {
      final productData = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      temporaryNameList.add(productData['productName']);
      temporaryImageList.add(productData['images'][0]);
      temporaryDataList.add(productData.data()!);
      setState(() {
        recentShopProductsNames = temporaryNameList;
        recentShopProductsImages = temporaryImageList;
        recentShopProductsData = temporaryDataList;
      });
    });

    return recentShopProductsImages.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.0125,
            vertical: MediaQuery.of(context).size.width * 0.0166,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final double width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SEARCH
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.0125,
                          vertical: width * 0.0125,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: ((context) => const SearchPage()),
                              ),
                            );
                          },
                          icon: const Icon(FeatherIcons.search),
                          color: primaryDark2.withOpacity(0.8),
                          tooltip: "Search",
                        ),
                      ),
                    ),

                    // CATEGORIES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.025,
                            vertical: width * 0.025,
                          ),
                          child: Text(
                            'Categories',
                            style: TextStyle(
                              color: primaryDark,
                              fontSize: width * 0.07,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        MyTextButton(
                          onPressed: () {},
                          text: 'See All',
                          textColor: primaryDark2,
                        ),
                      ],
                    ),

                    // CATEGORIES BOX
                    Container(
                      width: width,
                      height: width * 0.65,
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: lightGrey,
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.only(
                        right: width * 0.02,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: width,
                            height: width * 0.3,
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              itemBuilder: ((context, index) {
                                final String name =
                                    businessCategories[numbers[index]][0];
                                final String imageUrl =
                                    businessCategories[numbers[index]][1];

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.015,
                                  ),
                                  child: Container(
                                    width: width * 0.2,
                                    height: width * 0.25,
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              height: width * 0.175,
                                            ),
                                          ),
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
                          SizedBox(
                            width: width,
                            height: width * 0.3,
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              itemBuilder: ((context, index) {
                                final String name =
                                    businessCategories[reverseNumbers[index]]
                                        [0];
                                final String imageUrl =
                                    businessCategories[reverseNumbers[index]]
                                        [1];

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.025,
                                    vertical: width * 0.015,
                                  ),
                                  child: Container(
                                    width: width * 0.2,
                                    height: width * 0.25,
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              imageUrl,
                                              height: width * 0.175,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
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
                        ],
                      ),
                    ),

                    // CONTINUE
                    recentShop != ''
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.025,
                              vertical: width * 0.025,
                            ),
                            child: Text(
                              'Continue Shopping',
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: width * 0.07,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Container(),

                    // CONTINUE PRODUCTS
                    SizedBox(
                      width: width,
                      height: width * 0.425,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: recentShopProductsImages.length > 4
                            ? 4
                            : recentShopProductsImages.length,
                        itemBuilder: ((context, index) {
                          final String name = recentShopProductsNames[index];
                          final String image = recentShopProductsImages[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: ((context) => ProductPage(
                                        productData:
                                            recentShopProductsData[index],
                                      )),
                                ),
                              );
                            },
                            child: Container(
                              width: width * 0.3,
                              height: width * 0.2,
                              decoration: BoxDecoration(
                                color: white,
                                border: Border.all(
                                  width: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              padding: EdgeInsets.all(
                                width * 0.00625,
                              ),
                              margin: EdgeInsets.all(
                                width * 0.0125,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.network(
                                      image,
                                      fit: BoxFit.cover,
                                      width: width * 0.3,
                                      height: width * 0.3,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: width * 0.00625,
                                      left: width * 0.0125,
                                    ),
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: width * 0.05,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
