import 'package:Localsearch_User/models/household_types.dart';
import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:Localsearch_User/page/main/vendor/home/shop_categories_page.dart';
import 'package:Localsearch_User/utils/colors.dart';

class AllShopTypesPage extends StatefulWidget {
  const AllShopTypesPage({super.key});

  @override
  State<AllShopTypesPage> createState() => _AllShopTypesPageState();
}

class _AllShopTypesPageState extends State<AllShopTypesPage> {
  // INIT STATE
  @override
  void initState() {
    // getCategoryColors();
    super.initState();
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

  // // CALCULATE TOP LINE COLOR
  // Future<Color> calculateTopLineColor(String imageUrl) async {
  //   try {
  //     final ByteData imageData =
  //         await NetworkAssetBundle(Uri.parse(imageUrl)).load('');
  //     final Uint8List imageBytes = imageData.buffer.asUint8List();
  //     final img.Image image = img.decodeImage(imageBytes)!;

  //     double redSum = 0, greenSum = 0, blueSum = 0;
  //     final int width = image.width;

  //     for (int x = 0; x < width; x++) {
  //       final color = image.getPixel(x, 0);
  //       redSum += color.r;
  //       greenSum += color.g;
  //       blueSum += color.b;
  //     }

  //     final int pixelCount = width;
  //     final Color averageColor = Color.fromRGBO(
  //       redSum ~/ pixelCount,
  //       greenSum ~/ pixelCount,
  //       blueSum ~/ pixelCount,
  //       1.0,
  //     );

  //     return averageColor;
  //   } catch (e) {
  //     return white;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          SafeArea(
        child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7525,
            ),
            physics: const ClampingScrollPhysics(),
            itemCount: householdTypes.length,
            itemBuilder: (context, index) {
              final String name = householdTypes.keys.toList()[index];
              final String imageUrl = householdTypes.values.toList()[index];
              // final Color color = businessCategories[index][2];

              return GestureDetector(
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
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.bottomLeft,
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                          ),
                          padding: EdgeInsets.all(width * 0.025),
                          child: Text(
                            name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
