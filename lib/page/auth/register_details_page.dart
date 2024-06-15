import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localy_user/page/main/main_page.dart';
import 'package:localy_user/utils/colors.dart';
import 'package:localy_user/widgets/button.dart';
import 'package:localy_user/widgets/head_text.dart';
import 'package:localy_user/widgets/snack_bar.dart';
import 'package:localy_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterDetailsPage extends StatefulWidget {
  const RegisterDetailsPage({
    super.key,
    required this.emailPhoneGoogleChosen,
  });

  final int? emailPhoneGoogleChosen;

  @override
  State<RegisterDetailsPage> createState() => _RegisterDetailsPageState();
}

class _RegisterDetailsPageState extends State<RegisterDetailsPage> {
  final registerDetailsKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  double? latitude;
  double? longitude;
  String? address;
  bool isSaving = false;
  String? selectedGender;

  // SHOW INFO DIALOG
  Future<void> showInfoDialog() async {
    await showDialog(
      context: context,
      builder: ((context) {
        return const Dialog(
          backgroundColor: primary2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Name: Helps Vendors identify you in messages.\n\nLocation: To recommend nearby shops to you',
              style: TextStyle(
                color: primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }

  // GET LOCATION
  Future<Position?> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      mySnackBar('Turn ON Location Services to Continue', context);
      return null;
    } else {
      LocationPermission permission = await Geolocator.checkPermission();

      // LOCATION PERMISSION GIVEN
      Future<Position> locationPermissionGiven() async {
        print("Permission given");
        return await Geolocator.getCurrentPosition();
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          mySnackBar('Pls give Location Permission to Continue', context);
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          setState(() {
            latitude = 0;
            longitude = 0;
            address = "NONE";
          });
          mySnackBar(
            'Because Location permission is denied, We are continuing without Location',
            context,
          );
        } else {
          return await locationPermissionGiven();
        }
      } else {
        return await locationPermissionGiven();
      }
    }
    return null;
  }

  // GET ADDRESS
  Future<void> getAddress(double lat, double long) async {
    print("Getting address");
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
    setState(() {
      address =
          '${placemarks[0].name}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}';
    });
    print("address got");
  }

  // SAVE
  Future<void> save() async {
    if (registerDetailsKey.currentState!.validate()) {
      if (address == null) {
        return mySnackBar('Get Location', context);
      }
      if (selectedGender == null) {
        return mySnackBar('Select Gender', context);
      }
      setState(() {
        isSaving = true;
      });

      try {
        FirebaseAuth.instance.currentUser!.email == null
            ? await FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({
                'Name': nameController.text,
                'Email': emailController.text,
                'Gender': selectedGender,
                'Latitude': latitude,
                'Longitude': longitude,
              })
            : await FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({
                'Name': nameController.text,
                'Phone Number': '+91${phoneController.text}',
                'Gender': selectedGender,
                'Latitude': latitude,
                'Longitude': longitude,
              });

        setState(() {
          isSaving = false;
        });
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          return mySnackBar(e.toString(), context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // USER DETAILS HEADTEXT
                  const SizedBox(height: 80),
                  const HeadText(
                    text: 'USER\nDETAILS',
                  ),
                  const SizedBox(height: 40),

                  // FORM
                  Form(
                    key: registerDetailsKey,
                    child: Column(
                      children: [
                        // NAME
                        MyTextFormField(
                          hintText: 'Name',
                          controller: nameController,
                          borderRadius: 12,
                          horizontalPadding: 0,
                          verticalPadding: 12,
                          autoFillHints: const [AutofillHints.email],
                        ),

                        // EMAIL
                        widget.emailPhoneGoogleChosen == 2
                            ? TextFormField(
                                autofillHints: const [AutofillHints.email],
                                autofocus: false,
                                controller: emailController,
                                onTapOutside: (event) =>
                                    FocusScope.of(context).unfocus(),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.cyan.shade700,
                                    ),
                                  ),
                                  hintText: 'Email',
                                ),
                                validator: (value) {
                                  if (value != null) {
                                    if (value.isNotEmpty) {
                                      if (value.contains('@') &&
                                          value.contains('.co')) {
                                        return null;
                                      } else {
                                        return 'Enter valid Email';
                                      }
                                    } else {
                                      return 'Pls enter Email';
                                    }
                                  }
                                  return null;
                                },
                              )

                            // PHONE NUMBER
                            : MyTextFormField(
                                hintText: 'Phone Number',
                                controller: phoneController,
                                borderRadius: 12,
                                horizontalPadding: 0,
                                verticalPadding: 12,
                                autoFillHints: const [],
                                keyboardType: TextInputType.number,
                              ),

                        SizedBox(height: 8),

                        // LOCATION
                        GestureDetector(
                          onTap: () async {
                            await getLocation().then((value) async {
                              if (value != null) {
                                setState(() {
                                  latitude = value.latitude;
                                  longitude = value.longitude;
                                });

                                if (latitude != null && longitude != null) {
                                  await getAddress(latitude!, longitude!);
                                }
                              }
                            });
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: primary2,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: EdgeInsets.all(width * 0.025),
                              child: Text(
                                address ?? 'Get Location',
                                style: TextStyle(
                                  fontSize: width * 0.045,
                                  color: primaryDark2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        // SELECT GENDER
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: primary3,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: DropdownButton(
                                value: selectedGender,
                                hint: const Text(
                                  'Select Gender',
                                  style: TextStyle(
                                    color: primaryDark2,
                                  ),
                                ),
                                underline: const SizedBox(),
                                iconEnabledColor: primaryDark,
                                dropdownColor: primary2,
                                items: ['Male', 'Female']
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        // SAVE
                        MyButton(
                          text: 'SAVE',
                          onTap: () async {
                            await save();
                          },
                          isLoading: isSaving,
                          horizontalPadding: 0,
                          verticalPadding: 12,
                        ),
                      ],
                    ),
                  ),

                  // INFO
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await showInfoDialog();
                          },
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                          ),
                        ),
                        const Text(
                          'Why we collect this info?',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
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
