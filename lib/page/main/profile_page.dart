import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/page/auth/login_page.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/small_text_container.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // LOG OUT
  Future<void> logOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: ((context) => const LoginPage()),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        mySnackBar(e.toString(), context);
      }
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
        title: const Text("PROFILE"),
        actions: [
          IconButton(
            onPressed: () async {
              await logOut(context);
            },
            icon: const Icon(Icons.logout),
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
                    height: width * 0.33,
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: width * 0.01),
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.045,
                      vertical: width * 0.01125,
                    ),
                    decoration: BoxDecoration(
                      color: primary2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FutureBuilder(
                      future: userFuture,
                      builder: ((context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Something went wrong'),
                          );
                        }

                        if (snapshot.hasData) {
                          final userData = snapshot.data!;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // IMAGE, NAME & INFO
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: width * 0.1195,
                                    backgroundColor: primary2,
                                    backgroundImage: NetworkImage(
                                      userData['Image'],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 0.05),
                                    child: SizedBox(
                                      width: width * 0.45,
                                      child: Text(
                                        userData['Name']?.toUpperCase() ??
                                            'N/A',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontSize: width * 0.07,
                                          fontWeight: FontWeight.w700,
                                          color: primaryDark.withBlue(5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  FeatherIcons.settings,
                                ),
                                tooltip: "Edit Info",
                              ),
                            ],
                          );
                        }

                        return Container();
                      }),
                    ),
                  ),
                  const Divider(),

                  // FOLLOWED
                  SmallTextContainer(
                    text: 'Followed',
                    onPressed: () {},
                    width: width,
                  ),

                  // WISHLIST
                  SmallTextContainer(
                    text: 'Wishlist',
                    onPressed: () {},
                    width: width,
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
