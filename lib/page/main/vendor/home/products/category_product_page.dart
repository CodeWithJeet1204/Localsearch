import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/page/main/vendor/category/products_result_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/loading_indicator.dart';
import 'package:localsearch/widgets/video_tutorial.dart';

class CategoryProductPage extends StatefulWidget {
  const CategoryProductPage({
    super.key,
    required this.shopType,
    required this.categoryName,
  });

  final String shopType;
  final String categoryName;

  @override
  State<CategoryProductPage> createState() => _CategoryProductPageState();
}

class _CategoryProductPageState extends State<CategoryProductPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  List? products;

  // INIT STATE
  @override
  void initState() {
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    final catalogueSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Catalogue')
        .get();

    final catalogueData = catalogueSnap.data()!;
    final productData = catalogueData['catalogueData'];
    final myProducts = productData[widget.shopType][widget.categoryName]!;

    setState(() {
      products = myProducts;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: products == null
            ? Center(
                child: LoadingIndicator(),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  return SizedBox(
                    width: width,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemCount: products!.length,
                      itemBuilder: (context, index) {
                        final productName = products![index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductsResultPage(
                                  productName: productName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: width,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: primary2.withOpacity(0.125),
                              border: Border(
                                bottom: BorderSide(
                                  width: 0.5,
                                  color: primaryDark2,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.all(width * 0.05),
                            child: Text(
                              productName,
                              style: TextStyle(
                                fontSize: width * 0.035,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
