import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_easy_user/page/main/main_page.dart';
import 'package:find_easy_user/page/providers/sign_in_method_provider.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:find_easy_user/widgets/button.dart';
import 'package:find_easy_user/widgets/head_text.dart';
import 'package:find_easy_user/widgets/snack_bar.dart';
import 'package:find_easy_user/widgets/text_form_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterDetailsPage extends StatefulWidget {
  const RegisterDetailsPage({
    super.key,
  });

  @override
  State<RegisterDetailsPage> createState() => _RegisterDetailsPageState();
}

// TODO: ADDRESS WITH GOOGLE MAPS

class _RegisterDetailsPageState extends State<RegisterDetailsPage> {
  final registerDetailsKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
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
              'Name: Helps Vendors identify you in messages.\n\nStreet Address: To recommend nearby shops to you\n\nCity Name: To show you the shops in your city',
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

  // SAVE
  Future<void> save(SignInMethodProvider signInMethodProvider) async {
    if (selectedGender != null) {
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
                'gender': selectedGender,
              })
            : await FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({
                'Name': nameController.text,
                'Phone Number': '+91${phoneController.text}',
                'gender': selectedGender,
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
    } else {
      mySnackBar('Select Gender', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signInMethodProvider = Provider.of<SignInMethodProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: ((context, constraints) {
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // USER DETAILS HEADTEXT
                  const SizedBox(height: 80),
                  const HeadText(
                    text: "USER\nDETAILS",
                  ),
                  const SizedBox(height: 40),

                  // FORM
                  Form(
                    key: registerDetailsKey,
                    child: Column(
                      children: [
                        // NAME
                        MyTextFormField(
                          hintText: "Name",
                          controller: nameController,
                          borderRadius: 12,
                          horizontalPadding: 0,
                          verticalPadding: 12,
                          autoFillHints: const [AutofillHints.email],
                        ),

                        // EMAIL
                        !signInMethodProvider.isEmailChosen
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
                                      return "Pls enter Email";
                                    }
                                  }
                                  return null;
                                },
                              )
                            // PHONE NUMBER
                            : MyTextFormField(
                                hintText: "Phone Number",
                                controller: phoneController,
                                borderRadius: 12,
                                horizontalPadding: 0,
                                verticalPadding: 12,
                                autoFillHints: const [AutofillHints.email],
                              ),

                        // STREET
                        MyTextFormField(
                          hintText: "Street Address",
                          controller: streetController,
                          borderRadius: 12,
                          horizontalPadding: 0,
                          verticalPadding: 12,
                          autoFillHints: const [AutofillHints.email],
                        ),

                        // CITY
                        MyTextFormField(
                          hintText: "City Name",
                          controller: cityController,
                          borderRadius: 12,
                          horizontalPadding: 0,
                          verticalPadding: 12,
                          autoFillHints: const [AutofillHints.email],
                        ),

                        // SELECT GENDER
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primary3,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            child: DropdownButton(
                              value: selectedGender,
                              hint: const Text(
                                "Select Gender",
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

                        // SAVE
                        MyButton(
                          text: "SAVE",
                          onTap: () async {
                            await save(signInMethodProvider);
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
