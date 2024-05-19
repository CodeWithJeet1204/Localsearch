import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:find_easy_user/widgets/video_tutorial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final storage = FirebaseStorage.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  bool isChangingName = false;
  bool isChangingNumber = false;
  bool isChangingImage = false;
  bool isSaving = false;
  bool isDataLoaded = false;

  // DISPOSE
  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    super.dispose();
  }

  // SAVE
  void save() async {
    try {
      setState(() {
        isSaving = true;
      });
      if (isChangingName && !isChangingNumber) {
        if (nameController.text.isEmpty) {
          mySnackBar('Name should be atleast 1 characters long', context);
          setState(() {
            isSaving = false;
          });
          return;
        } else {
          Map<String, dynamic> updatedUserName = {
            'Name': nameController.text.toString(),
          };
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update(updatedUserName);
        }
        setState(() {
          isSaving = false;
          isChangingName = false;
          isChangingNumber = false;
        });
      } else if (!isChangingName && isChangingNumber) {
        if (numberController.text.length != 10) {
          mySnackBar('Number should be 10 characters long', context);
          setState(() {
            isSaving = false;
          });
          return;
        } else {
          Map<String, dynamic> updatedUserNumber = {
            'Phone Number': numberController.text.toString(),
          };
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update(updatedUserNumber);
          setState(() {
            isSaving = false;
            isChangingName = false;
            isChangingNumber = false;
          });
        }
      } else if (isChangingName && isChangingNumber) {
        if (nameController.text.isEmpty) {
          setState(() {
            isSaving = false;
          });
          return mySnackBar(
            'Name should be atleast 1 characters long',
            context,
          );
        }
        if (numberController.text.length != 10) {
          setState(() {
            isSaving = false;
          });
          return mySnackBar(
            'Number should be 10 characters long',
            context,
          );
        } else {
          // NAME
          Map<String, dynamic> updatedUserName = {
            'Name': nameController.text.toString(),
          };
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update(updatedUserName);

          // NUMBER
          Map<String, dynamic> updatedUserNumber = {
            'Phone Number': numberController.text.toString(),
          };
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update(updatedUserNumber);
          setState(() {
            isSaving = false;
            isChangingName = false;
            isChangingNumber = false;
          });
        }
      }
      setState(() {
        isSaving = false;
      });
    } catch (e) {
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'User Details',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await showYouTubePlayerDialog(
                context,
                getYoutubeVideoId(
                  '',
                ),
              );
            },
            icon: Icon(
              Icons.question_mark_outlined,
            ),
            tooltip: "Help",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            double width = constraints.maxWidth;

            return StreamBuilder(
                stream: userStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Something went wrong',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }

                  if (snapshot.hasData) {
                    final userData = snapshot.data!;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: width * 0.1111125),

                          // NAME
                          Container(
                            width: width,
                            height:
                                isChangingName ? width * 0.2775 : width * 0.175,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primary2.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isChangingName
                                ? TextField(
                                    autofocus: true,
                                    controller: nameController,
                                    onTapOutside: (event) =>
                                        FocusScope.of(context).unfocus(),
                                    decoration: InputDecoration(
                                      hintText: 'Change Name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.only(left: width * 0.05),
                                        child: SizedBox(
                                          width: width * 0.725,
                                          child: AutoSizeText(
                                            userData['Name'] ?? 'Name N/A',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: width * 0.06,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          right: width * 0.03,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              isChangingName = true;
                                            });
                                          },
                                          icon: const Icon(FeatherIcons.edit),
                                          tooltip: 'Edit Name',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 14),

                          // PHONE NUMBER
                          Container(
                            width: width,
                            height: isChangingNumber
                                ? width * 0.2775
                                : width * 0.175,
                            decoration: BoxDecoration(
                              color: primary2.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isChangingNumber
                                ? TextField(
                                    autofocus: true,
                                    controller: numberController,
                                    onTapOutside: (event) =>
                                        FocusScope.of(context).unfocus(),
                                    decoration: InputDecoration(
                                      hintText: 'Change Number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: width * 0.055,
                                        ),
                                        child: SizedBox(
                                          width: width * 0.725,
                                          child: AutoSizeText(
                                            userData['Phone Number'] ??
                                                'Phone Number N/A',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: width * 0.055,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          right: width * 0.03,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              isChangingNumber = true;
                                            });
                                          },
                                          icon: const Icon(FeatherIcons.edit),
                                          tooltip: 'Edit Phone Number',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 14),

                          // EMAIL ADDRESS
                          Container(
                            width: width,
                            height: width * 0.16,
                            decoration: BoxDecoration(
                              color: primary2.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: width * 0.055,
                                  ),
                                  child: SizedBox(
                                    width: width * 0.725,
                                    child: AutoSizeText(
                                      userData['Email'] ?? 'Email N/A',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: width * 0.055,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // GENDER
                          Container(
                            width: width,
                            height: width * 0.175,
                            decoration: BoxDecoration(
                              color: userData['gender'] == 'Male'
                                  ? const Color.fromARGB(255, 148, 207, 255)
                                  : userData['gender'] == 'Female'
                                      ? Color.fromARGB(255, 255, 200, 218)
                                      : primary2.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: width * 0.055,
                                top: width * 0.045,
                              ),
                              child: SizedBox(
                                width: width * 0.725,
                                height: width * 0.175,
                                child: Text(
                                  userData['gender'] ?? 'Gender N/A',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: width * 0.055,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // SAVE & CANCEL BUTTON
                          isChangingName || isChangingNumber
                              ? Column(
                                  children: [
                                    // SAVE
                                    isSaving
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            alignment: Alignment.center,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: buttonColor,
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: white,
                                              ),
                                            ))
                                        : MyButton(
                                            text: 'SAVE',
                                            onTap: save,
                                            isLoading: false,
                                            horizontalPadding: 0,
                                          ),
                                    const SizedBox(height: 12),

                                    // CANCEL
                                    MyButton(
                                      text: 'CANCEL',
                                      onTap: () {
                                        setState(() {
                                          isChangingName = false;
                                          isChangingNumber = false;
                                        });
                                      },
                                      isLoading: false,
                                      horizontalPadding: 0,
                                    ),
                                  ],
                                )
                              : Container(),
                        ],
                      ),
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                });
          }),
        ),
      ),
    );
  }
}
