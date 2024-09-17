import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch_user/page/auth/login_page.dart';
import 'package:localsearch_user/page/main/vendor/profile/followed_page.dart';
import 'package:localsearch_user/page/main/vendor/profile/user_details_page.dart';
import 'package:localsearch_user/page/main/vendor/profile/wishlist_page.dart';
import 'package:localsearch_user/providers/main_page_provider.dart';
import 'package:localsearch_user/utils/colors.dart';
import 'package:localsearch_user/widgets/small_text_container.dart';
import 'package:localsearch_user/widgets/snack_bar.dart';
import 'package:localsearch_user/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  String? name;
  bool canReview = false;
  bool hasReviewed = true;

  // INIT STATE
  @override
  void initState() {
    getHasReviewed();
    super.initState();
    getData();
  }

  // GET DATA
  Future<void> getData() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final userName = userData['Name'];

    setState(() {
      name = userName;
    });
  }

  // SIGN OUT
  Future<void> signOut() async {
    await showDialog(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: const Text(
            'Sign Out?',
          ),
          content: const Text(
            'Are you sure,\nYou want to Sign Out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'NO',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: ((context) => const LoginPage()),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  mySnackBar(e.toString(), context);
                }
              },
              child: const Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                'YES',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // GET HAS REVIEWED
  Future<void> getHasReviewed() async {
    final userSnap =
        await store.collection('Users').doc(auth.currentUser!.uid).get();

    final userData = userSnap.data()!;

    final myHasReviewed = userData['hasReviewed'];
    final hasReviewedIndex = userData['hasReviewedIndex'];

    setState(() {
      hasReviewed = myHasReviewed;
    });

    await store.collection('Users').doc(auth.currentUser!.uid).update({
      'hasReviewedIndex': hasReviewedIndex + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainPageProvider = Provider.of<MainPageProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        mainPageProvider.goToHomePage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              onPressed: () async {
                await signOut();
              },
              icon: const Icon(Icons.logout),
              tooltip: 'LOG OUT',
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
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.0225,
            ),
            child: LayoutBuilder(
              builder: ((context, constraints) {
                final width = constraints.maxWidth;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: width,
                        height: width * 0.33,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(bottom: width * 0.01),
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.045,
                          vertical: width * 0.01125,
                        ),
                        decoration: BoxDecoration(
                          color: primary2.withOpacity(0.5),
                          border: Border.all(
                            width: 0.5,
                            color: primaryDark.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // NAME
                            name == null
                                ? Container()
                                : Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.05),
                                    child: SizedBox(
                                      width: width * 0.45,
                                      child: Text(
                                        name!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontSize: width * 0.07,
                                          fontWeight: FontWeight.w700,
                                          color: primaryDark.withBlue(5),
                                        ),
                                      ),
                                    ),
                                  ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: ((context) =>
                                        const UserDetailsPage()),
                                  ),
                                );
                              },
                              icon: const Icon(
                                FeatherIcons.settings,
                              ),
                              tooltip: 'Your Info',
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // FOLLOWED
                      SmallTextContainer(
                        text: 'Followed',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: ((context) => const FollowedPage()),
                            ),
                          );
                        },
                        width: width,
                      ),

                      // WISHLIST
                      SmallTextContainer(
                        text: 'Wishlist',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: ((context) => const WishlistPage()),
                            ),
                          );
                        },
                        width: width,
                      ),

                      Divider(),

                      // RATE THIS APP
                      hasReviewed
                          ? Container()
                          : Padding(
                              padding: EdgeInsets.all(width * 0.0225),
                              child: InkWell(
                                onTap: () async {
                                  await store
                                      .collection('Users')
                                      .doc(auth.currentUser!.uid)
                                      .update({
                                    'hasReviewed': true,
                                  });

                                  const url =
                                      'https://play.google.com/store/apps/details?id=com.localsearchuser.package';
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  } else {
                                    return mySnackBar(
                                      'Some error occured, Try Again Later',
                                      context,
                                    );
                                  }
                                },
                                customBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(width * 0.0225),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Rate This App',
                                        style: TextStyle(
                                          fontSize: width * 0.0425,
                                          color: primaryDark,
                                        ),
                                      ),
                                      Icon(
                                        Icons.star,
                                        size: width * 0.075,
                                        color: Colors.yellow,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                      // CALL HELPLINE
                      InkWell(
                        onTap: () async {
                          final helplineSnap = await store
                              .collection('Helpline')
                              .doc('helpline1')
                              .get();

                          final helplineData = helplineSnap.data()!;

                          final int helplineNo = helplineData['helpline1'];

                          final Uri url = Uri(
                            scheme: 'tel',
                            path: helplineNo.toString(),
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            if (mounted) {
                              mySnackBar('Some error occured', context);
                            }
                          }
                        },
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.0225),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Call Helpline',
                                style: TextStyle(
                                  fontSize: width * 0.0425,
                                  color: primaryDark,
                                ),
                              ),
                              Icon(
                                FeatherIcons.phoneCall,
                                size: width * 0.075,
                                color: primaryDark,
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
        ),
      ),
    );
  }
}
