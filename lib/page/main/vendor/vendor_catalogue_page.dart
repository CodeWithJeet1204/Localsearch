import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/snack_bar.dart';

class VendorCataloguePage extends StatefulWidget {
  const VendorCataloguePage({
    super.key,
    required this.vendorId,
    required this.products,
  });

  final String vendorId;
  final List products;

  @override
  State<VendorCataloguePage> createState() => _VendorCataloguePageState();
}

class _VendorCataloguePageState extends State<VendorCataloguePage> {
  final store = FirebaseFirestore.instance;
  Map<String, Map<String, List<String>>> categorizedProducts = {};
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    try {
      final List<String> fetchedProducts = List<String>.from(widget.products);
      final Map<String, Map<String, List<String>>> tempCategorizedProducts = {};

      final catalogueSnap = await store
          .collection('Shop Types And Category Data')
          .doc('Catalogue')
          .get();

      final catalogueData = catalogueSnap.data()!;
      final catalogue = catalogueData['catalogueData'];

      for (String product in fetchedProducts) {
        String? category;
        String? shopType;

        for (var type in catalogue.keys) {
          final categories = catalogue[type];
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
      if (mounted) {
        mySnackBar('Error fetching data: $e', context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
      ),
      body: SafeArea(
        child: !isData
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: EdgeInsets.all(width * 0.0225),
                child: ListView(
                  children: categorizedProducts.entries.map((shopTypeEntry) {
                    final shopType = shopTypeEntry.key;
                    final categories = shopTypeEntry.value;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.only(
                        bottom: width * 0.0166,
                      ),
                      color: primary2,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.0225),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopType,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                color: primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...categories.entries.map((categoryEntry) {
                              final category = categoryEntry.key;
                              final products = categoryEntry.value;

                              return Padding(
                                padding: const EdgeInsets.only(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: primaryDark2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: primary2,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: products.map((product) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: primaryDark2,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    product,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: primaryDark,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
