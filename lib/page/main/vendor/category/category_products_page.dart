import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localy_user/page/main/vendor/product/product_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/skeleton_container.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.categoryName,
    required this.shopType,
  });

  final String categoryName;
  final String shopType;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> products = {};
  bool getData = false;

  // INIT STATE
  @override
  void initState() {
    getProducts();
    super.initState();
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    Map<String, dynamic> myProducts = {};
    // final categorySnap = await store
    //     .collection('Business')
    //     .doc('Special Categories')
    //     .collection(widget.shopType)
    //     .doc(widget.categoryName)
    //     .get();

    // final categoryData = categorySnap.data()!;

    // final List vendors = categoryData['vendors'];

    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .where('categoryId', isEqualTo: widget.categoryName)
        .where('categoryName', isEqualTo: widget.categoryName)
        .get();

    for (var productData in productsSnap.docs) {
      final id = productData.id;
      final name = productData['productName'];
      final price = productData['productPrice'];
      final imageUrl = productData['images'][0];
      final ratings = productData['ratings'];
      final myProductData = productData.data();
      myProducts[id] = [name, price, imageUrl, ratings, myProductData];
    }

    setState(() {
      products = myProducts;
      getData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
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
            icon: Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: "Help",
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.0125,
          vertical: width * 0.0166,
        ),
        child: !getData
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                ),
                itemCount: 6,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: EdgeInsets.all(width * 0.0225),
                    child: Container(
                      width: width * 0.28,
                      height: width * 0.3,
                      decoration: BoxDecoration(
                        color: lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SkeletonContainer(
                            width: width * 0.4,
                            height: width * 0.4,
                          ),
                          SkeletonContainer(
                            width: width * 0.4,
                            height: width * 0.04,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                ),
                itemCount: products.length,
                itemBuilder: ((context, index) {
                  final name = products.values.toList()[index][0];
                  final price = products.values.toList()[index][1];
                  final imageUrl = products.values.toList()[index][2];
                  final ratings = products.values.toList()[index][3];
                  final productData = products.values.toList()[index][4];

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.01,
                      vertical: width * 0.01,
                    ),
                    child: GestureDetector(
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
                        decoration: BoxDecoration(
                          color: white,
                          border: Border.all(
                            color: primaryDark,
                            width: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        255,
                                        92,
                                        78,
                                        1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0125,
                                      vertical: width * 0.00625,
                                    ),
                                    margin: EdgeInsets.all(
                                      width * 0.00625,
                                    ),
                                    child: Text(
                                      '${(ratings as Map).isEmpty ? '--' : ((ratings.values.map((e) => e?[0] ?? 0).toList().reduce((a, b) => a + b) / (ratings.values.isEmpty ? 1 : ratings.values.length)) as double).toStringAsFixed(1)} ⭐',
                                      style: const TextStyle(
                                        color: white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              price == ''
                                  ? Container()
                                  : Text(
                                      'Rs. $price',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
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
    );
  }
}
