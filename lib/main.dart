import 'package:Localsearch_User/firebase_options.dart';
import 'package:Localsearch_User/page/auth/login_page.dart';
import 'package:Localsearch_User/page/auth/register_method_page.dart';
import 'package:Localsearch_User/page/main/get_location_page.dart';
import 'package:Localsearch_User/page/main/main_page.dart';
import 'package:Localsearch_User/providers/location_provider.dart';
import 'package:Localsearch_User/providers/register_details_provider.dart';
import 'package:Localsearch_User/providers/review_provider.dart';
import 'package:Localsearch_User/providers/verification_provider.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
          create: (_) => ReviewProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterDetailsProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localsearch',
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
            iconColor: WidgetStatePropertyAll(
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
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: primaryDark,
                  ),
                );
              }

              if (snapshot.hasData) {
                return const MainPageContent();
              }

              return const GetLocationPage(
                nextPage: LoginPage(),
              );
            },
          ),
          // const ConnectivityNotificationWidget(),
        ],
      ),
    );
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return StreamBuilder<bool>(
      stream: Geolocator.getServiceStatusStream().map((serviceStatus) {
        return serviceStatus == ServiceStatus.enabled;
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.data!) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const GetLocationPage(
                  nextPage: MainPage(),
                ),
              ),
            );
          });
        } else if (locationProvider.cityLatitude == null ||
            locationProvider.cityLongitude == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const GetLocationPage(
                  nextPage: MainPage(),
                ),
              ),
            );
          });
        }

        return const MainPage();
      },
    );
  }
}
