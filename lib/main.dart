import 'package:find_easy_user/firebase_options.dart';
import 'package:find_easy_user/page/auth/login_page.dart';
import 'package:find_easy_user/page/auth/register_details_page.dart';
import 'package:find_easy_user/page/auth/register_method_page.dart';
import 'package:find_easy_user/page/auth/verify/email_verify.dart';
import 'package:find_easy_user/page/main/main_page.dart';
import 'package:find_easy_user/providers/register_details_provider.dart';
import 'package:find_easy_user/providers/sign_in_method_provider.dart';
import 'package:find_easy_user/providers/verification_provider.dart';
import 'package:find_easy_user/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SignInMethodProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VerificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterDetailsProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  if (FirebaseAuth.instance.currentUser != null) {
    print(FirebaseAuth.instance.currentUser!.uid);
  } else {
    print("No user");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final signInMethodProvider = Provider.of<SignInMethodProvider>(context);
    final bool emailChosen = signInMethodProvider.isEmailChosen;
    final bool numberChosen = signInMethodProvider.isNumberChosen;
    final bool googleChosen = signInMethodProvider.isGoogleChosen;
    final registerWithDetailsProvider =
        Provider.of<RegisterDetailsProvider>(context);
    final bool isRegisteredWithDetails =
        registerWithDetailsProvider.isRegisteredWithDetails;
    final verificationProvider = Provider.of<VerificationProvider>(context);
    final bool isVerified = verificationProvider.isVerified;

    return MaterialApp(
      title: 'Find Easy',
      theme: ThemeData(
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryDark2,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(),
          textStyle: TextStyle(
            fontSize: 22,
            color: primaryDark2,
            fontWeight: FontWeight.w600,
          ),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(
              color: primaryDark2,
            ),
          ),
        ),
        scaffoldBackgroundColor: primary,
        appBarTheme: const AppBarTheme(
          // toolbarHeight: 50,
          backgroundColor: primary,
          foregroundColor: primaryDark,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: primaryDark,
            fontSize: 22,
            letterSpacing: 1,
          ),
          iconTheme: IconThemeData(
            color: primaryDark,
          ),
        ),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStatePropertyAll(
              primaryDark,
            ),
          ),
        ),
        indicatorColor: primaryDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 10, 217, 213),
        ),
        useMaterial3: true,
      ),
      routes: {
        '/register': ((context) => RegisterMethodPage()),
      },
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData &&
                (emailChosen || numberChosen || googleChosen) &&
                isRegisteredWithDetails) {
              return const MainPage();
            } else if (snapshot.hasData &&
                (emailChosen || numberChosen || googleChosen) &&
                !isVerified) {
              return emailChosen
                  ? EmailVerifyPage()
                  : googleChosen
                      ? MainPage()
                      : RegisterMethodPage();
            } else if (snapshot.hasData &&
                (emailChosen || numberChosen || googleChosen) &&
                !isRegisteredWithDetails) {
              return RegisterDetailsPage();
            } else if (snapshot.hasData &&
                (emailChosen == false &&
                    numberChosen == false &&
                    googleChosen == false)) {
              return RegisterDetailsPage();
            } else if (snapshot.hasError) {
              return const Center(
                child: Text("Some error occured\nClose & Open the app again"),
              );
            } else {
              return const LoginPage();
            }
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryDark,
              ),
            );
          } else {
            return const LoginPage();
          }
        }),
      ),
    );
  }
}
