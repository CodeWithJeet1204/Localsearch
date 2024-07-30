import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localy_user/page/main/vendor/brand/brand_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/video_tutorial.dart';
import 'package:flutter/material.dart';

class AllBrandPage extends StatefulWidget {
  const AllBrandPage({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  State<AllBrandPage> createState() => _AllBrandPageState();
}

class _AllBrandPageState extends State<AllBrandPage> {
  final store = FirebaseFirestore.instance;
  Map brands = {};

  // INIT STATE
  @override
  void initState() {
    getBrands();
    super.initState();
  }

  // GET BRANDS
  Future<void> getBrands() async {
    Map brand = {};
    final brandsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Brands')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    for (var brandData in brandsSnap.docs) {
      final id = brandData['brandId'];
      final name = brandData['brandName'];
      final imageUrl = brandData['imageUrl'] ?? '';

      brand[id] = [name, imageUrl];
    }

    setState(() {
      brands = brand;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Brands - ${brands.length}'),
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
      body: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
        ),
        itemCount: brands.length,
        physics: ClampingScrollPhysics(),
        itemBuilder: ((context, index) {
          final id = brands.keys.toList()[index];
          final name = brands[id][0];
          final imageUrl = brands[id][1];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: ((context) => BrandPage(
                        brandId: id,
                      )),
                ),
              );
            },
            child: Container(
              color: white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      width: width * 0.3,
                      height: width * 0.3,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
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
