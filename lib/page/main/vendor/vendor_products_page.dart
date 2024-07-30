import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localy_user/models/household_type_category_subCategory.dart';
import 'package:localy_user/widgets/snack_bar.dart';

class VendorProductsPage extends StatefulWidget {
  const VendorProductsPage({
    super.key,
    required this.vendorId,
    required this.products,
  });

  final String vendorId;
  final List products;

  @override
  State<VendorProductsPage> createState() => _VendorProductsPageState();
}

class _VendorProductsPageState extends State<VendorProductsPage> {
  final store = FirebaseFirestore.instance;
  Map<String, Map<String, List<String>>> categorizedProducts = {};
  bool isData = false;

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    try {
      final List<String> fetchedProducts = List<String>.from(widget.products);

      final Map<String, Map<String, List<String>>> tempCategorizedProducts = {};

      for (String product in fetchedProducts) {
        String? category;
        String? shopType;

        for (var type in householdTypeCategorySubCategory.keys) {
          final categories = householdTypeCategorySubCategory[type];
          if (categories != null) {
            for (var cat in categories.keys) {
              if (categories[cat]!.contains(product)) {
                category = cat;
                shopType = type;
                break;
              }
            }
            if (category != null) break;
          }
        }

        if (category != null && shopType != null) {
          if (!tempCategorizedProducts.containsKey(shopType)) {
            tempCategorizedProducts[shopType] = {};
          }
          if (!tempCategorizedProducts[shopType]!.containsKey(category)) {
            tempCategorizedProducts[shopType]![category] = [];
          }
          tempCategorizedProducts[shopType]![category]!.add(product);
        }
      }

      setState(() {
        categorizedProducts = tempCategorizedProducts;
        isData = true;
      });
    } catch (e) {
      mySnackBar('Error fetching data: $e', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
      ),
      body: SafeArea(
        child: !isData
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;

                return ListView(
                  children: categorizedProducts.entries.map((shopTypeEntry) {
                    final shopType = shopTypeEntry.key;
                    final categories = shopTypeEntry.value;

                    return Padding(
                      padding: EdgeInsets.all(width * 0.0225),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopType,
                            style: TextStyle(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ...categories.entries.map((categoryEntry) {
                            final category = categoryEntry.key;
                            final products = categoryEntry.value;

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: width * 0.0225,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: width * 0.0175,
                                    ),
                                    child: Text(
                                      '- $category',
                                      style: TextStyle(
                                        fontSize: width * 0.055,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ...products.map((product) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0375,
                                        vertical: width * 0.0125,
                                      ),
                                      child: Text(
                                        '◯ $product',
                                        style: TextStyle(
                                          fontSize: width * 0.05,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
      ),
    );
  }
}
