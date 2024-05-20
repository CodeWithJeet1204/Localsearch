import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:localy_user/page/auth/login_page.dart';
import 'package:localy_user/page/auth/register_details_page.dart';
import 'package:localy_user/page/auth/verify/email_verify.dart';
import 'package:localy_user/page/main/events/events_home_page.dart';
import 'package:localy_user/page/main/product_home_page.dart';
import 'package:localy_user/page/main/post_page.dart';
import 'package:localy_user/page/main/vendor/profile/profile_page.dart';
import 'package:localy_user/page/main/services/services_home_page.dart';
import 'package:localy_user/page/main/vendor/shorts_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with AutomaticKeepAliveClientMixin {
  final auth = FirebaseAuth.instance.currentUser!;
  final store = FirebaseFirestore.instance;
  int current = 2;
  Widget? detailsPage;

  List<Widget> items = [
    const PostsPage(),
    const ProductHomePage(),
    const ShortsPage(),
    const ServicesHomePage(),
    const EventsHomePage(),
    const ProfilePage(),
  ];

  // KEEP ALIVE
  @override
  bool get wantKeepAlive => true;

  // INIT STATE
  @override
  void initState() {
    fetchUserDetails();
    super.initState();
  }

  // FETCH USER DETAILS
  Future<void> fetchUserDetails() async {
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

      if (userData['Name'] == null || userData['Email'] == null) {
        setState(() {
          detailsPage = const RegisterDetailsPage();
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
  }

  // CHANGE PAGE
  void changePage(int index) {
    setState(() {
      current = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return detailsPage ??
        Scaffold(
          body: IndexedStack(
            children: items,
            index: current,
          ),
          bottomNavigationBar: BottomNavigationBar(
            elevation: 0,
            backgroundColor: current == 2 ? black : white,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: current == 2 ? darkGrey.withOpacity(0.66) : primaryDark,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w400,
              color: current == 2
                  ? darkGrey.withOpacity(0.5)
                  : black.withOpacity(0.5),
            ),
            useLegacyColorScheme: false,
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: IconThemeData(
              size: 24,
              color: current == 2 ? lightGrey.withOpacity(0.66) : primaryDark,
            ),
            unselectedIconTheme: IconThemeData(
              size: 24,
              color: current == 2
                  ? darkGrey.withOpacity(0.5)
                  : black.withOpacity(0.5),
            ),
            currentIndex: current,
            onTap: changePage,
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
                label: 'Products',
                tooltip: 'PRODUCTS',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  FeatherIcons.video,
                ),
                activeIcon: Icon(FeatherIcons.video),
                label: 'Shorts',
                tooltip: 'SHORTS',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.handyman_outlined,
                ),
                activeIcon: Icon(Icons.handyman_outlined),
                label: 'Services',
                tooltip: 'SERVICES',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.calendar),
                activeIcon: Icon(FeatherIcons.calendar),
                label: 'Events',
                tooltip: 'EVENTS',
              ),
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
