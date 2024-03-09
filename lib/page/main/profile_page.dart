import 'package:find_easy_user/page/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PROFILE"),
        actions: [
          IconButton(
            onPressed: () async {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: ((context) => LoginPage()),
                ),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
            tooltip: "LOG OUT",
          ),
        ],
      ),
    );
  }
}
