// ignore_for_file: avoid_print
import 'package:localy_user/firebase_options.dart';
import 'package:localy_user/page/auth/login_page.dart';
import 'package:localy_user/page/auth/register_method_page.dart';
import 'package:localy_user/page/main/main_page.dart';
import 'package:localy_user/page/providers/register_details_provider.dart';
import 'package:localy_user/page/providers/verification_provider.dart';
import 'package:localy_user/utils/colors.dart';
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
    print('No user');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localy User',
      theme: ThemeData(
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryDark2,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
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
          seedColor: primary2,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          backgroundColor: white,
          modalBarrierColor: white,
          surfaceTintColor: white,
          shadowColor: white,
          dragHandleColor: white,
          modalBackgroundColor: white,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/register': ((context) => const RegisterMethodPage()),
      },
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: ((context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: primaryDark,
                  ),
                );
              }

              if (snapshot.hasData) {
                return const MainPage();
              }

              return const LoginPage();
            }),
          ),
          // const ConnectivityNotificationWidget(),
        ],
      ),
    );
  }
}
