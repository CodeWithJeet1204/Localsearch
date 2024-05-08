import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/main/vendor/category/category_page.dart';
import 'package:flutter/material.dart';

class AllCategoryPage extends StatefulWidget {
  const AllCategoryPage({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  State<AllCategoryPage> createState() => _AllCategoryPageState();
}

class _AllCategoryPageState extends State<AllCategoryPage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic>? shopData;
  Map<String, dynamic>? ownerData;
  Map categories = {};
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getVendorInfo();
    super.initState();
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo() async {
    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.vendorId)
        .get();

    final currentShopData = shopSnap.data()!;

    setState(() {
      shopData = currentShopData;
    });

    final ownerSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Users')
        .doc(widget.vendorId)
        .get();

    final currentOwnerData = ownerSnap.data()!;

    setState(() {
      ownerData = currentOwnerData;
    });
    print("Owner1: $ownerData");
    print("Shop1: $shopData");

    await getCategories();
  }

  // GET CATEGORIES
  Future<void> getCategories() async {
    Map category = {};
    final categoriesSnap = await store
        .collection('Business')
        .doc('Special Categories')
        .collection(shopData!['Type'])
        .get();

    print(categoriesSnap.docs.length);

    for (var categoryData in categoriesSnap.docs) {
      final List vendorIds = categoryData['vendorIds'];
      if (vendorIds.contains(widget.vendorId)) {
        final name = categoryData['specialCategoryName'] as String;
        final imageUrl = categoryData['specialCategoryImageUrl'] as String;

        category[name] = imageUrl;
      }
    }

    setState(() {
      categories = category;
      isData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Categories - ${categories.length}'),
      ),
      body: !isData
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: ((context, index) {
                final name = categories.keys.toList()[index];
                final imageUrl = categories.values.toList()[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: ((context) => CategoryPage(
                              categoryName: name,
                              vendorType: shopData!['Type'],
                            )),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.25,
                      ),
                    ),
                    margin: EdgeInsets.all(width * 0.0125),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            imageUrl,
                            width: width * 0.45,
                            height: width * 0.475,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width * 0.055,
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
