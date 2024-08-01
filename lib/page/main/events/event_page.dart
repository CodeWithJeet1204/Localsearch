import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Localsearch_User/page/main/events/event_comments_page.dart';
import 'package:Localsearch_User/page/main/events/events_organizer_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/image_view.dart';
import 'package:Localsearch_User/widgets/see_more_text.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventPage extends StatefulWidget {
  const EventPage({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> event = {};
  List workImages = [];
  int _currentIndex = 0;
  bool isData = false;
  bool isOrganizerHold = false;

  // INIT STATE
  @override
  void initState() {
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    final eventSnap =
        await store.collection('Events').doc(widget.eventId).get();

    final eventData = eventSnap.data()!;

    setState(() {
      event = eventData;
      isData = true;
    });
  }

  // GET TIME OF DAY
  String getTimeString(String timeString) {
    String cleanedString =
        timeString.replaceAll('TimeOfDay(', '').replaceAll(')', '');

    List<String> parts = cleanedString.split(':');

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: minute);

    final now = DateTime.now();
    final time = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    final format = DateFormat.jm();
    return format.format(time);
  }

  // GET IF WISHLIST
  Stream<bool> getIfWishlist() {
    return store
        .collection('Users')
        .doc(auth.currentUser!.uid)
        .snapshots()
        .map((userSnap) {
      final userData = userSnap.data()!;
      final userWishlist = userData['wishlistEvents'] as List;

      return userWishlist.contains(widget.eventId);
    });
  }

  // GET ADDRESS
  Future<String> getAddress(double shopLatitude, double shopLongitude) async {
    const apiKey = 'AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
    final apiUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$shopLatitude,$shopLongitude&key=$apiKey';

    String? address;
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          address = data['results'][0]['formatted_address'];
        } else {
          if (mounted) {
            mySnackBar('Failed to get address', context);
          }
        }
      } else {
        if (mounted) {
          mySnackBar('Failed to load data', context);
        }
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }

    address = address?.isNotEmpty == true ? address : 'No address found';

    return address!.length > 30 ? '${address.substring(0, 30)}...' : address;
  }

  // WISHLIST EVENT
  Future<void> wishlistEvent() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;
    List<dynamic> userWishlist = userData['wishlistEvents'] as List<dynamic>;

    bool alreadyInWishlist = userWishlist.contains(widget.eventId);

    if (!alreadyInWishlist) {
      userWishlist.add(widget.eventId);
    } else {
      userWishlist.remove(widget.eventId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'wishlistEvents': userWishlist,
    });

    final eventSnap =
        await store.collection('Events').doc(widget.eventId).get();

    final eventData = eventSnap.data()!;

    int noOfWishList = eventData['wishlists'] ?? 0;

    if (!alreadyInWishlist) {
      noOfWishList++;
    } else {
      noOfWishList--;
    }

    await store.collection('Events').doc(widget.eventId).update({
      'wishlists': noOfWishList,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder(
            stream: getIfWishlist(),
            builder: ((context, snapshot) {
              if (snapshot.hasError) {
                return Container();
              }

              if (snapshot.hasData) {
                final isWishlist = snapshot.data!;

                return IconButton(
                  onPressed: () async {
                    await wishlistEvent();
                  },
                  icon: Icon(
                    isWishlist ? Icons.favorite : Icons.favorite_outline,
                    color: Colors.red,
                  ),
                  color: Colors.red,
                  tooltip: isWishlist ? 'WISHLISTED' : 'WISHLIST',
                );
              }

              return Container();
            }),
          ),
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
      body: !isData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.006125,
                ),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    final width = constraints.maxWidth;

                    final List images = event['imageUrl'];

                    final String name = event['eventName'];

                    final String type = event['eventType'];

                    final double eventLatitude = event['eventLatitude'];
                    final double eventLongitude = event['eventLongitude'];

                    final String? contactHelp = event['contactHelp'];

                    final String organizerName = event['organizerName'];
                    final String organizerId = event['organizerId'];

                    final Timestamp startDate = event['startDate'];
                    final Timestamp endDate = event['endDate'];

                    final String startTime = event['startTime'];
                    final String endTime = event['endTime'];

                    final String? weekendStartTime = event['weekendStartTime'];
                    final String? weekendEndTime = event['weekendEndTime'];

                    final String? ticketTotal = event['ticketNoOfTickets'];

                    final String? ticketPrice = event['ticketPrice'];
                    final String? ticketEarlyBirdPrice =
                        event['ticketEarlyBirdPrice'];
                    final String? ticketVIPPrice = event['ticketVIPPrice'];
                    final String? ticketGroupPrice = event['ticketGroupPrice'];
                    final String? ticketPromoCodePrice =
                        event['ticketPromoCodePrice'];
                    final String? ticketPromoCode = event['ticketPromoCode'];

                    final String? ticketWebsite = event['ticketWebsite'];
                    final String? ticketAddress = event['ticketAddress'];

                    final String? ticketRefundDays = event['ticketRefundDays'];

                    final String description = event['eventDescription'];

                    // final Map<String, dynamic> comments =
                    //     event['eventComments'];

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // VENDOR
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0125,
                              vertical: width * 0.025,
                            ),
                            child: GestureDetector(
                              onTap: () {},
                              onTapDown: (details) {
                                setState(() {
                                  isOrganizerHold = true;
                                });
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: ((context) => EventsOrganizerPage(
                                          organizerId: organizerId,
                                        )),
                                  ),
                                );
                              },
                              onTapUp: (details) {
                                setState(() {
                                  isOrganizerHold = false;
                                });
                              },
                              onTapCancel: () {
                                setState(() {
                                  isOrganizerHold = false;
                                });
                              },
                              child: Text(
                                'Visit the $organizerName page',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 114, 196),
                                  fontSize: width * 0.045,
                                  decoration: isOrganizerHold
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ),
                          ),

                          // IMAGES
                          CarouselSlider(
                            items: images
                                .map(
                                  (e) => Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: primaryDark2,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: ((context) => ImageView(
                                                  imagesUrl: images,
                                                )),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          10,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(e),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            options: CarouselOptions(
                              enableInfiniteScroll:
                                  images.length > 1 ? true : false,
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
                                  padding: EdgeInsets.symmetric(
                                    vertical: width * 0.033,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: (images).map((e) {
                                      int index = images.indexOf(e);

                                      return Container(
                                        width: _currentIndex == index ? 12 : 8,
                                        height: _currentIndex == index ? 12 : 8,
                                        margin: const EdgeInsets.all(4),
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
                              : const SizedBox(height: 12),

                          const Divider(),

                          // COMMENTS
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: ((context) => EventCommentsPage(
                                        eventId: widget.eventId,
                                      )),
                                ),
                              );
                            },
                            splashColor: primary2,
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: width,
                              decoration: BoxDecoration(
                                color: primary2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(width * 0.0225),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "See Comments",
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: width * 0.05,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(FeatherIcons.chevronRight),
                                ],
                              ),
                            ),
                          ),

                          const Divider(),

                          // NAME
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Name',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05,
                                ),
                              ),
                            ),
                          ),

                          const Divider(),

                          // VENUE
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Venue',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // LOCATION
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: FutureBuilder(
                                  future:
                                      getAddress(eventLatitude, eventLongitude),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Text(
                                        'Something went wrong with addresss',
                                      );
                                    }

                                    if (snapshot.hasData) {
                                      return GestureDetector(
                                        onTap: () async {
                                          String encodedAddress =
                                              Uri.encodeFull(snapshot.data!);

                                          Uri mapsUrl = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

                                          if (await canLaunchUrl(mapsUrl)) {
                                            await launchUrl(mapsUrl);
                                          } else {
                                            if (context.mounted) {
                                              mySnackBar(
                                                'Something went Wrong',
                                                context,
                                              );
                                            }
                                          }
                                        },
                                        child: Text(
                                          snapshot.data!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: primaryDark,
                                            fontSize: width * 0.05,
                                          ),
                                        ),
                                      );
                                    }

                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }),
                            ),
                          ),

                          const Divider(),

                          // DATES
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Dates',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // DATES
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                '''${DateFormat('d MMM yy').format(
                                  startDate.toDate(),
                                )} - ${DateFormat('d MMM yy').format(
                                  endDate.toDate(),
                                )}''',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05,
                                ),
                              ),
                            ),
                          ),

                          const Divider(),

                          // TIMING
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Timing',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // TIMING
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                '${getTimeString(startTime)} - ${getTimeString(endTime)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05,
                                ),
                              ),
                            ),
                          ),

                          weekendStartTime == null || weekendEndTime == null
                              ? Container()
                              : const Divider(),

                          // WEEKEND TIMING
                          weekendStartTime == null || weekendEndTime == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Weekend Timings',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          // WEEKEND TIMING
                          weekendStartTime == null && weekendEndTime == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      '${getTimeString(weekendStartTime!)} - ${getTimeString(weekendEndTime!)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          const Divider(),

                          // TYPE
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Type',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // TYPE
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                type,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05,
                                ),
                              ),
                            ),
                          ),

                          description == ''
                              ? Container()
                              : const Divider(
                                  thickness: 4,
                                  height: 24,
                                ),

                          // DESCRIPTION
                          description == ''
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: width * 0.0175,
                                    horizontal: width * 0.02,
                                  ),
                                  child: Container(
                                    width: width,
                                    padding: EdgeInsets.all(width * 0.0225),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 0.33,
                                        color: black,
                                      ),
                                    ),
                                    child: SeeMoreText(
                                      description,
                                      textStyle: const TextStyle(
                                        color: primaryDark,
                                      ),
                                      seeMoreStyle: TextStyle(
                                        color: Colors.blue,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.0425,
                                      ),
                                    ),
                                  ),
                                ),

                          const Divider(
                            thickness: 4,
                            height: 24,
                          ),

                          // TICKETS
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'TICKETS INFO',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // TICKET TOTAL TICKETS
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Total Tickets',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // TICKET TOTAL TICKETS
                          ticketTotal == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      '$ticketTotal Tickets',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          const Divider(),

                          // TICKET BASE PRICE
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Base',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // TICKET BASE PRICE
                          ticketPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Rs. $ticketPrice',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketEarlyBirdPrice == null
                              ? Container()
                              : const Divider(),

                          // TICKET EARLY BIRD PRICE
                          ticketEarlyBirdPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Early Bird',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          // TICKET EARLY BIRD PRICE
                          ticketEarlyBirdPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Rs. $ticketEarlyBirdPrice',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketEarlyBirdPrice == null
                              ? Container()
                              : const Divider(),

                          // TICKET VIP PRICE
                          ticketVIPPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'VIP',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketVIPPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Rs. $ticketVIPPrice',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketVIPPrice == null
                              ? Container()
                              : const Divider(),

                          // TICKET GROUP PRICE
                          ticketGroupPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Group',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketGroupPrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Rs. $ticketGroupPrice',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketGroupPrice == null
                              ? Container()
                              : const Divider(),

                          // TICKET PROMO PRICE
                          ticketPromoCodePrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Discount & Promo Code',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketPromoCodePrice == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Rs. $ticketPromoCodePrice - $ticketPromoCode',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketPromoCodePrice == null
                              ? Container()
                              : const Divider(),

                          // TICKET WEBSITE
                          ticketWebsite == null
                              ? Container()
                              : GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.tryParse(
                                      ticketWebsite.contains('https://')
                                          ? ticketWebsite
                                          : 'https://$ticketWebsite',
                                    );
                                    if (uri != null) {
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else {
                                        if (context.mounted) {
                                          mySnackBar(
                                            'Something went wrong',
                                            context,
                                          );
                                        }
                                      }
                                    } else {
                                      mySnackBar(
                                        'Ticket website URL is invalid',
                                        context,
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: ticketWebsite,
                                      ),
                                    );
                                    mySnackBar('Copied To Clipboard', context);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0225,
                                    ),
                                    child: SizedBox(
                                      width: width * 0.9,
                                      child: Text(
                                        'Ticket Website',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: primaryDark.withOpacity(0.75),
                                          fontSize: width * 0.04,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                          ticketWebsite == null
                              ? Container()
                              : GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.tryParse(
                                      ticketWebsite.startsWith('https://')
                                          ? ticketWebsite
                                          : 'https://$ticketWebsite',
                                    );
                                    if (uri != null) {
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else {
                                        if (context.mounted) {
                                          mySnackBar(
                                            'Something went wrong',
                                            context,
                                          );
                                        }
                                      }
                                    } else {
                                      mySnackBar(
                                        'Ticket website URL is invalid',
                                        context,
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: ticketWebsite,
                                      ),
                                    );
                                    mySnackBar('Copied To Clipboard', context);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.0225,
                                    ),
                                    child: SizedBox(
                                      width: width * 0.9,
                                      child: Text(
                                        ticketWebsite,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color.fromRGBO(
                                              13, 121, 210, 1),
                                          fontSize: width * 0.05,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                          ticketWebsite == null ? Container() : const Divider(),

                          // TICKET ADDRESS
                          ticketAddress == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Ticket Address',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketAddress == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      ticketAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketAddress == null ? Container() : const Divider(),

                          // TICKET REFUND DAYS
                          ticketRefundDays == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      'Ticket Refund Days',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark.withOpacity(0.75),
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                          ticketRefundDays == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.9,
                                    child: Text(
                                      int.parse(ticketRefundDays) > 1
                                          ? '$ticketRefundDays Days'
                                          : '$ticketRefundDays Day',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryDark,
                                        fontSize: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ),

                          const Divider(
                            thickness: 4,
                            height: 24,
                          ),

                          // CONTACT HELP
                          contactHelp == ''
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final Uri url = Uri(
                                        scheme: 'tel',
                                        path: contactHelp,
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        if (context.mounted) {
                                          mySnackBar(
                                              'Some error occured', context);
                                        }
                                      }
                                    },
                                    onLongPress: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: contactHelp!,
                                        ),
                                      );
                                      mySnackBar(
                                          'Copied To Clipboard', context);
                                    },
                                    child: SizedBox(
                                      width: width * 0.9,
                                      child: Text(
                                        'Contact Help',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: primaryDark.withOpacity(0.75),
                                          fontSize: width * 0.04,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                          contactHelp == ''
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.0225,
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final Uri url = Uri(
                                        scheme: 'tel',
                                        path: contactHelp,
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        if (context.mounted) {
                                          mySnackBar(
                                            'Some error occured',
                                            context,
                                          );
                                        }
                                      }
                                    },
                                    onLongPress: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: contactHelp,
                                        ),
                                      );
                                      mySnackBar(
                                        'Copied To Clipboard',
                                        context,
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          contactHelp!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: primaryDark,
                                            fontSize: width * 0.05,
                                          ),
                                        ),
                                        const Icon(
                                          FeatherIcons.phoneCall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                          contactHelp == '' ? Container() : const Divider(),

                          // ORGANIZER NAME
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                'Organizer',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark.withOpacity(0.75),
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0225,
                            ),
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                organizerName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryDark,
                                  fontSize: width * 0.05,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
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
