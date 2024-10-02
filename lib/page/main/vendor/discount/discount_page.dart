import 'package:localsearch/widgets/shimmer_skeleton_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localsearch/page/main/vendor/brand/brand_page.dart';
import 'package:localsearch/page/main/vendor/category/category_page.dart';
import 'package:localsearch/page/main/vendor/product/product_page.dart';
import 'package:localsearch/utils/colors.dart';

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
  Map<String, dynamic> discountData = {};
  Map<String, dynamic> products = {};
  Map<String, dynamic> brands = {};
  Map<String, dynamic> categories = {};
  String? vendorId;
  bool isFit = false;
  bool isGridView = true;
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getDiscountData();
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // GET DISCOUNT DATA
  Future<void> getDiscountData() async {
    final discountSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Discounts')
        .doc(widget.discountId)
        .get();

    final myDiscountData = discountSnap.data()!;
    final myProducts = myDiscountData['products'];
    final myBrands = myDiscountData['brands'];
    final myCategories = myDiscountData['categories'];

    final myVendorId = myDiscountData['vendorId'];

    setState(() {
      vendorId = myVendorId;
      discountData = myDiscountData;
    });

    if (myDiscountData['isProducts']) {
      await getProducts(myProducts);
    } else if (myDiscountData['isBrands']) {
      await getBrands(myBrands);
    } else if (myDiscountData['isCategories']) {
      await getCategories(myVendorId, myCategories);
    }

    setState(() {
      isData = true;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts(List myProductIds) async {
    Map<String, dynamic> myProducts = {};

    for (var myProductId in myProductIds) {
      final productsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(myProductId)
          .get();

      final productData = productsSnap.data()!;
      final productId = productData['productId'];

      myProducts.addAll({
        productId: productData,
      });
    }
    setState(() {
      products = myProducts;
    });
  }

  // GET BRANDS
  Future<void> getBrands(List myBrandIds) async {
    Map<String, dynamic> myBrands = {};

    for (var myBrandId in myBrandIds) {
      final brandsSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Brands')
          .doc(myBrandId)
          .get();

      final brandData = brandsSnap.data()!;
      final brandId = brandData['brandId'];

      myBrands.addAll({
        brandId: brandData,
      });
    }

    setState(() {
      brands = myBrands;
      isData = true;
    });
  }

  // GET CATEGORIES
  Future<void> getCategories(String vendorId, List allCategories) async {
    Map<String, dynamic> myCategories = {};

    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final List shopTypes = vendorData['Type'];

    final categoriesSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Category Data')
        .get();

    final categoriesData = categoriesSnap.data()!;

    for (var shopType in shopTypes) {
      final Map<String, dynamic> categoryData =
          categoriesData['householdCategoryData'][shopType];

      categoryData.forEach((categoryName, categoryImageUrl) {
        if (allCategories.contains(categoryName)) {
          myCategories.addAll({
            categoryName: categoryImageUrl,
          });
        }
      });
    }

    setState(() {
      categories = myCategories;
    });
  }

  // CHANGE FIT
  void changeFit() {
    setState(() {
      isFit = !isFit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: !isData
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: ((context, constraints) {
                  final width = constraints.maxWidth;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.0225,
                        vertical: width * 0.0125,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          discountData['discountImageUrl'] == null
                              ? Center(
                                  child: Text('No Image'),
                                )
                              : Container(
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
                                                  discountData[
                                                          'discountImageUrl']
                                                      .toString()
                                                      .trim(),
                                                ),
                                                fit:
                                                    isFit ? null : BoxFit.cover,
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
                              color: white,
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
                                  discountData['discountName']
                                      .toString()
                                      .trim(),
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
                              color: white,
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
                                      ? '${(discountData['discountAmount'] as double).round().toString()} %'
                                      : 'Rs. ${(discountData['discountAmount'] as double).round().toString()}',
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            discountData[
                                                    'discountStartDateTime']
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    tooltip: isGridView ? 'List' : 'Grid',
                                  ),
                                  children: [
                                    products.isEmpty
                                        ? GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 0,
                                              mainAxisSpacing: 0,
                                              childAspectRatio:
                                                  width * 0.5 / width * 1.545,
                                            ),
                                            itemCount: 4,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: width * 0.02,
                                                ),
                                                child: GridViewSkeleton(
                                                  width: width,
                                                  isPrice: false,
                                                  isDelete: true,
                                                ),
                                              );
                                            },
                                          )
                                        : Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0125,
                                              vertical: width * 0.0125,
                                            ),
                                            child: isGridView
                                                // PRODUCTS IN GRIDVIEW
                                                ? GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      childAspectRatio: 0.65,
                                                    ),
                                                    itemCount: products.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final productData =
                                                          products.values
                                                              .toList()[index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      ProductPage(
                                                                productData:
                                                                    productData,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: white,
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
                                                                      SizedBox(
                                                                        width: width *
                                                                            0.4,
                                                                        child:
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
                                                                              Text(
                                                                            productData['productName'].toString().trim(),
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
                                                                      SizedBox(
                                                                        width: width *
                                                                            0.4,
                                                                        child:
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
                                                                            'Rs. ${(productData['productPrice'] as double).round()}',
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: width * 0.04,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
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
                                                    itemCount: products.length,
                                                    itemBuilder:
                                                        ((context, index) {
                                                      final productData =
                                                          products.values
                                                              .toList()[index];

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
                                                                    (context) =>
                                                                        ProductPage(
                                                                  productData:
                                                                      productData,
                                                                ),
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
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                  width *
                                                                      0.0125,
                                                                ),
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
                                                                        'productName']
                                                                    .toString()
                                                                    .trim(),
                                                                maxLines: 1,
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
                                                                'Rs. ${(productData['productPrice'] as double).round()}',
                                                                maxLines: 1,
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
                                    maxLines: 1,
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
                                    tooltip: isGridView ? 'List' : 'Grid',
                                  ),
                                  children: [
                                    brands.isEmpty
                                        ? GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 0,
                                              mainAxisSpacing: 0,
                                              childAspectRatio: 0.5 / 1.545,
                                            ),
                                            itemCount: 4,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: width * 0.02,
                                                ),
                                                child: GridViewSkeleton(
                                                  width: width,
                                                  isPrice: false,
                                                  isDelete: true,
                                                ),
                                              );
                                            },
                                          )
                                        : Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0125,
                                              vertical: width * 0.0125,
                                            ),
                                            child: isGridView
                                                ? GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      childAspectRatio: 0.725,
                                                    ),
                                                    itemCount: brands.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final brandData = brands
                                                          .values
                                                          .toList()[index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
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
                                                            color: white,
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
                                                                    brandData[
                                                                        'imageUrl'],
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
                                                                child: SizedBox(
                                                                  width: width *
                                                                      0.45,
                                                                  child: Text(
                                                                    brandData[
                                                                            'brandName']
                                                                        .toString()
                                                                        .trim(),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          width *
                                                                              0.05,
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
                                                    itemCount: brands.length,
                                                    itemBuilder:
                                                        ((context, index) {
                                                      final brandData = brands
                                                          .values
                                                          .toList()[index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      BrandPage(
                                                                brandId: brandData[
                                                                    'brandId'],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: white,
                                                            border: Border.all(
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
                                                          padding:
                                                              EdgeInsets.all(
                                                            width * 0.0125,
                                                          ),
                                                          margin: EdgeInsets
                                                              .symmetric(
                                                            horizontal: width *
                                                                0.006125,
                                                            vertical:
                                                                width * 0.0125,
                                                          ),
                                                          child: ListTile(
                                                            visualDensity:
                                                                VisualDensity
                                                                    .standard,
                                                            leading: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                4,
                                                              ),
                                                              child:
                                                                  Image.network(
                                                                brandData[
                                                                        'imageUrl']
                                                                    .toString()
                                                                    .trim(),
                                                                width: width *
                                                                    0.15,
                                                                height: width *
                                                                    0.15,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                            title: Text(
                                                              brandData[
                                                                      'brandName']
                                                                  .toString()
                                                                  .trim(),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
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
                                                      );
                                                    }),
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
                                    maxLines: 1,
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
                                    tooltip: isGridView ? 'List' : 'Grid',
                                  ),
                                  children: [
                                    categories.isEmpty
                                        ? GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 0,
                                              mainAxisSpacing: 0,
                                              childAspectRatio:
                                                  width * 0.5 / width * 1.545,
                                            ),
                                            itemCount: 4,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: width * 0.02,
                                                ),
                                                child: GridViewSkeleton(
                                                  width: width,
                                                  isPrice: false,
                                                  isDelete: true,
                                                ),
                                              );
                                            },
                                          )
                                        : Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.0225,
                                              vertical: width * 0.02125,
                                            ),
                                            child: isGridView
                                                // CATEGORIES IN GRIDVIEW
                                                ? GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      childAspectRatio: 0.68,
                                                    ),
                                                    itemCount:
                                                        categories.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final categoryName =
                                                          categories.keys
                                                              .toList()[index];
                                                      final categoryImageUrl =
                                                          categories.values
                                                              .toList()[index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  CategoryPage(
                                                                categoryName:
                                                                    categoryName,
                                                                vendorId:
                                                                    vendorId,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: white,
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
                                                                    categoryImageUrl,
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
                                                                              width * 0.4,
                                                                          child:
                                                                              Text(
                                                                            categoryName.toString().trim(),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: width * 0.055,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
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
                                                        const ClampingScrollPhysics(),
                                                    itemCount:
                                                        categories.length,
                                                    itemBuilder:
                                                        ((context, index) {
                                                      final categoryName =
                                                          categories.keys
                                                              .toList()[index];
                                                      final categoryImageUrl =
                                                          categories.values
                                                              .toList()[index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  CategoryPage(
                                                                categoryName:
                                                                    categoryName,
                                                                vendorId:
                                                                    vendorId,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              2,
                                                            ),
                                                            border: Border.all(
                                                              width: 0.25,
                                                            ),
                                                          ),
                                                          margin: EdgeInsets
                                                              .symmetric(
                                                            horizontal: width *
                                                                0.000625,
                                                            vertical:
                                                                width * 0.02,
                                                          ),
                                                          child: ListTile(
                                                            leading: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                4,
                                                              ),
                                                              child:
                                                                  Image.network(
                                                                categoryImageUrl
                                                                    .toString()
                                                                    .trim(),
                                                                width: width *
                                                                    0.1125,
                                                                height: width *
                                                                    0.1125,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                            title: Text(
                                                              categoryName
                                                                  .toString()
                                                                  .trim(),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
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
                                                      );
                                                    }),
                                                  ),
                                          ),
                                  ],
                                )
                              : Container(),
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
