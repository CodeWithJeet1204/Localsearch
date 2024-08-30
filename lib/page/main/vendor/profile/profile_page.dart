import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:Localsearch_User/page/auth/login_page.dart';
import 'package:Localsearch_User/page/main/vendor/profile/followed_page.dart';
import 'package:Localsearch_User/page/main/vendor/profile/user_details_page.dart';
import 'package:Localsearch_User/page/main/vendor/profile/wishlist_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/small_text_container.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:Localsearch_User/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // INIT STATE
  @override
  void initState() {
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

  // LOG OUT
  Future<void> logOut(BuildContext context) async {
    try {
      await auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: ((context) => const LoginPage()),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        mySnackBar(e.toString(), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              await logOut(context);
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
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.0225,
        ),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            final double width = constraints.maxWidth;

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
                                padding: EdgeInsets.only(left: width * 0.05),
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
                                builder: ((context) => const UserDetailsPage()),
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
    );
  }
}
