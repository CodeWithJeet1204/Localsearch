import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/auth/login_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // LOG OUT
  Future<void> logOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: ((context) => LoginPage()),
        ),
        (route) => false,
      );
    } catch (e) {
      mySnackBar(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userFuture = FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    return Scaffold(
      appBar: AppBar(
        title: Text("PROFILE"),
        actions: [
          IconButton(
            onPressed: () async {
              await logOut(context);
            },
            icon: Icon(Icons.logout),
            tooltip: "LOG OUT",
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.0225,
          vertical: MediaQuery.of(context).size.width * 0.0166,
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
                    height: width * 0.5625,
                    color: primary2,
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: width * 0.01),
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.045,
                      vertical: width * 0.01125,
                    ),
                    child: FutureBuilder(
                      future: userFuture,
                      builder: ((context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Something went wrong'),
                          );
                        }

                        if (snapshot.hasData) {
                          final userData = snapshot.data!;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: width * 0.025,
                              ),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // IMAGE, NAME & INFO
                                  CircleAvatar(
                                    radius: width * 0.1195,
                                    backgroundColor: primary2,
                                    backgroundImage: NetworkImage(
                                      userData['Image'],
                                    ),
                                  ),
                                  SizedBox(
                                    width: width * 0.75,
                                    child: Text(
                                      userData['Name']?.toUpperCase() ?? 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: width * 0.07,
                                        fontWeight: FontWeight.w700,
                                        color: primaryDark.withBlue(5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  FeatherIcons.settings,
                                ),
                              ),
                            ],
                          );
                        }

                        return Container();
                      }),
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
