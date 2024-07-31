import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:Localsearch_User/page/auth/login_page.dart';
import 'package:Localsearch_User/page/auth/register_details_page.dart';
import 'package:Localsearch_User/page/auth/verify/email_verify.dart';
import 'package:Localsearch_User/page/main/product_home_page.dart';
import 'package:Localsearch_User/page/main/post_home_page.dart';
import 'package:Localsearch_User/page/main/vendor/profile/profile_page.dart';
import 'package:Localsearch_User/page/main/vendor/shorts_page.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/utils/notification_handler.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with AutomaticKeepAliveClientMixin {
  final NotificationHandler _notificationHandler = NotificationHandler();
  final auth = FirebaseAuth.instance.currentUser!;
  final store = FirebaseFirestore.instance;
  final messaging = FirebaseMessaging.instance;
  int currentIndex = 1;
  Widget? detailsPage;

  List<Widget> items = [
    const PostHomePage(),
    const ProductHomePage(),
    const ShortsPage(),
    // const ServicesHomePage(),
    // const EventsHomePage(),
    const ProfilePage(),
  ];

  // KEEP ALIVE
  @override
  bool get wantKeepAlive => true;

  // INIT STATE
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchUserDetailsAndSaveToken();
  }

  // INITIALIZE NOTIFICATIONS
  void _initializeNotifications() {
    _notificationHandler.initialize();
  }

  // FETCH USER DETAILS
  Future<void> _fetchUserDetailsAndSaveToken() async {
    try {
      final userSnap = await store.collection('Users').doc(auth.uid).get();

      if (!userSnap.exists) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: ((context) => const LoginPage()),
            ),
            (route) => false,
          );
          mySnackBar(
            'The account you created was for business app, create / login with another account for this app',
            context,
          );
        }
        return;
      }

      final userData = userSnap.data()!;

      if (!auth.emailVerified) {
        setState(() {
          detailsPage = const EmailVerifyPage();
        });
      } else if (userData['Name'] == null || userData['Email'] == null) {
        setState(() {
          detailsPage = const RegisterDetailsPage(
            emailPhoneGoogleChosen: 0,
          );
        });
      } else if (auth.email != null &&
          auth.email!.length > 4 &&
          !auth.emailVerified) {
        setState(() {
          detailsPage = const EmailVerifyPage();
        });
      } else {
        setState(() {
          detailsPage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }

    messaging.getToken().then((String? token) {
      if (token != null) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(auth.uid)
            .update({'fcmToken': token}).catchError((e) {});
      }
    }).catchError((e) {});

    messaging.subscribeToTopic('all').then((_) {}).catchError((e) {});
  }

  // CHANGE PAGE
  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return detailsPage ??
        Scaffold(
          // body: IndexedStack(
          //   index: current,
          //   children: items,
          // ),
          body: items[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            elevation: 0,
            backgroundColor: currentIndex == 2 ? black : white,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color:
                  currentIndex == 2 ? darkGrey.withOpacity(0.66) : primaryDark,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w400,
              color: currentIndex == 2
                  ? darkGrey.withOpacity(0.5)
                  : black.withOpacity(0.5),
            ),
            useLegacyColorScheme: false,
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: IconThemeData(
              size: 24,
              color:
                  currentIndex == 2 ? lightGrey.withOpacity(0.66) : primaryDark,
            ),
            unselectedIconTheme: IconThemeData(
              size: 24,
              color: currentIndex == 2
                  ? darkGrey.withOpacity(0.5)
                  : black.withOpacity(0.5),
            ),
            currentIndex: currentIndex,
            onTap: (index) {
              changePage(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  FeatherIcons.compass,
                ),
                activeIcon: Icon(FeatherIcons.compass),
                label: 'Posts',
                tooltip: 'POSTS',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  FeatherIcons.home,
                ),
                activeIcon: Icon(FeatherIcons.home),
                label: 'Home',
                tooltip: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  FeatherIcons.video,
                ),
                activeIcon: Icon(FeatherIcons.video),
                label: 'Shorts',
                tooltip: 'SHORTS',
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(
              //     Icons.handyman_outlined,
              //   ),
              //   activeIcon: Icon(Icons.handyman_outlined),
              //   label: 'Services',
              //   tooltip: 'SERVICES',
              // ),
              // BottomNavigationBarItem(
              //   icon: Icon(FeatherIcons.calendar),
              //   activeIcon: Icon(FeatherIcons.calendar),
              //   label: 'Events',
              //   tooltip: 'EVENTS',
              // ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.user),
                activeIcon: Icon(FeatherIcons.user),
                label: 'Profile',
                tooltip: 'PROFILE',
              ),
            ],
          ),
        );
  }
}
