import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/auth/register_details_page.dart';
import 'package:find_easy_user/page/auth/verify/email_verify.dart';
import 'package:find_easy_user/page/main/home_page.dart';
import 'package:find_easy_user/page/main/profile_page.dart';
import 'package:find_easy_user/page/main/search/search_with_products_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final auth = FirebaseAuth.instance.currentUser!;
  final store = FirebaseFirestore.instance;
  int current = 1;
  Widget? detailsPage;

  List<Widget> items = [
    HomePage(),
    SearchWithProductsPage(),
    ProfilePage(),
  ];

  // INIT STATE
  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  // FETCH USER DETAILS
  Future<void> fetchUserDetails() async {
    try {
      final userSnap = await store.collection('Users').doc(auth.uid).get();
      final userData = userSnap.data()!;

      if (userData['Name'] == null) {
        setState(() {
          detailsPage = RegisterDetailsPage();
        });
      } else if (auth.email != null &&
          auth.email!.length > 4 &&
          !auth.emailVerified) {
        setState(() {
          detailsPage = EmailVerifyPage();
        });
      } else {
        setState(() {
          detailsPage = null;
        });
      }
    } catch (e) {
      mySnackBar(e.toString(), context);
    }
  }

  // CHANGE PAGE
  void changePage(int value) {
    setState(() {
      current = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return detailsPage ??
        Scaffold(
          body: items[current],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: primary2,
            selectedLabelStyle: const TextStyle(
              color: primaryDark,
              fontWeight: FontWeight.w600,
            ),
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: const IconThemeData(
              size: 24,
              color: primaryDark,
            ),
            currentIndex: current,
            onTap: changePage,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(
                  FeatherIcons.home,
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: const Icon(
                  FeatherIcons.search,
                ),
                label: "Search",
              ),
              BottomNavigationBarItem(
                icon: const Icon(
                  FeatherIcons.user,
                ),
                label: "Profile",
              ),
            ],
          ),
        );
  }
}
