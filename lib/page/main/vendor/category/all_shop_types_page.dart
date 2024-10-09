import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:image/image.dart' as img;
// import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:localsearch/page/main/vendor/home/products/shop_categories_page.dart';
import 'package:localsearch/utils/colors.dart';

class AllShopTypesPage extends StatefulWidget {
  const AllShopTypesPage({
    super.key,
    required this.shopTypesData,
  });

  final Map<String, dynamic> shopTypesData;

  @override
  State<AllShopTypesPage> createState() => _AllShopTypesPageState();
}

class _AllShopTypesPageState extends State<AllShopTypesPage> {
  final store = FirebaseFirestore.instance;
  Map<String, List>? shopTypesData;
  Map<String, Color>? colors;
  int noOf = 10;
  bool isLoadMore = false;
  final scrollController = ScrollController();

  // INIT STATE
  @override
  void initState() {
    scrollController.addListener(scrollListener);
    getOrder();
    getTopColor();
    super.initState();
  }

  // DISPOSE
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  // GET ORDER
  Future<void> getOrder() async {
    // GET COLOR
    Color getColor(String colorString) {
      var hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      if (hexColor.length == 8) {
        return Color(int.parse('0x$hexColor'));
      }
      return Color(0xFF000000);
    }

    final orderSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Shop Types Order')
        .get();

    final orderData = orderSnap.data()!;

    final Map<String, dynamic> order = orderData['shopTypesOrder'];

    final shopTypesSnap = await store
        .collection('Shop Types And Category Data')
        .doc('Shop Types Data')
        .get();

    final myShopTypesData = shopTypesSnap.data()!;

    final Map<String, dynamic> shopTypes = myShopTypesData['shopTypesData'];

    final Map<String, List> sortedShopTypesData = {};
    for (int i = 0; i < order.length; i++) {
      final stringI = i.toString();
      final categoryData = order[stringI];
      final categoryName = categoryData[0];
      final categoryColor = getColor(categoryData[1]);
      final categoryImageUrl = shopTypes[categoryName];
      sortedShopTypesData[categoryName] = [
        categoryImageUrl,
        categoryColor,
      ];
    }

    setState(() {
      shopTypesData = sortedShopTypesData;
    });
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

  // GET CATEGORY COLORS
  // Future<void> getCategoryColors() async {
  //   List<List<dynamic>> tempCategories = [];
  //   for (int i = 0; i < businessCategories.length; i++) {
  //     final String name = businessCategories[i][0];
  //     final String imageUrl = businessCategories[i][1];
  //     final Color color = await calculateTopLineColor(imageUrl);
  //     tempCategories.add([name, imageUrl, color]);
  //     if (mounted) {
  //       setState(() {
  //         businessCategory = tempCategories;
  //         isData = true;
  //       });
  //     }
  //   }
  // }

  // GET TOP COLOR
  Future<void> getTopColor() async {
    Map<String, Color> myColors = {};

    for (var entry in widget.shopTypesData.entries) {
      try {
        final ByteData imageData =
            await NetworkAssetBundle(Uri.parse(entry.value)).load('');
        final Uint8List imageBytes = imageData.buffer.asUint8List();
        final img.Image image = img.decodeImage(imageBytes)!;
        double redSum = 0, greenSum = 0, blueSum = 0;
        final int width = image.width;
        for (int x = 0; x < width; x++) {
          final color = image.getPixel(x, 0);
          redSum += color.r;
          greenSum += color.g;
          blueSum += color.b;
        }
        final int pixelCount = width;
        final Color averageColor = Color.fromRGBO(
          redSum ~/ pixelCount,
          greenSum ~/ pixelCount,
          blueSum ~/ pixelCount,
          1.0,
        );
        myColors.addAll({
          entry.key: averageColor,
        });
      } catch (e) {
        myColors.addAll({
          entry.key: white,
        });
      }
    }

    if (mounted) {
      setState(() {
        colors = myColors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Shop Types'),
        actions: [
          IconButton(
            onPressed: () async {},
            icon: const Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: 'Help',
          ),
        ],
      ),
      body: /*!isData
          ? SizedBox(
              width: width,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7525,
                ),
                itemCount: 17,
                itemBuilder: ((context, index) {
                  return Padding(
                    padding: EdgeInsets.all(width * 0.0225),
                    child: SkeletonContainer(
                      width: width,
                      height: width,
                    ),
                  );
                }),
              ),
            )
          :*/
          shopTypesData == null
              ? Container()
              : SafeArea(
                  child: GridView.builder(
                      controller: scrollController,
                      cacheExtent: height * 1.5,
                      addAutomaticKeepAlives: true,
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7525,
                      ),
                      physics: const ClampingScrollPhysics(),
                      itemCount: noOf > shopTypesData!.length
                          ? shopTypesData!.length
                          : noOf,
                      itemBuilder: (context, index) {
                        final String name = shopTypesData!.keys.toList()[index];
                        final String imageUrl =
                            shopTypesData!.values.toList()[index][0];
                        final Color color =
                            shopTypesData!.values.toList()[index][1];

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShopCategoriesPage(
                                  shopType: name,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                    padding: EdgeInsets.all(width * 0.025),
                                    child: AutoSizeText(
                                      name.toString().trim().toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: black,
                                        fontSize: width * 0.0425,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8),
                                  ),
                                  child: Image.network(
                                    imageUrl.toString().trim(),
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    repeat: ImageRepeat.noRepeat,
                                  ),
                                ),
                                // ClipRRect(
                                //   borderRadius: const BorderRadius.vertical(
                                //     top: Radius.circular(8),
                                //   ),
                                //   child: Image.network(
                                //     imageUrl,
                                //     fit: BoxFit.cover,
                                //     filterQuality: FilterQuality.low,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        );
                      }),
                ),
    );
  }
}
