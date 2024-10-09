import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localsearch/widgets/image_view.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ExhibitionPage extends StatefulWidget {
  const ExhibitionPage({
    super.key,
    required this.exhibitionId,
    required this.exhibitionName,
  });

  final String exhibitionId;
  final String exhibitionName;

  @override
  State<ExhibitionPage> createState() => _ExhibitionPageState();
}

class _ExhibitionPageState extends State<ExhibitionPage> {
  final store = FirebaseFirestore.instance;
  Map<String, dynamic>? data;
  int currentIndex = 0;

  // INIT STATE
  @override
  void initState() {
    getExhibitionData();
    super.initState();
  }

  // GET EXHIBITION DATA
  Future<void> getExhibitionData() async {
    try {
      final exhibitionDoc =
          store.collection('Exhibitions').doc(widget.exhibitionId);

      final exhibitionSnap = await exhibitionDoc.get();

      final exhibitionData = exhibitionSnap.data()!;

      final views = exhibitionData['views'];

      await exhibitionDoc.update({
        'views': views + 1,
      });

      setState(() {
        data = exhibitionData;
      });
    } catch (e) {
      if (mounted) {
        mySnackBar('Some error occured', context);
      }
    }
  }

  // FORMAT TIMEOFDAY
  String formatTimeOfDay(String timeString) {
    List<String> parts = timeString.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);

    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dateTime);
  }

  // FORMAT DATE
  String formatDate(Timestamp date) {
    DateTime myDate = date.toDate();
    return "${myDate.day} ${getMonthAbbreviation(myDate.month)}";
  }

  String getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exhibitionName),
        actions: [
          // SHARE
          IconButton(
            onPressed: () async {},
            icon: const Icon(
              Icons.share_outlined,
            ),
            tooltip: 'Share',
          ),
        ],
      ),
      body: data == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(
                  width * 0.0125,
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final List images = data!['Images'];

                  return SingleChildScrollView(
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
                                        builder: (context) => ImageView(
                                          imagesUrl: images,
                                          shortsThumbnail: null,
                                          shortsURL: null,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Image.network(
                                      e.toString().trim(),
                                      width: width,
                                      height: width,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        } else {
                                          return SizedBox(
                                            width: width,
                                            height: width,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          options: CarouselOptions(
                            enableInfiniteScroll:
                                images.length > 1 ? true : false,
                            viewportFraction: 1,
                            aspectRatio: 16 / 9,
                            enlargeCenterPage: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                          ),
                        ),

                        // NAME
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: width * 0.9,
                                child: Text(
                                  data!['Name'],
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // VENUE
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: GestureDetector(
                            onTap: () async {
                              Uri mapsUrl = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${data!['Latitude']},${data!['Longitude']}',
                              );

                              if (await canLaunchUrl(
                                mapsUrl,
                              )) {
                                await launchUrl(
                                  mapsUrl,
                                );
                              } else {
                                if (context.mounted) {
                                  mySnackBar(
                                    'Something went wrong while finding Location',
                                    context,
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Venue',
                                      style: TextStyle(
                                        fontSize: width * 0.03,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.825,
                                      child: Text(
                                        data!['Venue'],
                                        style: TextStyle(
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  FeatherIcons.mapPin,
                                  size: width * 0.075,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // TIMINGS
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timings',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: width * 0.9,
                                child: Text(
                                  '${formatTimeOfDay(data!['startTime'])} - ${formatTimeOfDay(data!['endTime'])}',
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DATES
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dates',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: width * 0.9,
                                child: Text(
                                  '${formatDate(data!['startDate'])} - ${formatDate(data!['endDate'])}',
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DESCRIPTION
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: width * 0.9,
                                child: Text(
                                  data!['Description'],
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ORGANIZER
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organizer',
                                style: TextStyle(
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: width * 0.9,
                                child: Text(
                                  data!['Organizer'],
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // CONTACT NO
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: GestureDetector(
                            onTap: () async {
                              final Uri callUri = Uri(
                                scheme: 'tel',
                                path: data!['ContactNo'],
                              );

                              if (await canLaunchUrl(
                                callUri,
                              )) {
                                await launchUrl(
                                  callUri,
                                );
                              } else {
                                if (context.mounted) {
                                  mySnackBar(
                                    'Something went wrong',
                                    context,
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact Number',
                                      style: TextStyle(
                                        fontSize: width * 0.03,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width * 0.825,
                                      child: Text(
                                        data!['ContactNo'],
                                        style: TextStyle(
                                          fontSize: width * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  FeatherIcons.phoneCall,
                                  size: width * 0.075,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
    );
  }
}
