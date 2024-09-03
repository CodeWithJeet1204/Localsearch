import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Localsearch_User/page/main/events/event_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventTypePage extends StatefulWidget {
  const EventTypePage({
    super.key,
    required this.eventType,
  });

  final String eventType;

  @override
  State<EventTypePage> createState() => _EventTypePageState();
}

class _EventTypePageState extends State<EventTypePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> events = {};
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    Map<String, Map<String, dynamic>> myEvents = {};

    final eventSnap = await store
        .collection('Events')
        .where('eventType', isEqualTo: widget.eventType)
        .orderBy('eventViewsTimestamp', descending: true)
        .get();

    for (var event in eventSnap.docs) {
      myEvents[event.id] = event.data();
    }

    setState(() {
      events = myEvents;
      isData = true;
    });
  }

  // GET IF WISHLIST
  Stream<bool> getIfWishlist(String eventId) {
    return store
        .collection('Users')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((userSnap) {
      final userData = userSnap.data()!;
      final userWishlist = userData['wishlistEvents'] as List;

      return userWishlist.contains(eventId);
    });
  }

  // WISHLIST EVENT
  Future<void> wishlistEvent(String eventId) async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlistEvents'] as List<dynamic>;

    bool alreadyInWishlist = userWishlist.contains(eventId);

    if (!alreadyInWishlist) {
      userWishlist.add(eventId);
    } else {
      userWishlist.remove(eventId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlistEvents': userWishlist,
    });

    final eventSnap = await store.collection('Events').doc(eventId).get();

    final eventData = eventSnap.data()!;

    int noOfWishList = eventData['wishlists'] ?? 0;

    if (!alreadyInWishlist) {
      noOfWishList++;
    } else {
      noOfWishList--;
    }

    await store.collection('Events').doc(eventId).update({
      'wishlists': noOfWishList,
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventType),
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            width * 0.006125,
          ),
          child: SizedBox(
            width: width,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: width * 0.633 / width,
              ),
              itemCount: events.length,
              itemBuilder: ((context, index) {
                final id = events.keys.toList()[index];
                final name = events.values.toList()[index]['eventName'];
                final imageUrl = events.values.toList()[index]['imageUrl'][0];
                final price = events.values.toList()[index]['ticketPrice'];

                return StreamBuilder(
                    stream: getIfWishlist(id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Something went wrong',
                          ),
                        );
                      }

                      if (snapshot.hasData) {
                        final isWishListed = snapshot.data ?? false;

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: ((context) => EventPage(
                                      eventId: id,
                                    )),
                              ),
                            );
                          },
                          child: Container(
                            width: width * 0.325,
                            height: width * 0.225,
                            decoration: BoxDecoration(
                              color: white,
                              border: Border.all(
                                width: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            padding: EdgeInsets.all(
                              width * 0.006125,
                            ),
                            margin: EdgeInsets.all(
                              width * 0.006125,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: width * 0.5,
                                    height: width * 0.58,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.00625,
                                            right: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.00625,
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.0125,
                                          ),
                                          child: SizedBox(
                                            width: width * 0.3,
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: width * 0.0575,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.0125,
                                          ),
                                          child: Text(
                                            price == ''
                                                ? 'Rs. --'
                                                : 'Rs. $price',
                                            style: TextStyle(
                                              fontSize: width * 0.05,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await wishlistEvent(id);
                                      },
                                      icon: Icon(
                                        isWishListed
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      color: Colors.red,
                                      tooltip: isWishListed
                                          ? 'Remove from Wishlist'
                                          : 'Wishlist',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    });
              }),
            ),
          ),
        ),
      ),
    );
  }
}
