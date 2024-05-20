import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localy_user/page/main/shorts_tile.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({super.key});

  @override
  State<ShortsPage> createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  final store = FirebaseFirestore.instance;
  int snappedPageIndex = 0;

  // GET VENDOR NAME
  Future<String> getVendorName(String vendorId) async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final vendorName = vendorData['Name'] as String;

    return vendorName;
  }

  // GET PRODUCT NAME
  Future<String> getProductName(String productId) async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data()!;

    final productName = productData['productName'] as String;

    return productName;
  }

  @override
  Widget build(BuildContext context) {
    final shortsStream = store
        .collection('Business')
        .doc('Data')
        .collection('Shorts')
        .orderBy('datetime', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: black,
      body: SafeArea(
        child: StreamBuilder(
            stream: shortsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Some Error Occured',
                    style: TextStyle(
                      color: white,
                    ),
                  ),
                );
              }

              if (snapshot.hasData) {
                final shortsSnap = snapshot.data!;

                if (shortsSnap.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No Shorts Available',
                      style: TextStyle(
                        color: darkGrey,
                      ),
                    ),
                  );
                }

                return PageView.builder(
                  controller:
                      PageController(initialPage: 0, viewportFraction: 1),
                  scrollDirection: Axis.vertical,
                  onPageChanged: (pageIndex) {
                    setState(() {
                      snappedPageIndex = pageIndex;
                    });
                  },
                  itemCount: shortsSnap.docs.length,
                  itemBuilder: ((context, index) {
                    final currentShort = shortsSnap.docs[index];
                    final data = currentShort.data();

                    return ShortsTile(
                      data: data,
                      snappedPageIndex: index,
                      currentIndex: snappedPageIndex,
                    );
                  }),
                );
              }

              return Center(
                child: CircularProgressIndicator(),
              );
            }),
      ),
    );
  }
}
