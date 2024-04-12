import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/product/product_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, List<dynamic>> wishlists = {};
  String? selectedCategory;
  List categories = ['Pens'];

  // INIT STATE
  @override
  void initState() {
    getWishlist();
    super.initState();
  }

  // GET WISHLIST
  Future<void> getWishlist() async {
    Map<String, List<dynamic>> wishlist = {};

    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();
    final userData = userSnap.data()!;
    final myWishlists = userData['wishlists'] as List;

    await Future.forEach(myWishlists, (productId) async {
      final productSnap = await store
          .collection('Business')
          .doc('Data')
          .collection('Products')
          .doc(productId)
          .get();

      if (productSnap.exists) {
        final productData = productSnap.data()!;
        final id = productId as String;
        final name = productData['productName'] as String;
        final imageUrl = productData['images'][0] as String;
        final price = productData['productPrice'] as String;
        final categoryId = productData['categoryId'] as String;

        if (categoryId != '0') {
          final categorySnap = await store
              .collection('Business')
              .doc('Data')
              .collection('Category')
              .doc(categoryId)
              .get();

          final categoryData = categorySnap.data()!;

          final categoryName = categoryData['categoryName'];

          if (!categories.contains(categoryName)) {
            categories.add(categoryName);
          }
          wishlist[id] = [
            name,
            imageUrl,
            price,
            categoryName,
            productData,
          ];
        } else {
          wishlist[id] = [
            name,
            imageUrl,
            price,
            '0',
            productData,
          ];
        }
      }
    });

    setState(() {
      wishlists = wishlist;
    });

    print("Wishlists: $wishlists");
  }

  // REMOVE
  Future<void> remove(String id) async {
    wishlists.removeWhere((key, value) => key == id);

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlists': wishlists.keys.toList(),
    });

    await getWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wishlist"),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.00625,
          ),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final width = constraints.maxWidth;
              final currentWishlists = selectedCategory == null
                  ? wishlists
                  : Map.fromEntries(
                      wishlists.entries
                          .where((entry) => entry.value[3] == selectedCategory),
                    );

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CATEGORY CHIPS
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.0125,
                        vertical: width * 0.00625,
                      ),
                      child: SizedBox(
                        width: width,
                        height: 40,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: ((context, index) {
                            final category = categories[index];

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.01,
                              ),
                              child: ActionChip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    color: selectedCategory == category
                                        ? white
                                        : primaryDark,
                                  ),
                                ),
                                tooltip: "See $category",
                                onPressed: () {
                                  setState(() {
                                    if (selectedCategory == category) {
                                      selectedCategory = null;
                                    } else {
                                      selectedCategory = category;
                                    }
                                  });
                                },
                                backgroundColor: selectedCategory == category
                                    ? primaryDark
                                    : primary2,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    currentWishlists.isEmpty
                        ? Center(
                            child: Text(
                              'No Products',
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0125,
                              vertical: width * 0.0125,
                            ),
                            child: SizedBox(
                              width: width,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                itemCount: currentWishlists.length,
                                itemBuilder: ((context, index) {
                                  final id =
                                      currentWishlists.keys.toList()[index];
                                  final name = currentWishlists.values
                                      .toList()[index][0];
                                  final imageUrl = currentWishlists.values
                                      .toList()[index][1];
                                  final price = currentWishlists.values
                                      .toList()[index][2];
                                  final data = currentWishlists.values
                                      .toList()[index][4];

                                  return Slidable(
                                    endActionPane: ActionPane(
                                      extentRatio: 0.325,
                                      motion: StretchMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) async {
                                            await remove(id);
                                          },
                                          backgroundColor: Colors.red,
                                          icon: FeatherIcons.trash,
                                          label: "Unfollow",
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: width * 0.0125,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  ProductPage(
                                                    productData: data,
                                                  )),
                                            ),
                                          );
                                        },
                                        child: ListTile(
                                          splashColor: white,
                                          visualDensity:
                                              VisualDensity.comfortable,
                                          tileColor: primary2.withOpacity(0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: primary2,
                                            backgroundImage:
                                                NetworkImage(imageUrl),
                                          ),
                                          title: Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            price == '' ? 'N/A' : 'Rs. $price',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          titleTextStyle: TextStyle(
                                            color: primaryDark,
                                            fontSize: width * 0.0475,
                                          ),
                                          subtitleTextStyle: TextStyle(
                                            color: primaryDark2,
                                            fontSize: width * 0.04,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
