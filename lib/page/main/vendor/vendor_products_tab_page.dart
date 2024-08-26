import 'package:Localsearch_User/page/main/vendor/product/product_page.dart';
import 'package:Localsearch_User/page/main/vendor/vendor_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorProductsTabPage extends StatefulWidget {
  const VendorProductsTabPage({
    super.key,
    required this.width,
    required this.myProducts,
    required this.myProductSort,
    required this.myNumProductsLoaded,
    required this.height,
  });

  final double width;
  final double height;
  final String? myProductSort;
  final Map<String, dynamic> myProducts;
  final int myNumProductsLoaded;

  @override
  State<VendorProductsTabPage> createState() => _VendorProductsTabPageState();
}

class _VendorProductsTabPageState extends State<VendorProductsTabPage> {
  Map<String, dynamic> products = {};
  String? productSort;
  int numProductsLoaded = 0;

  // INIT STATE
  @override
  void initState() {
    products = widget.myProducts;
    productSort = widget.myProductSort;
    numProductsLoaded = widget.myNumProductsLoaded;
    super.initState();
  }

  // SORT PRODUCTS
  void sortProducts(EventSorting sorting) {
    List<MapEntry<String, dynamic>> sortedEntries =
        widget.myProducts.entries.toList();

    switch (sorting) {
      case EventSorting.recentlyAdded:
        sortedEntries.sort((a, b) =>
            (b.value[4] as Timestamp).compareTo(a.value[4] as Timestamp));
        break;
      case EventSorting.highestRated:
        sortedEntries.sort((a, b) {
          final ratingA = calculateAverageRating(a.value[3]);
          final ratingB = calculateAverageRating(b.value[3]);
          return ratingB.compareTo(ratingA);
        });
        break;
      case EventSorting.mostViewed:
        sortedEntries.sort((a, b) => ((b.value[5] as List).length)
            .compareTo((a.value[5] as List).length));
        break;
      case EventSorting.lowestPrice:
        sortedEntries.sort((a, b) {
          final priceA = double.parse(a.value[2]);
          final priceB = double.parse(b.value[2]);
          return priceA.compareTo(priceB);
        });
        break;
      case EventSorting.highestPrice:
        sortedEntries.sort((a, b) {
          final priceA = double.parse(a.value[2]);
          final priceB = double.parse(b.value[2]);
          return priceB.compareTo(priceA);
        });
        break;
    }

    setState(() {
      products = Map.fromEntries(sortedEntries);
    });
  }

  // CALCULATE AVERAGE RATINGS
  double calculateAverageRating(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;

    final allRatings = ratings.values.map((e) => e[0] as double).toList();

    final sum = allRatings.reduce((value, element) => value + element);

    final averageRating = sum / allRatings.length;

    return averageRating;
  }

  // GET SCREEN HEIGHT
  double getScreenHeight() {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    final availableHeight = screenHeight - paddingTop - paddingBottom;
    return availableHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          widget.myProducts.isEmpty
              ? Container()
              : SizedBox(
                  height: getScreenHeight() * 0.0675,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: widget.width * 0.01,
                      horizontal: widget.width * 0.0125,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.width * 0.0125,
                      ),
                      decoration: BoxDecoration(
                        color: primary3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        underline: const SizedBox(),
                        dropdownColor: primary2,
                        value: productSort,
                        iconEnabledColor: primaryDark,
                        items: [
                          'Recently Added',
                          'Highest Rated',
                          'Most Viewed',
                          'Price - Highest to Lowest',
                          'Price - Lowest to Highest'
                        ]
                            .map((e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            productSort = value;
                          });
                          try {
                            sortProducts(
                              value == 'Recently Added'
                                  ? EventSorting.recentlyAdded
                                  : value == 'Highest Rated'
                                      ? EventSorting.highestRated
                                      : value == 'Most Viewed'
                                          ? EventSorting.mostViewed
                                          : value == 'Price - Highest to Lowest'
                                              ? EventSorting.highestPrice
                                              : EventSorting.lowestPrice,
                            );
                          } catch (e) {
                            mySnackBar('Something went wrong', context);
                          }
                        },
                      ),
                    ),
                  ),
                ),

          // PRODUCTS
          products.isEmpty
              ? Container()
              : SizedBox(
                  width: widget.width,
                  height: getScreenHeight() * 0.5625,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: numProductsLoaded > products.length
                        ? products.length
                        : numProductsLoaded,
                    itemBuilder: ((context, index) {
                      final name = products.values.toList()[index][0];
                      final imageUrl = products.values.toList()[index][1];
                      final price = products.values.toList()[index][2];
                      final ratings = products.values.toList()[index][3];
                      final productData = products.values.toList()[index][6];
                      final rating = calculateAverageRating(ratings);

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: ((context) => ProductPage(
                                    productData: productData,
                                  )),
                            ),
                          );
                        },
                        child: Container(
                          width: widget.width,
                          // height: 150,
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.width * 0.0125,
                            vertical: widget.width * 0.0125,
                          ),
                          margin: EdgeInsets.all(
                            widget.width * 0.00625,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: index == 0
                                  ? const BorderSide(
                                      color: darkGrey,
                                      width: 0.25,
                                    )
                                  : BorderSide.none,
                              bottom: const BorderSide(
                                color: darkGrey,
                                width: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      width: widget.width * 0.3,
                                      height: widget.width * 0.3,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  rating == 0
                                      ? Text(
                                          'No Reviews',
                                          style: TextStyle(
                                            fontSize: widget.width * 0.03,
                                          ),
                                        )
                                      : Text('$rating ⭐'),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: widget.width * 0.6,
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: widget.width * 0.05,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    price == '' ? 'Rs. --' : 'Rs. $price',
                                    style: TextStyle(
                                      fontSize: widget.width * 0.04,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
  }
}
