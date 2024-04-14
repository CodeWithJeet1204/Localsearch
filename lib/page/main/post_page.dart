import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/main/product/product_page.dart';
import 'package:find_easy_user/page/main/vendor/vendor_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> posts = {};
  Map<String, dynamic> vendors = {};
  Map<String, dynamic> productsData = {};

  // INIT STATE
  @override
  void initState() {
    super.initState();
    getPosts();
  }

  // GET POSTS
  Future<void> getPosts() async {
    Map<String, dynamic> myPosts = {};
    final postsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Posts')
        .get();

    for (final postSnap in postsSnap.docs) {
      final postData = postSnap.data();
      final String productId = postData['postProductId'];
      final String name = postData['postProductName'];
      final String price = postData['postProductPrice'];
      final bool isTextPost = postData['isTextPost'];
      final List imageUrl = isTextPost ? [] : postData['postProductImages'];
      final String vendorId = postData['postVendorId'];
      final Timestamp datetime = postData['postDateTime'];

      myPosts[isTextPost ? '${productId}text' : '${productId}image'] = [
        name,
        price,
        imageUrl,
        vendorId,
        isTextPost,
        datetime,
      ];

      myPosts = Map.fromEntries(
        myPosts.entries.toList()
          ..sort(
            (a, b) => (b.value[5] as Timestamp).compareTo(
              a.value[5] as Timestamp,
            ),
          ),
      );

      await getVendorInfo(vendorId);
      await getPostProductData(productId, isTextPost);
    }

    setState(() {
      posts = myPosts;
    });
  }

  // GET POST PRODUCT DATA
  Future<Map<String, dynamic>?> getPostProductData(
      String productId, bool isTextPost,
      {bool? wantData}) async {
    final productSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId)
        .get();

    final productData = productSnap.data();
    productsData[isTextPost ? '${productId}text' : '${productId}image'] =
        productData;

    if (wantData != null) {
      return productsData[isTextPost ? productId : productId];
    } else {
      return null;
    }
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo(String vendorId) async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(vendorId)
        .get();

    final vendorData = vendorSnap.data()!;

    final id = vendorSnap.id;
    final name = vendorData['Name'];
    final imageUrl = vendorData['Image'];

    setState(() {
      vendors[id] = [name, imageUrl];
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: posts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.00625,
                ),
                child: SizedBox(
                  width: width,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: ((context, index) {
                      final String id = posts.keys.toList()[index];

                      final String name = posts.values.toList()[index][0];
                      final String price = posts.values.toList()[index][1];
                      final List imageUrl = posts.values.toList()[index][2];
                      final String vendorId = posts.values.toList()[index][3];
                      final bool isTextPost = posts.values.toList()[index][4];
                      final String vendorName =
                          vendors.isEmpty ? '' : vendors[vendorId][0];
                      final String vendorImageUrl =
                          vendors.isEmpty ? '' : vendors[vendorId][1];
                      final productData = productsData[id];

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: ((context) => ProductPage(
                                    productData: productData!,
                                  )),
                            ),
                          );
                        },
                        child: Container(
                          width: width,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                width: 0.06125,
                                color: black,
                              ),
                              right: BorderSide(
                                width: 0.06125,
                                color: black,
                              ),
                              top: BorderSide(
                                width: 0.06125,
                                color: black,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              // VENDOR INFO
                              vendors.isEmpty
                                  ? Container()
                                  : Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                        vertical: width * 0.0125,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) => VendorPage(
                                                    vendorId: vendorId,
                                                  )),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          // mainAxisAlignment: MainAxis,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: width * 0.04,
                                              backgroundColor: primary2,
                                              backgroundImage: NetworkImage(
                                                vendorImageUrl,
                                              ),
                                            ),
                                            SizedBox(width: width * 0.0125),
                                            Text(
                                              vendorName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                              // IMAGES
                              isTextPost
                                  ? Container()
                                  : Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Container(
                                          width: width,
                                          height: width,
                                          decoration: const BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 237, 237, 237),
                                          ),
                                          child: CarouselSlider(
                                            items: (imageUrl)
                                                .map(
                                                  (e) => Image.network(
                                                    e,
                                                    width: width,
                                                    height: width,
                                                  ),
                                                )
                                                .toList(),
                                            options: CarouselOptions(
                                              enableInfiniteScroll:
                                                  imageUrl.length > 1
                                                      ? true
                                                      : false,
                                              viewportFraction: 1,
                                              aspectRatio: 0.7875,
                                              enlargeCenterPage: false,
                                            ),
                                          ),
                                        ),

                                        // DOTS
                                        // isTextPost
                                        //     ? Container()
                                        //     : Padding(
                                        //         padding: const EdgeInsets.only(
                                        //           bottom: 8,
                                        //         ),
                                        //         child: Row(
                                        //           mainAxisAlignment:
                                        //               MainAxisAlignment.center,
                                        //           crossAxisAlignment:
                                        //               CrossAxisAlignment.center,
                                        //           children: (imageUrl).map((e) {
                                        //             int index = imageUrl.indexOf(e);

                                        //             return Container(
                                        //               width: 8,
                                        //               height: 8,
                                        //               margin: const EdgeInsets.all(4),
                                        //               decoration: BoxDecoration(
                                        //                 shape: BoxShape.circle,
                                        //                 color: currentIndex == index
                                        //                     ? primaryDark
                                        //                     : primary2,
                                        //               ),
                                        //             );
                                        //           }).toList(),
                                        //         ),
                                        //       ),
                                      ],
                                    ),

                              // NAME
                              Padding(
                                padding: EdgeInsets.all(width * 0.0125),
                                child: SizedBox(
                                  width: width,
                                  height: isTextPost ? null : 40,
                                  child: Text(
                                    name,
                                    maxLines: isTextPost ? null : 2,
                                    overflow: isTextPost
                                        ? null
                                        : TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              // PRICE
                              price == ''
                                  ? Container()
                                  : Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0125,
                                        vertical: width * 0.00625,
                                      ),
                                      child: SizedBox(
                                        width: width * 0.75,
                                        child: Text(
                                          'Rs. $price',
                                          maxLines: isTextPost ? null : 2,
                                          overflow: isTextPost
                                              ? null
                                              : TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}
