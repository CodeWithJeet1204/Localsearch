import 'dart:convert';
import 'package:localsearch/providers/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localsearch/page/main/main_page.dart';
import 'package:localsearch/utils/colors.dart';
import 'package:localsearch/widgets/button.dart';
import 'package:localsearch/widgets/snack_bar.dart';
import 'package:localsearch/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
  final registerDetailsKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  double? latitude;
  double? longitude;
  String? address;
  String? selectedGender;
  bool isGettingLocation = false;
  bool isSaving = false;

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

  // GET ADDRESS
  Future<void> getAddress(double shopLatitude, double shopLongitude) async {
    const apiKey = 'AIzaSyA-CD3MgDBzAsjmp_FlDbofynMMmW6fPsU';
    final apiUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$shopLatitude,$shopLongitude&key=$apiKey';

    String? myAddress;
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          myAddress = data['results'][0]['formatted_address'];
        } else {
          if (mounted) {
            mySnackBar('Failed to get address', context);
          }
        }
      } else {
        if (mounted) {
          mySnackBar('Failed to load data', context);
        }
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(e.toString(), context);
      }
    }
    setState(() {
      address = myAddress?.isNotEmpty == true
          ? myAddress!.length > 40
              ? '${myAddress.substring(0, 40)}...'
              : myAddress
          : 'No address found';
    });
  }

  // SAVE
  Future<void> save() async {
    if (registerDetailsKey.currentState!.validate()) {
      if (address == null) {
        return mySnackBar('Get Location', context);
      }
      if (selectedGender == null) {
        return mySnackBar(
          'Select Gender',
          context,
        );
      }
      setState(() {
        isSaving = true;
      });

      try {
        if (auth.currentUser!.email == null) {
          await auth.currentUser!
              .verifyBeforeUpdateEmail(emailController.text.trim());
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Verify Email'),
              content: Text(
                'Open mail, and verify your email to set it as your email',
              ),
            ),
          );

          await store.collection('Users').doc(auth.currentUser!.uid).update({
            'Name': nameController.text.trim(),
            'Email': emailController.text.trim(),
            'Gender': selectedGender,
            'Latitude': latitude,
            'Longitude': longitude,
          });
        } else {
          await store.collection('Users').doc(auth.currentUser!.uid).update({
            'Name': nameController.text.trim(),
            'Phone Number': '+91 ${phoneController.text.trim()}',
            'Gender': selectedGender,
            'Latitude': latitude,
            'Longitude': longitude,
          });
        }

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
    final width = MediaQuery.of(context).size.width;
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Details*'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.045),
          child: LayoutBuilder(
            builder: ((context, constraints) {
              final width = constraints.maxWidth;

              return SingleChildScrollView(
                child: Form(
                  key: registerDetailsKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // FORM
                      MyTextFormField(
                        hintText: 'Name',
                        controller: nameController,
                        borderRadius: 12,
                        horizontalPadding: 0,
                        verticalPadding: 12,
                        autoFillHints: const [],
                      ),

                      // EMAIL
                      widget.emailPhoneGoogleChosen == 2
                          ? MyTextFormField(
                              hintText: 'Email',
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              borderRadius: 12,
                              horizontalPadding: 0,
                              autoFillHints: const [AutofillHints.email],
                            )

                          // PHONE NUMBER
                          : MyTextFormField(
                              hintText: 'Phone Number',
                              controller: phoneController,
                              borderRadius: 12,
                              horizontalPadding: 0,
                              verticalPadding: 12,
                              autoFillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              keyboardType: TextInputType.number,
                            ),

                      const SizedBox(height: 8),

                      // LOCATION
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            isGettingLocation = true;
                          });

                          final cityLatitude = locationProvider.cityLatitude;
                          final cityLongitude = locationProvider.cityLongitude;

                          setState(() {
                            latitude = cityLatitude;
                            longitude = cityLongitude;
                          });

                          if (latitude != null && longitude != null) {
                            await getAddress(latitude!, longitude!);
                          }
                          setState(() {
                            isGettingLocation = false;
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
                            child: isGettingLocation
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Text(
                                    address ?? 'Get Location',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: width * 0.045,
                                      color: primaryDark2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // SELECT GENDER
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primary2,
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

                      // INFO
                      // Padding(
                      //   padding: EdgeInsets.only(
                      //     bottom: MediaQuery.of(context).viewInsets.bottom,
                      //   ),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.start,
                      //     children: [
                      //       IconButton(
                      //         onPressed: () async {
                      //           await showInfoDialog();
                      //         },
                      //         icon: const Icon(
                      //           Icons.info_outline_rounded,
                      //           size: 20,
                      //         ),
                      //       ),
                      //       const Text(
                      //         'Why we collect this info?',
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
