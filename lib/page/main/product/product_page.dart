import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/image_view.dart';
import 'package:find_easy_user/widgets/info_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({
    super.key,
    required this.productData,
  });

  final Map<String, dynamic> productData;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  int _currentIndex = 0;
  bool isWishListed = false;
  String? vendorName;
  String? vendorImageUrl;

  // INIT STATE
  @override
  void initState() {
    getIfWishlist(widget.productData['productId']);
    getVendorInfo();
    super.initState();
  }

  // GET IF WISHLIST
  Future<void> getIfWishlist(String productId) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    final userWishlist = userData['wishlists'] as List;

    setState(() {
      if (userWishlist.contains(productId)) {
        isWishListed = true;
      } else {
        isWishListed = false;
      }
    });
  }

  // WISHLIST PRODUCT
  Future<void> wishlistProduct(String productId) async {
    setState(() {
      isWishListed = !isWishListed;
    });
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlists'] as List<dynamic>;

    bool alreadyInWishlist = userWishlist.contains(productId);

    if (!alreadyInWishlist) {
      userWishlist.add(productId);
    } else {
      userWishlist.remove(productId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlists': userWishlist,
    });

    final productDoc = store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .doc(productId);

    final productSnap = await productDoc.get();
    final productData = productSnap.data()!;

    int noOfWishList = productData['productWishlist'] ?? 0;

    if (!alreadyInWishlist) {
      noOfWishList++;
    } else {
      noOfWishList--;
    }

    await productDoc.update({
      'productWishlist': noOfWishList,
    });
  }

  // GET VENDOR INFO
  Future<void> getVendorInfo() async {
    final vendorSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .doc(widget.productData['vendorId'])
        .get();

    final vendorData = vendorSnap.data()!;

    setState(() {
      vendorName = vendorData['Name'];
      vendorImageUrl = vendorData['Image'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.productData;
    final String id = data['productId'];
    final String name = data['productName'];
    final String price = data['productPrice'];
    final String description = data['productDescription'];
    final String brand = data['productBrand'];
    final List images = data['images'];
    // final String categoryId = data['categoryId'];
    final String categoryName = data['categoryName'];

    final Map<String, dynamic> properties = data['Properties'];
    final String propertyName0 = properties['propertyName0'];
    final String propertyName1 = properties['propertyName1'];
    final String propertyName2 = properties['propertyName2'];
    final String propertyName3 = properties['propertyName3'];
    final String propertyName4 = properties['propertyName4'];
    final String propertyName5 = properties['propertyName5'];

    final List propertyValue0 = properties['propertyValue0'];
    final List propertyValue1 = properties['propertyValue1'];
    final List propertyValue2 = properties['propertyValue2'];
    final List propertyValue3 = properties['propertyValue3'];
    final List propertyValue4 = properties['propertyValue4'];
    final List propertyValue5 = properties['propertyValue5'];

    final int propertyNoOfAnswers0 = properties['propertyNoOfAnswers0'];
    final int propertyNoOfAnswers1 = properties['propertyNoOfAnswers1'];
    final int propertyNoOfAnswers2 = properties['propertyNoOfAnswers2'];
    final int propertyNoOfAnswers3 = properties['propertyNoOfAnswers3'];
    final int propertyNoOfAnswers4 = properties['propertyNoOfAnswers4'];
    final int propertyNoOfAnswers5 = properties['propertyNoOfAnswers5'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productData['productName'],
        ),
      ),
      body: LayoutBuilder(
        builder: ((context, constraints) {
          double width = constraints.maxWidth;
          print(propertyName0);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(width * 0.0225),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGES
                  CarouselSlider(
                    items: (images)
                        .map(
                          (e) => GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: ((context) => ImageView(
                                        imagesUrl: images,
                                      )),
                                ),
                              );
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: primaryDark2,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.network(
                                e,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    options: CarouselOptions(
                      enableInfiniteScroll: images.length > 1 ? true : false,
                      aspectRatio: 1.2,
                      enlargeCenterPage: true,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  ),

                  // DOTS
                  images.length > 1
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: (images).map((e) {
                              int index = images.indexOf(e);

                              return Container(
                                width: _currentIndex == index ? 12 : 8,
                                height: _currentIndex == index ? 12 : 8,
                                margin: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentIndex == index
                                      ? primaryDark
                                      : primary2,
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : SizedBox(height: 36),

                  // NAME, PRICE & WISHLIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NAME
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: name.length > 12
                                    ? 28
                                    : name.length > 10
                                        ? 30
                                        : 32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // PRICE
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              price == "" ? 'N/A (price)' : 'Rs. ${price}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // WISHLIST
                      IconButton(
                        onPressed: () async {
                          await wishlistProduct(id);
                        },
                        icon: Icon(
                          isWishListed ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: width * 0.1,
                        ),
                        splashColor: Colors.red,
                        tooltip: "Wishlist",
                      ),
                    ],
                  ),

                  // DESCRIPTION
                  InfoBox(
                    head: "Description",
                    content: description,
                    noOfAnswers: 1,
                    propertyValue: [],
                    width: width,
                  ),

                  // BRAND
                  InfoBox(
                    head: "Brand",
                    content: brand,
                    noOfAnswers: 1,
                    propertyValue: [],
                    width: width,
                  ),

                  // CATEGORY
                  InfoBox(
                    head: "Category",
                    content: categoryName,
                    noOfAnswers: 1,
                    propertyValue: [],
                    width: width,
                  ),

                  // VENDOR
                  vendorName == null
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.0125,
                            vertical: width * 0.0225,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // VENDOR PROFILE
                              CircleAvatar(
                                backgroundImage: NetworkImage(vendorImageUrl!),
                              ),

                              // VENDOR NAME
                              Padding(
                                padding: EdgeInsets.only(left: width * 0.033),
                                child: Text(
                                  vendorName!,
                                  style: TextStyle(
                                    color: primaryDark,
                                    fontSize: width * 0.05,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                  // PROPERTY 0
                  propertyValue0.isEmpty
                      ? Container()
                      : InfoBox(
                          head: propertyName0,
                          noOfAnswers: propertyNoOfAnswers0,
                          width: width,
                          content: propertyValue0.length == 1
                              ? propertyValue0[0]
                              : null,
                          propertyValue: propertyValue0.length > 1
                              ? propertyValue0
                                  .map(
                                    (e) => Container(
                                      height: 40,
                                      margin: EdgeInsets.only(
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryDark2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : List.empty(),
                        ),

                  // PROPERTY 1
                  propertyValue1.isEmpty
                      ? Container()
                      : InfoBox(
                          head: propertyName1,
                          noOfAnswers: propertyNoOfAnswers1,
                          width: width,
                          content: propertyValue1.length == 1
                              ? propertyValue1[0]
                              : null,
                          propertyValue: propertyValue1.length > 1
                              ? propertyValue1
                                  .map(
                                    (e) => Container(
                                      height: 40,
                                      margin: EdgeInsets.only(
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryDark2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : List.empty(),
                        ),

                  // PROPERTY 2
                  propertyValue2.isEmpty
                      ? Container()
                      : InfoBox(
                          head: propertyName2,
                          noOfAnswers: propertyNoOfAnswers2,
                          width: width,
                          content: propertyValue2.length == 1
                              ? propertyValue2[0]
                              : null,
                          propertyValue: propertyValue2.length > 1
                              ? propertyValue2
                                  .map(
                                    (e) => Container(
                                      height: 40,
                                      margin: EdgeInsets.only(
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryDark2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : List.empty(),
                        ),

                  // PROPERTY 3
                  propertyValue3.isEmpty
                      ? Container()
                      : InfoBox(
                          head: propertyName3,
                          noOfAnswers: propertyNoOfAnswers3,
                          width: width,
                          content: propertyValue3.length == 1
                              ? propertyValue3[0]
                              : null,
                          propertyValue: propertyValue3.length > 1
                              ? propertyValue3
                                  .map(
                                    (e) => Container(
                                      height: 40,
                                      margin: EdgeInsets.only(
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryDark2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : List.empty(),
                        ),

                  // PROPERTY 4
                  propertyValue4.isEmpty
                      ? Container()
                      : InfoBox(
                          head: propertyName4,
                          noOfAnswers: propertyNoOfAnswers4,
                          width: width,
                          content: propertyValue4.length == 1
                              ? propertyValue4[0]
                              : null,
                          propertyValue: propertyValue4.length > 1
                              ? propertyValue4
                                  .map(
                                    (e) => Container(
                                      height: 40,
                                      margin: EdgeInsets.only(
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryDark2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : List.empty(),
                        ),

                  // PROPERTY 5
                  propertyValue5.isEmpty
                      ? Container()
                      : InfoBox(
                          head: propertyName5,
                          noOfAnswers: propertyNoOfAnswers5,
                          width: width,
                          content: propertyValue5.length == 1
                              ? propertyValue5[0]
                              : null,
                          propertyValue: propertyValue5.length > 1
                              ? propertyValue5
                                  .map(
                                    (e) => Container(
                                      height: 40,
                                      margin: EdgeInsets.only(
                                        right: 4,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: primaryDark2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList()
                              : List.empty(),
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
