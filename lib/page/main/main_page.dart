import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/auth/login_page.dart';
import 'package:find_easy_user/page/auth/register_details_page.dart';
import 'package:find_easy_user/page/auth/verify/email_verify.dart';
import 'package:find_easy_user/page/main/home_page.dart';
import 'package:find_easy_user/page/main/post_page.dart';
import 'package:find_easy_user/page/main/profile/profile_page.dart';
import 'package:find_easy_user/page/main/search/search_with_products_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
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
  int current = 1;
  Widget? detailsPage;

  List<Widget> items = [
    const PostsPage(),
    const HomePage(),
    const SearchWithProductsPage(),
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

      if (userData['Name'] == null || userData['Image'] == null) {
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
            backgroundColor: white,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: primaryDark,
            ),
            useLegacyColorScheme: false,
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: const IconThemeData(
              size: 24,
              color: primaryDark,
            ),
            unselectedIconTheme: IconThemeData(
              size: 24,
              color: black.withOpacity(0.5),
            ),
            currentIndex: current,
            onTap: changePage,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  FeatherIcons.compass,
                ),
                activeIcon: Icon(FeatherIcons.compass),
                label: "Posts",
                tooltip: 'POSTS',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  FeatherIcons.home,
                ),
                activeIcon: Icon(FeatherIcons.home),
                label: "Home",
                tooltip: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.search),
                activeIcon: Icon(FeatherIcons.search),
                label: "Search",
                tooltip: 'SEARCH',
              ),
              BottomNavigationBarItem(
                icon: Icon(FeatherIcons.user),
                activeIcon: Icon(FeatherIcons.user),
                label: "Profile",
                tooltip: 'PROFILE',
              ),
            ],
          ),
        );
  }
}
