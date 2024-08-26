import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Localsearch_User/page/main/vendor/brand/brand_page.dart';
import 'package:Localsearch_User/page/main/vendor/category/category_page.dart';
import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/shimmer_skeleton_container.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({
    super.key,
    required this.discountId,
  });

  final String discountId;

  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isFit = false;
  bool isGridView = true;

  // GET PRODUCT DATA
  Future<List<Map<String, dynamic>>> getProductData() async {
    List<Map<String, dynamic>> myProducts = [];

    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    for (var product in productsSnap.docs) {
      final productData = product.data();

      if (productData['discountId'] == widget.discountId) {
        myProducts.add(productData);
      }
    }

    return myProducts;
  }

  // GET BRAND DATA
  Future<List<Map<String, dynamic>>> getBrandData() async {
    List<Map<String, dynamic>> myBrands = [];

    final brandsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Brands')
        .get();

    for (var brand in brandsSnap.docs) {
      final brandData = brand.data();

      if (brandData['discountId'] == widget.discountId) {
        myBrands.add(brandData);
      }
    }

    return myBrands;
  }

  // GET CATEGORY DATA
  Future<List<Map<String, dynamic>>> getCategoryData(String vendorId) async {
    List<Map<String, dynamic>> myCategories = [];

    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final type = vendorData['Type'];

    final categorySnap = await store
        .collection('Business')
        .doc('Special Categories')
        .collection(type)
        .get();

    for (var category in categorySnap.docs) {
      final categoryData = category.data();

      final categoryName = categoryData['specialCategoryName'];
      final categoryImageUrl = categoryData['specialCategoryImageUrl'];
      final discountId = categoryData['discountId'];

      if (discountId == widget.discountId) {
        myCategories.add({
          categoryName: categoryImageUrl,
        });
      }
    }

    return myCategories;
  }

  // CHANGE FIT
  void changeFit() {
    setState(() {
      isFit = !isFit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final discountStream = store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.discountId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(),
      body: LayoutBuilder(
        builder: ((context, constraints) {
          double width = constraints.maxWidth;

          return SingleChildScrollView(
            child: StreamBuilder(
              stream: discountStream,
              builder: ((context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Something went wrong',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }

                if (snapshot.hasData) {
                  final discountData = snapshot.data!;

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.0225,
                      vertical: width * 0.0125,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE
                        Container(
                          width: width,
                          height: width * 9 / 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: primaryDark2,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onTap: changeFit,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                              child: InteractiveViewer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          discountData['discountImageUrl'],
                                        ),
                                        fit: isFit ? null : BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // NAME
                        Container(
                          width: width,
                          decoration: BoxDecoration(
                            color: primary2.withOpacity(0.125),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(
                            width * 0.0125,
                          ),
                          margin: EdgeInsets.symmetric(
                            vertical: width * 0.0133,
                            horizontal: width * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NAME',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                discountData['discountName'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05833,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // AMOUNT
                        Container(
                          width: width,
                          decoration: BoxDecoration(
                            color: primary2.withOpacity(0.125),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(
                            width * 0.0125,
                          ),
                          margin: EdgeInsets.symmetric(
                            vertical: width * 0.0133,
                            horizontal: width * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AMOUNT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                discountData['isPercent']
                                    ? '${discountData['discountAmount'].toString()} %'
                                    : 'Rs. ${discountData['discountAmount'].toString()}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05833,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // START DATE
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: width * 0.0133,
                            horizontal: width * 0.01,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: width * 0.025,
                              horizontal: width * 0.025,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'START DATE',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('d MMM yy').format(
                                          discountData['discountStartDateTime']
                                              .toDate()),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05833,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // END DATE
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: width * 0.0133,
                            horizontal: width * 0.01,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: width * 0.025,
                              horizontal: width * 0.025,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'END DATE',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('d MMM yy').format(
                                        discountData['discountEndDateTime']
                                            .toDate(),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05833,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // PRODUCTS
                        discountData['isProducts']
                            ? ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0225,
                                ),
                                backgroundColor: primary2.withOpacity(0.25),
                                collapsedBackgroundColor:
                                    primary2.withOpacity(0.33),
                                textColor: primaryDark.withOpacity(0.9),
                                collapsedTextColor: primaryDark,
                                iconColor: primaryDark2.withOpacity(0.9),
                                collapsedIconColor: primaryDark2,
                                shape: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryDark.withOpacity(0.1),
                                  ),
                                ),
                                collapsedShape: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryDark.withOpacity(0.33),
                                  ),
                                ),
                                title: Text(
                                  'Products',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.06,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isGridView = !isGridView;
                                    });
                                  },
                                  icon: Icon(
                                    isGridView
                                        ? FeatherIcons.list
                                        : FeatherIcons.grid,
                                  ),
                                  tooltip: isGridView ? "List" : 'Grid',
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                      vertical: width * 0.0125,
                                    ),
                                    child: FutureBuilder(
                                      future: getProductData(),
                                      builder: ((context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Center(
                                            child: Text(
                                              overflow: TextOverflow.ellipsis,
                                              'Something went wrong',
                                            ),
                                          );
                                        }

                                        if (snapshot.hasData) {
                                          return SafeArea(
                                            child: isGridView
                                                // PRODUCTS IN GRIDVIEW
                                                ? GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        ClampingScrollPhysics(),
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      childAspectRatio: 0.675,
                                                    ),
                                                    itemCount:
                                                        snapshot.data!.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final productData =
                                                          snapshot.data![index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  ((context) =>
                                                                      ProductPage(
                                                                        productData:
                                                                            productData,
                                                                      )),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: primary2
                                                                .withOpacity(
                                                              0.125,
                                                            ),
                                                            border: Border.all(
                                                              width: 0.25,
                                                              color:
                                                                  primaryDark,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              2,
                                                            ),
                                                          ),
                                                          padding:
                                                              EdgeInsets.all(
                                                            width * 0.00625,
                                                          ),
                                                          margin:
                                                              EdgeInsets.all(
                                                            width * 0.00625,
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Center(
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    2,
                                                                  ),
                                                                  child: Image
                                                                      .network(
                                                                    productData[
                                                                        'images'][0],
                                                                    width:
                                                                        width *
                                                                            0.5,
                                                                    height:
                                                                        width *
                                                                            0.5,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.fromLTRB(
                                                                          width *
                                                                              0.0125,
                                                                          width *
                                                                              0.0125,
                                                                          width *
                                                                              0.0125,
                                                                          0,
                                                                        ),
                                                                        child:
                                                                            SizedBox(
                                                                          width:
                                                                              width * 0.275,
                                                                          child:
                                                                              Text(
                                                                            productData['productName'],
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: width * 0.05,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.fromLTRB(
                                                                          width *
                                                                              0.0125,
                                                                          0,
                                                                          width *
                                                                              0.0125,
                                                                          0,
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          productData['productPrice'] != '' && productData['productPrice'] != null
                                                                              ? 'Rs. ${productData['productPrice']}'
                                                                              : 'N/A',
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          maxLines:
                                                                              1,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                width * 0.04,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    })
                                                // PRODUCTS IN LISTVIEW
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    itemCount:
                                                        snapshot.data!.length,
                                                    itemBuilder:
                                                        ((context, index) {
                                                      final productData =
                                                          snapshot.data![index];
                                                      return Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal:
                                                              width * 0.000625,
                                                          vertical:
                                                              width * 0.02,
                                                        ),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            Navigator.of(
                                                                    context)
                                                                .push(
                                                              MaterialPageRoute(
                                                                builder:
                                                                    ((context) =>
                                                                        ProductPage(
                                                                          productData:
                                                                              productData,
                                                                        )),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: white,
                                                              border:
                                                                  Border.all(
                                                                width: 0.25,
                                                                color:
                                                                    primaryDark,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                4,
                                                              ),
                                                            ),
                                                            child: ListTile(
                                                              visualDensity:
                                                                  VisualDensity
                                                                      .standard,
                                                              leading: Padding(
                                                                padding: EdgeInsets
                                                                    .all(width *
                                                                        0.0125),
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    4,
                                                                  ),
                                                                  child: Image
                                                                      .network(
                                                                    productData[
                                                                        'images'][0],
                                                                    width:
                                                                        width *
                                                                            0.15,
                                                                    height:
                                                                        width *
                                                                            0.15,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                              ),
                                                              title: Text(
                                                                productData[
                                                                    'productName'],
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      width *
                                                                          0.0525,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              subtitle: Text(
                                                                productData['productPrice'] !=
                                                                            '' &&
                                                                        productData['productPrice'] !=
                                                                            null
                                                                    ? productData[
                                                                        'productPrice']
                                                                    : 'N/A',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      width *
                                                                          0.035,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                          );
                                        }

                                        return SafeArea(
                                          child: isGridView
                                              ? GridView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      ClampingScrollPhysics(),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing: 0,
                                                    mainAxisSpacing: 0,
                                                    childAspectRatio: width *
                                                        0.5 /
                                                        width *
                                                        1.45,
                                                  ),
                                                  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        vertical: width * 0.02,
                                                        horizontal:
                                                            width * 0.00575,
                                                      ),
                                                      child: GridViewSkeleton(
                                                        width: width,
                                                        isPrice: true,
                                                        isDelete: true,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  itemCount: 4,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Padding(
                                                      padding: EdgeInsets.all(
                                                        width * 0.02,
                                                      ),
                                                      child: ListViewSkeleton(
                                                        width: width,
                                                        isPrice: true,
                                                        height: 30,
                                                        isDelete: true,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              )
                            : Container(),

                        // BRANDS
                        discountData['isBrands']
                            ? ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0225,
                                ),
                                backgroundColor: primary2.withOpacity(0.25),
                                collapsedBackgroundColor:
                                    primary2.withOpacity(0.33),
                                textColor: primaryDark.withOpacity(0.9),
                                collapsedTextColor: primaryDark,
                                iconColor: primaryDark2.withOpacity(0.9),
                                collapsedIconColor: primaryDark2,
                                shape: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryDark.withOpacity(0.1),
                                  ),
                                ),
                                collapsedShape: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryDark.withOpacity(0.33),
                                  ),
                                ),
                                title: Text(
                                  'Brands',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.06,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isGridView = !isGridView;
                                    });
                                  },
                                  icon: Icon(
                                    isGridView
                                        ? FeatherIcons.list
                                        : FeatherIcons.grid,
                                  ),
                                  tooltip: isGridView ? "List" : 'Grid',
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                      vertical: width * 0.0125,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              isGridView = !isGridView;
                                            });
                                          },
                                          icon: Icon(
                                            isGridView
                                                ? FeatherIcons.list
                                                : FeatherIcons.grid,
                                          ),
                                        ),
                                        FutureBuilder(
                                          future: getBrandData(),
                                          builder: ((context, snapshot) {
                                            if (snapshot.hasError) {
                                              return const Center(
                                                child: Text(
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  'Something went wrong',
                                                ),
                                              );
                                            }

                                            if (snapshot.hasData) {
                                              return SafeArea(
                                                child: isGridView
                                                    ? GridView.builder(
                                                        shrinkWrap: true,
                                                        physics:
                                                            ClampingScrollPhysics(),
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 2,
                                                          childAspectRatio:
                                                              0.75,
                                                        ),
                                                        itemCount: snapshot
                                                            .data!.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final brandData =
                                                              snapshot
                                                                  .data![index];

                                                          return GestureDetector(
                                                            onTap: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      ((context) =>
                                                                          BrandPage(
                                                                            brandId:
                                                                                brandData['brandId'],
                                                                          )),
                                                                ),
                                                              );
                                                            },
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: primary2
                                                                    .withOpacity(
                                                                  0.125,
                                                                ),
                                                                border:
                                                                    Border.all(
                                                                  width: 0.25,
                                                                  color:
                                                                      primaryDark,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  2,
                                                                ),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                width * 0.00625,
                                                              ),
                                                              margin: EdgeInsets
                                                                  .all(
                                                                width * 0.00625,
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Center(
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                        2,
                                                                      ),
                                                                      child: Image
                                                                          .network(
                                                                        brandData[
                                                                            'imageUrl'],
                                                                        width: width *
                                                                            0.5,
                                                                        height: width *
                                                                            0.5,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .fromLTRB(
                                                                      width *
                                                                          0.0125,
                                                                      width *
                                                                          0.0125,
                                                                      width *
                                                                          0.0125,
                                                                      0,
                                                                    ),
                                                                    child:
                                                                        SizedBox(
                                                                      width: width *
                                                                          0.275,
                                                                      child:
                                                                          Text(
                                                                        brandData[
                                                                            'brandName'],
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              width * 0.05,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                    : ListView.builder(
                                                        shrinkWrap: true,
                                                        physics:
                                                            const ClampingScrollPhysics(),
                                                        itemCount: snapshot
                                                            .data!.length,
                                                        itemBuilder:
                                                            ((context, index) {
                                                          final brandData =
                                                              snapshot
                                                                  .data![index];
                                                          return Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal:
                                                                  width *
                                                                      0.000625,
                                                              vertical:
                                                                  width * 0.02,
                                                            ),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .push(
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        ((context) =>
                                                                            BrandPage(
                                                                              brandId: brandData['brandId'],
                                                                            )),
                                                                  ),
                                                                );
                                                              },
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: white,
                                                                  border: Border
                                                                      .all(
                                                                    width: 0.25,
                                                                    color:
                                                                        primaryDark,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    4,
                                                                  ),
                                                                ),
                                                                child: ListTile(
                                                                  visualDensity:
                                                                      VisualDensity
                                                                          .standard,
                                                                  leading:
                                                                      Padding(
                                                                    padding: EdgeInsets
                                                                        .all(width *
                                                                            0.0125),
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                        4,
                                                                      ),
                                                                      child: Image
                                                                          .network(
                                                                        brandData[
                                                                            'imageUrl'],
                                                                        width: width *
                                                                            0.15,
                                                                        height: width *
                                                                            0.15,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  title: Text(
                                                                    brandData[
                                                                        'brandName'],
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          width *
                                                                              0.0525,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                              );
                                            }

                                            return SafeArea(
                                              child: isGridView
                                                  ? GridView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          ClampingScrollPhysics(),
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 2,
                                                        crossAxisSpacing: 0,
                                                        mainAxisSpacing: 0,
                                                        childAspectRatio:
                                                            width *
                                                                0.5 /
                                                                width *
                                                                1.45,
                                                      ),
                                                      itemCount: 4,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            vertical:
                                                                width * 0.02,
                                                            horizontal:
                                                                width * 0.00575,
                                                          ),
                                                          child:
                                                              GridViewSkeleton(
                                                            width: width,
                                                            isPrice: true,
                                                            isDelete: true,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : ListView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          const ClampingScrollPhysics(),
                                                      itemCount: 4,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                            width * 0.02,
                                                          ),
                                                          child:
                                                              ListViewSkeleton(
                                                            width: width,
                                                            isPrice: true,
                                                            height: 30,
                                                            isDelete: true,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Container(),

                        // CATEGORY
                        discountData['isCategories']
                            ? ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: EdgeInsets.symmetric(
                                  horizontal: width * 0.0225,
                                ),
                                backgroundColor: primary2.withOpacity(0.25),
                                collapsedBackgroundColor:
                                    primary2.withOpacity(0.33),
                                textColor: primaryDark.withOpacity(0.9),
                                collapsedTextColor: primaryDark,
                                iconColor: primaryDark2.withOpacity(0.9),
                                collapsedIconColor: primaryDark2,
                                shape: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryDark.withOpacity(0.1),
                                  ),
                                ),
                                collapsedShape: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryDark.withOpacity(0.33),
                                  ),
                                ),
                                title: Text(
                                  'Categories',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.06,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isGridView = !isGridView;
                                    });
                                  },
                                  icon: Icon(
                                    isGridView
                                        ? FeatherIcons.list
                                        : FeatherIcons.grid,
                                  ),
                                  tooltip: isGridView ? "List" : 'Grid',
                                ),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0225,
                                      vertical: width * 0.02125,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // TEXTFIELD
                                            Expanded(
                                              child: TextField(
                                                controller: searchController,
                                                autocorrect: false,
                                                onTapOutside: (event) =>
                                                    FocusScope.of(context)
                                                        .unfocus(),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: 'Search ...',
                                                  border: OutlineInputBorder(),
                                                ),
                                                onChanged: (value) {
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  isGridView = !isGridView;
                                                });
                                              },
                                              icon: Icon(
                                                isGridView
                                                    ? FeatherIcons.list
                                                    : FeatherIcons.grid,
                                              ),
                                              tooltip: isGridView
                                                  ? 'List View'
                                                  : 'Grid View',
                                            ),
                                          ],
                                        ),
                                        FutureBuilder(
                                          future: getCategoryData(
                                              discountData['vendorId']),
                                          builder: ((context, snapshot) {
                                            if (snapshot.hasError) {
                                              return const Center(
                                                child: Text(
                                                  'Something went wrong',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }

                                            if (snapshot.hasData) {
                                              return SafeArea(
                                                child: isGridView
                                                    // CATEGORIES IN GRIDVIEW
                                                    ? GridView.builder(
                                                        shrinkWrap: true,
                                                        physics:
                                                            ClampingScrollPhysics(),
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 2,
                                                          childAspectRatio:
                                                              0.68,
                                                        ),
                                                        itemCount: snapshot
                                                            .data!.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final categoryData =
                                                              snapshot
                                                                  .data![index];
                                                          final categoryName =
                                                              categoryData.keys
                                                                      .toList()[
                                                                  index];
                                                          final categoryImageUrl =
                                                              categoryData
                                                                      .values
                                                                      .toList()[
                                                                  index];

                                                          return GestureDetector(
                                                            onTap: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      ((context) =>
                                                                          CategoryPage(
                                                                            categoryName:
                                                                                categoryName,
                                                                            vendorType:
                                                                                discountData['vendor'],
                                                                          )),
                                                                ),
                                                              );
                                                            },
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: primary2
                                                                    .withOpacity(
                                                                  0.125,
                                                                ),
                                                                border:
                                                                    Border.all(
                                                                  width: 0.25,
                                                                  color:
                                                                      primaryDark,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  2,
                                                                ),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                width * 0.00625,
                                                              ),
                                                              margin: EdgeInsets
                                                                  .all(
                                                                width * 0.00625,
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Center(
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                        2,
                                                                      ),
                                                                      child: Image
                                                                          .network(
                                                                        categoryImageUrl,
                                                                        width: width *
                                                                            0.5,
                                                                        height: width *
                                                                            0.5,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Padding(
                                                                            padding:
                                                                                EdgeInsets.fromLTRB(
                                                                              width * 0.0125,
                                                                              width * 0.0125,
                                                                              width * 0.0125,
                                                                              0,
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              categoryName,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                              style: TextStyle(
                                                                                fontSize: width * 0.055,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                    : ListView.builder(
                                                        shrinkWrap: true,
                                                        physics:
                                                            ClampingScrollPhysics(),
                                                        itemCount: snapshot
                                                            .data!.length,
                                                        itemBuilder:
                                                            ((context, index) {
                                                          final categoryData =
                                                              snapshot
                                                                  .data![index];
                                                          final categoryName =
                                                              categoryData.keys
                                                                      .toList()[
                                                                  index];
                                                          final categoryImageUrl =
                                                              categoryData
                                                                      .values
                                                                      .toList()[
                                                                  index];

                                                          return Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                              horizontal:
                                                                  width *
                                                                      0.000625,
                                                              vertical:
                                                                  width * 0.02,
                                                            ),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .push(
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        ((context) =>
                                                                            CategoryPage(
                                                                              categoryName: categoryName,
                                                                              vendorType: discountData['vendorId'],
                                                                            )),
                                                                  ),
                                                                );
                                                              },
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: primary2
                                                                      .withOpacity(
                                                                    0.5,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    8,
                                                                  ),
                                                                ),
                                                                child: ListTile(
                                                                  leading:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      4,
                                                                    ),
                                                                    child: Image
                                                                        .network(
                                                                      categoryImageUrl,
                                                                      width: width *
                                                                          0.1125,
                                                                      height: width *
                                                                          0.1125,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                  title: Text(
                                                                    categoryName,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          width *
                                                                              0.0525,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                              );
                                            }

                                            return SafeArea(
                                              child: isGridView
                                                  ? GridView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          ClampingScrollPhysics(),
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 2,
                                                        crossAxisSpacing: 0,
                                                        mainAxisSpacing: 0,
                                                        childAspectRatio:
                                                            width *
                                                                0.5 /
                                                                width *
                                                                1.545,
                                                      ),
                                                      itemCount: 4,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                            vertical:
                                                                width * 0.02,
                                                          ),
                                                          child:
                                                              GridViewSkeleton(
                                                            width: width,
                                                            isPrice: false,
                                                            isDelete: true,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount: 4,
                                                      physics:
                                                          ClampingScrollPhysics(),
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                            width * 0.02,
                                                          ),
                                                          child:
                                                              ListViewSkeleton(
                                                            width: width,
                                                            isPrice: false,
                                                            height: 30,
                                                            isDelete: true,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
