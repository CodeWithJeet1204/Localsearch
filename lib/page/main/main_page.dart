import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:localsearch_user/page/auth/login_page.dart';
import 'package:localsearch_user/page/auth/register_details_page.dart';
import 'package:localsearch_user/page/auth/verify/email_verify.dart';
import 'package:localsearch_user/page/main/vendor/home/product_home_page.dart';
import 'package:localsearch_user/page/main/vendor/home/product_scroll_page.dart';
import 'package:localsearch_user/page/main/vendor/profile/profile_page.dart';
import 'package:localsearch_user/page/main/vendor/shorts_page.dart';
import 'package:localsearch_user/utils/colors.dart';
// import 'package:localsearch_user/utils/notification_handler.dart';
import 'package:localsearch_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // final NotificationHandler _notificationHandler = NotificationHandler();
  final auth = FirebaseAuth.instance.currentUser!;
  final store = FirebaseFirestore.instance;
  // final messaging = FirebaseMessaging.instance;
  int currentIndex = 0;
  List loadedPages = [0];
  Widget? detailsPage;

  // GET DATA
  Future<void> getData() async {
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

    // messaging.getToken().then((String? token) {
    //   if (token != null) {
    //     FirebaseFirestore.instance
    //         .collection('Users')
    //         .doc(auth.uid)
    //         .update({'fcmToken': token}).catchError((e) {});
    //   }
    // }).catchError((e) {});

    // messaging.subscribeToTopic('all').then((_) {}).catchError((e) {});
  }

  // CHANGE PAGE
  void changePage(int index) {
    if (!loadedPages.contains(index)) {
      loadedPages.add(index);
    }
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      const ProductHomePage(),
      loadedPages.contains(1) ? const ProductsScrollPage() : Container(),
      loadedPages.contains(2)
          ? ShortsPage(
              bottomNavIndex: currentIndex,
            )
          : Container(),
      // const ServicesHomePage(),
      // const EventsHomePage(),
      loadedPages.contains(3) ? const ProfilePage() : Container(),
    ];

    return detailsPage ??
        Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: items,
          ),
          // body: items[currentIndex],
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
                  FeatherIcons.home,
                ),
                activeIcon: Icon(FeatherIcons.home),
                label: 'Home',
                tooltip: 'HOME',
              ),
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
                  FeatherIcons.playCircle,
                ),
                activeIcon: Icon(FeatherIcons.playCircle),
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
