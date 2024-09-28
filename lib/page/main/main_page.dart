import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localsearch/page/auth/register_details_page.dart';
import 'package:localsearch/page/auth/sign_in_page.dart';
import 'package:localsearch/page/main/under_development_page.dart';
import 'package:localsearch/page/main/vendor/home/posts/posts_page.dart';
import 'package:localsearch/page/main/vendor/home/products/product_home_page.dart';
import 'package:localsearch/page/main/vendor/profile/profile_page.dart';
import 'package:localsearch/page/main/vendor/shorts_page.dart';
import 'package:localsearch/providers/main_page_provider.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  // final NotificationHandler _notificationHandler = NotificationHandler();
  // final messaging = FirebaseMessaging.instance;
  Widget? detailsPage;

  // INIT STATE
  void initState() {
    getData();
    super.initState();
  }

  // GET DATA
  Future<void> getData() async {
    try {
      final developmentSnap =
          await store.collection('Development').doc('Under Development').get();

      final developmentData = developmentSnap.data()!;

      final userUnderDevelopment = developmentData['userUnderDevelopment'];

      if (userUnderDevelopment) {
        detailsPage = UnderDevelopmentPage();
      } else {
        final userSnap =
            await store.collection('Users').doc(auth.currentUser!.uid).get();

        if (!userSnap.exists) {
          await auth.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const SignInPage(),
              ),
              (route) => false,
            );
            mySnackBar(
              'The account you created was for Business app, create / login with another account for this app',
              context,
            );
          }
          return;
        } else {
          final userData = userSnap.data()!;

          if (userData['Name'] == null || userData['Email'] == null) {
            setState(() {
              detailsPage = const RegisterDetailsPage(
                emailPhoneGoogleChosen: 0,
              );
            });
          } /* else if (auth.currentUser!.email == null) {
            setState(() {
              detailsPage = SetEmailPage();
            });
          } else if (auth.currentUser!.email != null &&
              auth.currentUser!.email!.length > 4 &&
              !auth.currentUser!.emailVerified) {
            setState(() {
              detailsPage = EmailVerifyPage();
            });
          }*/
          else {
            setState(() {
              detailsPage = null;
            });
          }
        }
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

  @override
  Widget build(BuildContext context) {
    final mainPageProvider = Provider.of<MainPageProvider>(context);
    final loadedPages = mainPageProvider.loadedPages;
    final currentIndex = mainPageProvider.index;

    final List<Widget> items = [
      const ProductHomePage(),
      loadedPages.contains(1) ? const PostsPage() : Container(),
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
              mainPageProvider.changeIndex(index);
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
