import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({
    super.key,
    required this.search,
  });

  final String search;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  bool isMicPressed = false;
  bool isSearchPressed = false;
  Map shops = {};
  Map products = {};
  bool getShopsData = false;
  bool getProductsData = false;

  // INIT STATE
  @override
  void initState() {
    getShops();
    getProducts();
    super.initState();
  }

  // LISTEN
  Future<void> listen() async {
    var result = await showDialog(
      context: context,
      builder: ((context) => SpeechToText()),
    );

    if (result != null && result is String) {
      searchController.text = result;
    }
  }

  // SEARCH
  Future<void> search() async {
    // search function

    await addRecentSearch();
  }

  // ADD RECENT SEARCH
  Future<void> addRecentSearch() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final recent = userData['recentSearches'] as List;

    if (!recent.contains(searchController.text) &&
        searchController.text.isNotEmpty) {
      recent.insert(0, searchController.text);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'recentSearches': recent,
    });
  }

  // GET SHOPS
  Future<void> getShops() async {
    var currentShops = {};

    final shopSnap = await store
        .collection('Business')
        .doc('Owners')
        .collection('Shops')
        .get();

    shopSnap.docs.forEach((shopSnap) {
      final shopData = shopSnap.data();

      final String shopName = shopData['Name'];
      final String address = shopData['Address'];
      final String vendorId = shopSnap.id;

      final String upperName =
          shopName[0].toUpperCase() + shopName.substring(1).toLowerCase();

      final String lowerName = shopName.toLowerCase();

      currentShops[upperName] = [address, vendorId];
      currentShops[lowerName] = [address, vendorId];

      if (currentShops.containsKey(widget.search)) {
        shops[widget.search] = currentShops[widget.search];
      }
    });

    setState(() {
      getShopsData = true;
    });
  }

  // GET PRODUCTS
  Future<void> getProducts() async {
    final productsSnap = await store
        .collection('Business')
        .doc('Data')
        .collection('Products')
        .get();

    productsSnap.docs.forEach((productSnap) {
      final productData = productSnap.data();

      final String productName = productData['productName'];
      final String productId = productData['productId'];

      final String upperName =
          productName[0].toUpperCase() + productName.substring(1).toLowerCase();

      final String lowerName = productName.toLowerCase();

      products[upperName] = productId;
      products[lowerName] = productId;
    });

    setState(() {
      getProductsData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: width * 0.15125,
        title: Padding(
          padding: EdgeInsets.only(
            top: width * 0.025,
            bottom: width * 0.0225,
            right: width * 0.0125,
          ),
          child: Container(
            width: width,
            height: width * 0.15,
            decoration: BoxDecoration(
              color: primary,
              border: Border.all(
                color: primaryDark.withOpacity(0.75),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: width * 0.466,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        width: 0.5,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(
                        // top: width * 0.135,
                        ),
                    child: TextFormField(
                      autofillHints: const [],
                      autofocus: true,
                      minLines: 1,
                      maxLines: 1,
                      controller: searchController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          textBaseline: TextBaseline.alphabetic,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTapDown: (details) {
                        setState(() {
                          isMicPressed = true;
                        });
                      },
                      onTapUp: (details) {
                        setState(() {
                          isMicPressed = false;
                        });
                      },
                      onTapCancel: () {
                        setState(() {
                          isMicPressed = false;
                        });
                      },
                      onTap: () async {
                        await listen();
                      },
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: width * 0.15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isMicPressed
                              ? primary2.withOpacity(0.95)
                              : primary2.withOpacity(0.25),
                        ),
                        child: Icon(
                          FeatherIcons.mic,
                          size: width * 0.066,
                        ),
                      ),
                    ),
                    InkWell(
                      onTapDown: (details) {
                        setState(() {
                          isSearchPressed = true;
                        });
                      },
                      onTapUp: (details) {
                        setState(() {
                          isSearchPressed = false;
                        });
                      },
                      onTapCancel: () {
                        setState(() {
                          isSearchPressed = false;
                        });
                      },
                      onTap: () async {
                        await search();
                      },
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          bottomLeft: Radius.circular(0),
                          bottomRight: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Container(
                        width: width * 0.15,
                        decoration: BoxDecoration(
                          color: isSearchPressed
                              ? primary2.withOpacity(0.95)
                              : primary2.withOpacity(0.25),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          FeatherIcons.search,
                          size: width * 0.066,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: !getShopsData && !getProductsData
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  width * 0.0125,
                ),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    final double width = constraints.maxWidth;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FILTERS
                          // ListView.builder(
                          //   scrollDirection: Axis.horizontal,
                          //   itemCount: 4,
                          //   itemBuilder: ((context, index) {

                          //   }),
                          // ),

                          // SHOPS
                          shops.isEmpty
                              ? Container()
                              : Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * 0.0225,
                                        vertical: width * 0.00625,
                                      ),
                                      child: Text(
                                        'Shops',
                                        style: TextStyle(
                                          color: primaryDark.withOpacity(0.8),
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                    Divider(),
                                  ],
                                ),

                          // ListView.builder(
                          //   itemCount: shops.length > 3 ? 3 : shops.length,
                          //   itemBuilder: ((context, index) {}),
                          // ),
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
