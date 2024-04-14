import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/main/vendor/category/category_page.dart';
import 'package:find_easy_user/utils/colors.dart';
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
  Map categories = {};

  // INIT STATE
  @override
  void initState() {
    getCategories();
    super.initState();
  }

  // GET BRANDS
  Future<void> getCategories() async {
    Map category = {};
    final categoriesSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Category')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    for (var categoryData in categoriesSnap.docs) {
      final id = categoryData['categoryId'];
      final name = categoryData['categoryName'];
      final imageUrl = categoryData['imageUrl'] ?? '';

      category[id] = [name, imageUrl];
    }

    setState(() {
      categories = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Categories - ${categories.length}'),
      ),
      body: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
        ),
        itemCount: categories.length,
        itemBuilder: ((context, index) {
          final id = categories.keys.toList()[index];
          final name = categories[id][0];
          final imageUrl = categories[id][1];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: ((context) => CategoryPage(
                        categoryId: id,
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
