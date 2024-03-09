import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/auth/register_details_page.dart';
import 'package:find_easy_user/page/auth/verify/email_verify.dart';
import 'package:find_easy_user/page/main/post_page.dart';
import 'package:find_easy_user/page/main/profile_page.dart';
import 'package:find_easy_user/page/main/search_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int current = 0;
  Widget? detailsPage;

  List<Widget> items = [
    PostPage(),
    SearchPage(),
    ProfilePage(),
  ];

  // INIT STATE
  @override
  void initState() {
    getInfoDetails();
    super.initState();
  }

  Future<void> getInfoDetails() async {
    final userData = await FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userData['Name'] == null) {
      setState(() {
        detailsPage = RegisterDetailsPage();
      });
    } else if (FirebaseAuth.instance.currentUser!.email != null &&
        !FirebaseAuth.instance.currentUser!.emailVerified) {
      detailsPage = EmailVerifyPage();
    }
  }

  // CHANGE PAGE
  void changePage(value) {
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
              fontWeight: FontWeight.w600,
              color: primaryDark,
            ),
            selectedIconTheme: const IconThemeData(
              size: 28,
              color: primaryDark,
            ),
            currentIndex: current,
            onTap: (value) {
              changePage(value);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                ),
                label: "Add",
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.search,
                ),
                label: "Search",
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_outline,
                ),
                label: "Profile",
              ),
            ],
          ),
        );
  }
}
