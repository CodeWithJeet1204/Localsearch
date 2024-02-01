import 'package:find_easy_user/main/post_page.dart';
import 'package:find_easy_user/main/profile_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int current = 0;

  Widget content = PostPage();
  List<Widget> items = [
    PostPage(),
    ProfilePage(),
  ];

  void changePage(value) {
    setState(() {
      current = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content,
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
