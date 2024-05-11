import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/main/events/event_page.dart';
import 'package:find_easy_user/page/main/events/events_previous_work_images_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/image_show.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsOrganizerPage extends StatefulWidget {
  const EventsOrganizerPage({
    super.key,
    required this.organizerId,
  });

  final String organizerId;

  @override
  State<EventsOrganizerPage> createState() => _EventsOrganizerPageState();
}

class _EventsOrganizerPageState extends State<EventsOrganizerPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  Map<String, dynamic> organizerData = {};
  List workImages = [];
  Map<String, Map<String, dynamic>> allEvents = {};
  Map<String, Map<String, dynamic>> events = {};
  Map<String, dynamic> ongoingEvents = {};
  List eventTypes = [];
  bool isFollowing = false;
  String? selectedEventType;
  bool isData = false;

  // INIT STATE
  @override
  void initState() {
    getOrganizerData();
    getIfFollowing();
    getWorkImages();
    getEvents();
    super.initState();
  }

  // GET ORGANIZER DATA
  Future<void> getOrganizerData() async {
    final organizerSnap =
        await store.collection('Organizers').doc(widget.organizerId).get();

    final myOrganizerData = organizerSnap.data()!;

    setState(() {
      organizerData = myOrganizerData;
      isData = true;
    });
  }

  // GET EVENTS
  Future<void> getEvents() async {
    Map<String, Map<String, dynamic>> myEvents = {};
    Map<String, Map<String, dynamic>> myOngoingEvents = {};
    List myEventTypes = [];
    final eventsSnap = await store.collection('Events').get();

    eventsSnap.docs.forEach((event) {
      final eventData = event.data();

      if (eventData['organizerId'] == widget.organizerId) {
        if ((eventData['endDate'] as Timestamp)
            .toDate()
            .isAfter(DateTime.now())) {
          myEvents[eventData['eventId']] = eventData;
          if (!myEventTypes.contains(eventData['eventType'])) {
            myEventTypes.add(eventData['eventType']);
          }
        }

        if ((eventData['startDate'] as Timestamp)
                .toDate()
                .isBefore(DateTime.now()) &&
            (eventData['endDate'] as Timestamp)
                .toDate()
                .isAfter(DateTime.now())) {
          myOngoingEvents[eventData['eventId']] = eventData;
        }
      }

      setState(() {
        ongoingEvents = myOngoingEvents;
        eventTypes = myEventTypes;
        events = myEvents;
        allEvents = myEvents;
      });
    });
  }

  // GET WORK IMAGES
  Future<void> getWorkImages() async {
    List myWorkImages = [];

    final organizerSnap =
        await store.collection('Organizers').doc(widget.organizerId).get();

    final organizerData = organizerSnap.data()!;

    myWorkImages = organizerData['workImages'];

    setState(() {
      workImages = myWorkImages;
    });
  }

  // FOLLOW ORGANIZER
  Future<void> followOrganizer() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final followedOrganizers = userData['followedOrganizers'] as List;

    if (followedOrganizers.contains(widget.organizerId)) {
      followedOrganizers.remove(widget.organizerId);
    } else {
      followedOrganizers.add(widget.organizerId);
    }

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'followedOrganizers': followedOrganizers,
    });

    final organizerSnap =
        await store.collection('Organizers').doc(widget.organizerId).get();

    final organizerData = organizerSnap.data()!;

    List followers = organizerData['Followers'];

    if (followers.contains(auth.currentUser!.uid)) {
      followers.remove(auth.currentUser!.uid);
    } else {
      followers.add(auth.currentUser!.uid);
    }

    await store.collection('Organizers').doc(widget.organizerId).update({
      'Followers': followers,
    });

    await getIfFollowing();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: ((context) => EventsOrganizerPage(
              organizerId: widget.organizerId,
            )),
      ),
    );
  }

  // GET IF FOLLOWING
  Future<void> getIfFollowing() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final following = userData['followedOrganizers'];

    setState(() {
      if ((following as List).contains(widget.organizerId)) {
        isFollowing = true;
      } else {
        isFollowing = false;
      }
    });
  }

  // CALL SHOP
  Future<void> callShop() async {
    final Uri url = Uri(
      scheme: 'tel',
      path: organizerData['Phone Number'],
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        mySnackBar('Some error occured', context);
      }
    }
  }

  // GET TYPE EVENT
  void getTypeEvent(String? type) {
    Map<String, Map<String, dynamic>> filteredEvents = {};
    setState(() {
      events = allEvents;
    });

    if (type != null) {
      events.forEach((eventKey, eventDetails) {
        if (eventDetails['eventType'] == type) {
          filteredEvents[eventKey] = eventDetails;
        }
      });

      setState(() {
        events = filteredEvents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: !isData
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.0125,
                ),
                child: LayoutBuilder(
                  builder: ((context, constraints) {
                    final width = constraints.maxWidth;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: ((context) => ImageShow(
                                        imageUrl: organizerData['Image'],
                                        width: width,
                                      )),
                                );
                              },
                              child: CircleAvatar(
                                radius: width * 0.15,
                                backgroundImage: NetworkImage(
                                  organizerData['Image'],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: width * 0.0225),

                          // NAME
                          Center(
                            child: SizedBox(
                              width: width * 0.9,
                              child: Text(
                                organizerData['Name'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: width * 0.066,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: width * 0.0225),

                          // TYPE
                          Center(
                            child: SizedBox(
                              width: width * 0.9,
                              child: Center(
                                child: Text(
                                  organizerData['Type'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: width * 0.0425,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: width * 0.033),

                          // OPTIONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // FOLLOW
                              GestureDetector(
                                onTap: () async {
                                  await followOrganizer();
                                },
                                child: Container(
                                  width: width * 0.4125,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isFollowing ? black : lightGrey,
                                    border: Border.all(
                                      color: isFollowing ? lightGrey : black,
                                      width: 0.75,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isFollowing ? 'Following' : 'Follow',
                                    style: TextStyle(
                                      color: isFollowing ? white : black,
                                    ),
                                  ),
                                ),
                              ),

                              // CALL
                              GestureDetector(
                                onTap: () async {
                                  await callShop();
                                },
                                child: Container(
                                  width: width * 0.25,
                                  height: 40,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.00625,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary2.withOpacity(0.5),
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.5),
                                      width: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Call',
                                        style: TextStyle(
                                          color: primaryDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(FeatherIcons.phone),
                                    ],
                                  ),
                                ),
                              ),

                              // WHATSAPP
                              GestureDetector(
                                onTap: () async {
                                  final String phoneNumber =
                                      organizerData['Phone Number'];
                                  final String message =
                                      'Hey, I found you on Find Easy\n';
                                  final url =
                                      'https://wa.me/$phoneNumber?text=$message';

                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  } else {
                                    mySnackBar(
                                      'Something went Wrong',
                                      context,
                                    );
                                  }
                                },
                                child: Container(
                                  width: width * 0.275,
                                  height: 40,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.00625,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      198,
                                      255,
                                      200,
                                      1,
                                    ),
                                    border: Border.all(
                                      color: primaryDark.withOpacity(0.25),
                                      width: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Whatsapp',
                                        style: TextStyle(
                                          color: primaryDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(FeatherIcons.messageCircle),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: width * 0.0225),

                          const Divider(),

                          SizedBox(height: width * 0.0125),

                          // ADDRESS
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0125,
                              vertical: width * 0.0175,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: width * 0.8,
                                  child: Text(
                                    '${organizerData['Followers'].length.toString()} ${organizerData['Followers'].length > 1 ? 'Followers' : 'Follower'}',
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: width * 0.034,
                                  ),
                                  child: Icon(FeatherIcons.users),
                                ),
                              ],
                            ),
                          ),

                          // ADDRESS
                          GestureDetector(
                            onTap: () async {
                              String encodedAddress =
                                  Uri.encodeFull(organizerData['Address']);

                              Uri mapsUrl = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

                              if (await canLaunchUrl(mapsUrl)) {
                                await launchUrl(mapsUrl);
                              } else {
                                mySnackBar(
                                  'Something went Wrong',
                                  context,
                                );
                              }
                            },
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: organizerData['Address'],
                                ),
                              );
                              mySnackBar('Copied To Clipboard', context);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.0125,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      organizerData['Address'],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      String encodedAddress = Uri.encodeFull(
                                          organizerData['Address']);

                                      Uri mapsUrl = Uri.parse(
                                          'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

                                      if (await canLaunchUrl(mapsUrl)) {
                                        await launchUrl(mapsUrl);
                                      } else {
                                        mySnackBar(
                                          'Something went Wrong',
                                          context,
                                        );
                                      }
                                    },
                                    icon: const Icon(FeatherIcons.mapPin),
                                    tooltip: 'Locate on Maps',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // EMAIL
                          GestureDetector(
                            onTap: () async {
                              Uri emailUri = Uri(
                                scheme: 'mailto',
                                path: organizerData['Email'],
                              );

                              if (await canLaunchUrl(emailUri)) {
                                await launchUrl(emailUri);
                              } else {
                                mySnackBar('Something went Wrong', context);
                              }
                            },
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: organizerData['Email'],
                                ),
                              );
                              mySnackBar('Copied To Clipboard', context);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.0125,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      organizerData['Email'],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      Uri emailUri = Uri(
                                        scheme: 'mailto',
                                        path: organizerData['Email'],
                                      );

                                      if (await canLaunchUrl(emailUri)) {
                                        await launchUrl(emailUri);
                                      } else {
                                        mySnackBar(
                                            'Something went Wrong', context);
                                      }
                                    },
                                    icon: const Icon(FeatherIcons.mail),
                                    tooltip: 'Mail',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // WEBSITE
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.tryParse(
                                organizerData['Website'].contains('https://')
                                    ? organizerData['Website']
                                    : 'https://${organizerData['Website']}',
                              );
                              if (uri != null) {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  mySnackBar(
                                    'Something went wrong',
                                    context,
                                  );
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
                                  text: organizerData['Website'],
                                ),
                              );
                              mySnackBar('Copied To Clipboard', context);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.0125,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: width * 0.8,
                                    child: Text(
                                      organizerData['Website'],
                                      style: TextStyle(
                                        color: Color.fromRGBO(
                                          13,
                                          121,
                                          210,
                                          1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final uri = Uri.tryParse(
                                        organizerData['Website']
                                                .contains('https://')
                                            ? organizerData['Website']
                                            : 'https://${organizerData['Website']}',
                                      );
                                      if (uri != null) {
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          mySnackBar(
                                            'Something went wrong',
                                            context,
                                          );
                                        }
                                      } else {
                                        mySnackBar(
                                          'Ticket website URL is invalid',
                                          context,
                                        );
                                      }
                                    },
                                    icon: const Icon(FeatherIcons.globe),
                                    tooltip: 'Website',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // DOE
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.0125,
                              vertical: width * 0.0175,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: width * 0.8,
                                  child: Text(
                                    'Established - ${organizerData['DOE']}',
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: width * 0.034,
                                  ),
                                  child: Icon(FeatherIcons.calendar),
                                ),
                              ],
                            ),
                          ),

                          Divider(),

                          // WORK IMAGES
                          workImages.isEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.all(width * 0.0125),
                                  child: InkWell(
                                    onTap: () {
                                      print(workImages);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: ((context) =>
                                              EventsPreviousWorkImagesPage(
                                                workImages: workImages,
                                              )),
                                        ),
                                      );
                                    },
                                    splashColor: white,
                                    customBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      width: width,
                                      decoration: BoxDecoration(
                                        color: primary2.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.all(width * 0.045),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'See Previous Work',
                                            style: TextStyle(
                                              fontSize: width * 0.05,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(FeatherIcons.chevronRight),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                          workImages.isEmpty ? Container() : Divider(),

                          // ONGOING
                          ongoingEvents.isEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.all(
                                    width * 0.0175,
                                  ),
                                  child: Text(
                                    'Ongoing',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: width * 0.055,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                          // ONGOING EVENTS
                          ongoingEvents.isEmpty
                              ? Container()
                              : SizedBox(
                                  width: width,
                                  height: width * 0.45,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    physics: ClampingScrollPhysics(),
                                    itemCount: ongoingEvents.length,
                                    itemBuilder: ((context, index) {
                                      final id =
                                          ongoingEvents.keys.toList()[index];
                                      final name = ongoingEvents.values
                                          .toList()[index]['eventName'];
                                      final imageUrl = ongoingEvents.values
                                          .toList()[index]['imageUrl'][0];

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: ((context) =>
                                                  EventPage(eventId: id)),
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
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          padding: EdgeInsets.all(
                                            width * 0.00625,
                                          ),
                                          margin: EdgeInsets.all(
                                            width * 0.0125,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: width * 0.325,
                                                  height: width * 0.325,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: width * 0.00625,
                                                  left: width * 0.0125,
                                                ),
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: width * 0.05,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                          ongoingEvents.isEmpty ? Container() : Divider(),

                          // EVENT TYPES
                          eventTypes.length < 2
                              ? Container()
                              : SizedBox(
                                  width: width,
                                  height: 50,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: eventTypes.length,
                                    itemBuilder: ((context, index) {
                                      final type = eventTypes[index];

                                      return Padding(
                                        padding: EdgeInsets.all(width * 0.0125),
                                        child: ActionChip(
                                          label: Text(
                                            type,
                                            style: TextStyle(
                                              color: selectedEventType == type
                                                  ? white
                                                  : primaryDark,
                                            ),
                                          ),
                                          tooltip: 'Select $type',
                                          onPressed: () {
                                            setState(() {
                                              if (selectedEventType == type) {
                                                selectedEventType = null;
                                              } else {
                                                selectedEventType = type;
                                              }
                                            });
                                            print(
                                                'Selected Category: $selectedEventType');
                                            getTypeEvent(selectedEventType);
                                          },
                                          backgroundColor:
                                              selectedEventType == type
                                                  ? primaryDark
                                                  : primary2,
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                          // EVENTS
                          events.isEmpty
                              ? SizedBox(
                                  width: width,
                                  height: 100,
                                  child: Center(
                                    child: Text('No Events'),
                                  ),
                                )
                              : SizedBox(
                                  width: width,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    itemCount: events.length,
                                    itemBuilder: ((context, index) {
                                      final id = events.keys.toList()[index];
                                      final name = events.values.toList()[index]
                                          ['eventName'];
                                      final startDate = DateFormat('d MMM')
                                          .format((events.values.toList()[index]
                                                  ['startDate'] as Timestamp)
                                              .toDate());
                                      final endDate = DateFormat('d MMM')
                                          .format((events.values.toList()[index]
                                                  ['endDate'] as Timestamp)
                                              .toDate());
                                      final imageUrl = events.values
                                          .toList()[index]['imageUrl'][0];
                                      final type = events.values.toList()[index]
                                          ['eventType'];
                                      final address = events.values
                                          .toList()[index]['eventAddress'];

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
                                          width: width,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 0.25,
                                              color:
                                                  primaryDark.withOpacity(0.25),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          padding:
                                              EdgeInsets.all(width * 0.0125),
                                          margin:
                                              EdgeInsets.all(width * 0.0125),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  // NAME
                                                  SizedBox(
                                                    width: width * 0.6,
                                                    child: Text(
                                                      name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: width * 0.05,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // DATES
                                                  SizedBox(
                                                    width: width * 0.6,
                                                    child: Text(
                                                      '$startDate - $endDate',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize:
                                                            width * 0.0475,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // TYPE
                                                  SizedBox(
                                                    width: width * 0.6,
                                                    child: Text(
                                                      type,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: width * 0.045,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  // ADDRESS
                                                  SizedBox(
                                                    width: width * 0.6,
                                                    child: Text(
                                                      address,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: width * 0.045,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ), // IMAGE
                                              Container(
                                                width: width * 0.33,
                                                height: 132,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  image: DecorationImage(
                                                    image:
                                                        NetworkImage(imageUrl),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                          SizedBox(height: 8),
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
