import 'package:Localsearch_User/page/main/vendor/brand/brand_page.dart';
import 'package:Localsearch_User/page/main/vendor/category/category_page.dart';
import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  Future<String> getName(
    int index,
    bool wantName, {
    Map<String, dynamic>? wantProductData,
  }) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List products = discountData['products'];
    // final List categories = discountData['categories'];
    final List brands = discountData['brands'];

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

      final String name = productData['productName'];
      final String imageUrl = productData['images'][0];

      return wantName ? name : imageUrl;
    }

    // CATEGORY
    // if (categories.isNotEmpty) {
    //   final categoryId = categories[0];

    //   final categorySnap = await store
    //       .collection('Business')
    //       .doc('Data')
    //       .collection('Category')
    //       .doc(categoryId)
    //       .get();

    //   final categoryData = categorySnap.data()!;

    //   final name = categoryData['categoryName'];
    //   final imageUrl = categoryData['imageUrl'];

    //   return wantName ? name : imageUrl;
    // }

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

      final name = brandData['brandName'];
      final imageUrl = brandData['imageUrl'];

      return wantName ? name : imageUrl;
    }
    return '';
  }

  // GET PRODUCT DATA
  Future<Map<String, dynamic>> getProductData(int index) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List products = discountData['products'];

    final productId = products[0];

    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    return productData;
  }

  // GET CATEGORY ID
  Future<String> getCategoryId(int index) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List categories = discountData['categories'];

    final categoryId = categories[0];

    return categoryId;
  }

  // GET BRAND ID
  Future<String> getBrandId(int index) async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.allDiscount[index]['discountId'])
        .get();

    final discountData = discountSnap.data()!;
    final List brands = discountData['brands'];

    final brandId = brands[0];

    return brandId;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.00125,
      ),
      child: SizedBox(
        width: width,
        height: width * 0.35,
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
            final name = currentDiscount['discountName'];
            final amount = currentDiscount['discountAmount'];
            final isPercent = currentDiscount['isPercent'];
            final List products = currentDiscount['products'];
            final List categories = currentDiscount['categories'];
            final List brands = currentDiscount['brands'];
            // final endDate = currentDiscount['discountEndDateTime'];

            return Padding(
              padding: EdgeInsets.all(width * 0.0125),
              child: GestureDetector(
                onTap: () async {
                  if (products.isNotEmpty) {
                    final productData = await getProductData(index);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductPage(
                            productData: productData,
                          ),
                        ),
                      );
                    }
                  } else if (categories.isNotEmpty) {
                    final categoryId = await getCategoryId(index);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => CategoryPage(
                                categoryName: categoryId,
                                vendorType: widget.vendorType,
                              )),
                        ),
                      );
                    }
                  } else if (brands.isNotEmpty) {
                    final brandId = await getBrandId(index);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: ((context) => BrandPage(
                                brandId: brandId,
                              )),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: width * 0.25,
                  // padding: EdgeInsets.all(
                  //   width * 0.00325,
                  // ),
                  decoration: BoxDecoration(
                    color: white,
                    border: Border.all(
                      width: 0.125,
                      color: black,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                                    borderRadius: BorderRadius.circular(2),
                                    child: Image.network(
                                      snapshot.data ??
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/ProhibitionSign2.svg/800px-ProhibitionSign2.svg.png',
                                      fit: BoxFit.cover,
                                      width: width * 0.25,
                                      height: width * 0.25,
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
                              child: CircularProgressIndicator(),
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
                                  snapshot.data ?? name,
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
              ),
            );
          }),
        ),
      ),
    );
  }
}
