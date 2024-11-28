import 'package:localsearch/page/main/vendor/discount/discount_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/widgets/loading_indicator.dart';

class VendorDiscounts extends StatefulWidget {
  const VendorDiscounts({
    super.key,
    required this.noOfDiscounts,
    required this.allDiscount,
    required this.vendorType,
  });

  final int noOfDiscounts;
  final List allDiscount;
  final List vendorType;

  @override
  State<VendorDiscounts> createState() => _VendorDiscountsState();
}

class _VendorDiscountsState extends State<VendorDiscounts> {
  final store = FirebaseFirestore.instance;
  int noOf = 16;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
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
      setState(() {
        noOf = noOf + 8;
      });
      setState(() {
        isLoadMore = false;
      });
    }
  }

  // GET NAME
  Future<String> getName(int index, bool wantName) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final String discountName = discountData['discountName'];
    final String? discountImageUrl = discountData['discountImageUrl'];
    final List products = discountData['products'];
    final List categories = discountData['categories'];
    final List brands = discountData['brands'];

    if (wantName) {
      return discountName;
    } else {
      if (discountImageUrl != null) {
        return discountImageUrl;
      } else {
        // PRODUCT
        if (products.isNotEmpty) {
          final productId = products[0];

          final productSnap = await store
              .collection('Business')
              .doc('Data')
              .collection('Products')
              .doc(productId)
              .get();

          final productData = productSnap.data()!;

          final String imageUrl = productData['images'][0];

          return imageUrl;
        }

        // CATEGORY
        if (categories.isNotEmpty) {
          final categoryName = categories[0];

          final justCategorySnap = await store
              .collection('Shop Types And Category Data')
              .doc('Just Category Data')
              .get();

          final categoryData = justCategorySnap.data()!;

          final householdCategories = categoryData['householdCategories'];

          final imageUrl = householdCategories[categoryName];

          return imageUrl;
        }

        // BRAND
        if (brands.isNotEmpty) {
          final brandId = brands[0];

          final brandSnap = await store
              .collection('Business')
              .doc('Data')
              .collection('Brands')
              .doc(brandId)
              .get();

          final brandData = brandSnap.data()!;

          final imageUrl = brandData['imageUrl'];

          return imageUrl;
        }
        return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.00125,
      ),
      child: SizedBox(
        width: width,
        height: width * 0.4125,
        child: ListView.builder(
          controller: scrollController,
          cacheExtent: height * 1.5,
          addAutomaticKeepAlives: true,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          physics: ClampingScrollPhysics(),
          itemCount: widget.allDiscount.length,
          itemBuilder: ((context, index) {
            final currentDiscount = widget.allDiscount[isLoadMore
                ? index == 0
                    ? 0
                    : index - 1
                : index];
            // final String? image = currentDiscount['discountImageUrl'];
            final id = currentDiscount['discountId'];
            final name = currentDiscount['discountName'];
            final amount = currentDiscount['discountAmount'];
            final isPercent = currentDiscount['isPercent'];

            return GestureDetector(
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DiscountPage(
                      discountId: id,
                    ),
                  ),
                );
              },
              child: Container(
                width: width * 0.3,
                decoration: BoxDecoration(
                  color: white,
                  border: Border.all(
                    width: 0.125,
                    color: black,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: EdgeInsets.all(width * 0.0125),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE
                    FutureBuilder(
                        future: getName(index, false),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    2,
                                  ),
                                  child: Image.network(
                                    snapshot.data ??
                                        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/ProhibitionSign2.svg/800px-ProhibitionSign2.svg.png',
                                    width: width * 0.3,
                                    height: width * 0.3,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(
                                    width * 0.00675,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(2),
                                      bottomRight: Radius.circular(4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(),
                                    ],
                                  ),
                                  child: Text(
                                    isPercent
                                        ? '$amount %'
                                        : 'Save Rs. $amount',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 255, 30, 14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              ],
                            );
                          }

                          return const Center(
                            child: LoadingIndicator(),
                          );
                        }),

                    // NAME
                    FutureBuilder(
                        future: getName(index, true),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.00625,
                              ),
                              child: Text(
                                snapshot.data ?? name.toString().trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                ),
                              ),
                            );
                          }

                          return Container();
                        }),
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
