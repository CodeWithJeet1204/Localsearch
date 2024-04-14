import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/image_pick_dialog.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// TODO: ADDRESS WITH GOOGLE MAPS

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

  // CHANGE USER IMAGE
  void changeImage(String previousUrl) async {
    XFile? im = await showImagePickDialog(context);
    String? userPhotoUrl;
    if (im != null) {
      try {
        setState(() {
          isChangingImage = true;
        });
        await storage.refFromURL(previousUrl).delete();

        Map<String, dynamic> updatedUserImage = {
          "Image": im.path,
        };
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('Profile/Users')
            .child(auth.currentUser!.uid);
        await ref
            .putFile(File(updatedUserImage['Image']!))
            .whenComplete(() async {
          await ref.getDownloadURL().then((value) {
            userPhotoUrl = value;
          });
        });
        updatedUserImage = {
          "Image": userPhotoUrl,
        };
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update(updatedUserImage);

        setState(() {
          isChangingImage = false;
        });
      } catch (e) {
        setState(() {
          isChangingImage = false;
        });
        if (mounted) {
          mySnackBar(e.toString(), context);
        }
      }
    } else {
      if (mounted) {
        mySnackBar("Image not selected", context);
      }
    }
  }

  // SAVE
  void save() async {
    try {
      setState(() {
        isSaving = true;
      });
      if (isChangingName && !isChangingNumber) {
        if (nameController.text.isEmpty) {
          mySnackBar("Name should be atleast 1 characters long", context);
          setState(() {
            isSaving = false;
          });
          return;
        } else {
          Map<String, dynamic> updatedUserName = {
            "Name": nameController.text.toString(),
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
          mySnackBar("Number should be 10 characters long", context);
          setState(() {
            isSaving = false;
          });
          return;
        } else {
          Map<String, dynamic> updatedUserNumber = {
            "Phone Number": numberController.text.toString(),
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
            "Name should be atleast 1 characters long",
            context,
          );
        }
        if (numberController.text.length != 10) {
          setState(() {
            isSaving = false;
          });
          return mySnackBar(
            "Number should be 10 characters long",
            context,
          );
        } else {
          // NAME
          Map<String, dynamic> updatedUserName = {
            "Name": nameController.text.toString(),
          };
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update(updatedUserName);

          // NUMBER
          Map<String, dynamic> updatedUserNumber = {
            "Phone Number": numberController.text.toString(),
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

  // SHOW IMAGE
  void showImage() {
    final imageStream = FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots();

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: ((context) {
        return StreamBuilder(
            stream: imageStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    'Something went wrong',
                  ),
                );
              }

              if (snapshot.hasData) {
                final userData = snapshot.data!;
                return Dialog(
                  elevation: 20,
                  child: InteractiveViewer(
                    child: Image.network(
                      userData['Image'],
                    ),
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryDark,
                ),
              );
            });
      }),
    );
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
          overflow: TextOverflow.ellipsis,
          "User Details",
        ),
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
                        "Something went wrong",
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
                          isChangingImage
                              ? Container(
                                  width: width * 0.3,
                                  height: width * 0.3,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryDark,
                                    ),
                                  ),
                                )
                              : Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    GestureDetector(
                                      onTap: showImage,
                                      child: CircleAvatar(
                                        radius: width * 0.15,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          userData['Image'] ??
                                              'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/ProhibitionSign2.svg/800px-ProhibitionSign2.svg.png',
                                        ),
                                        backgroundColor: primary2,
                                      ),
                                    ),
                                    Positioned(
                                      right: -(width * 0.0015),
                                      bottom: -(width * 0.0015),
                                      child: IconButton.filledTonal(
                                        onPressed: () {
                                          changeImage(userData['Image']);
                                        },
                                        icon: Icon(
                                          FeatherIcons.camera,
                                          size: width * 0.1,
                                        ),
                                        tooltip: "Change Photo",
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 14),

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
                                    decoration: InputDecoration(
                                      hintText: "Change Name",
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
                                            userData['Name'] ?? 'N/A',
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
                                          tooltip: "Edit Name",
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
                                    decoration: InputDecoration(
                                      hintText: "Change Number",
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
                                            userData['Phone Number'] ?? 'N/A',
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
                                          tooltip: "Edit Phone Number",
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
                                      userData['Email'] ?? 'N/A',
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
                                      ? const Color.fromARGB(255, 255, 142, 180)
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
                                  userData['gender'] ?? 'N/A',
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
                                            text: "SAVE",
                                            onTap: save,
                                            isLoading: false,
                                            horizontalPadding: 0,
                                          ),
                                    const SizedBox(height: 12),

                                    // CANCEL
                                    MyButton(
                                      text: "CANCEL",
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
