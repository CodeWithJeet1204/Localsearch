import 'package:Localsearch_User/providers/location_provider.dart';
import 'package:Localsearch_User/utils/colors.dart';
import 'package:Localsearch_User/widgets/snack_bar.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class GetLocationPage extends StatefulWidget {
  const GetLocationPage({
    super.key,
    required this.nextPage,
  });

  final Widget nextPage;

  @override
  State<GetLocationPage> createState() => _GetLocationPageState();
}

class _GetLocationPageState extends State<GetLocationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> _animation;

  // INIT STATE
  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 0.1).animate(animationController);

    monitorLocationService();
  }

  // DISPOSE
  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  // MONITOR LOCATION SERVICE
  Future<void> monitorLocationService() async {
    while (true) {
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!isServiceEnabled) {
        if (mounted) {
          mySnackBar('Turn ON Location Services on the next page', context);
          await Future.delayed(Duration(seconds: 1));
          await Geolocator.openLocationSettings();
        }
      } else {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setLocation(context.read<LocationProvider>());
          });
        }
        break;
      }

      await Future.delayed(Duration(seconds: 1));
    }
  }

  // GET LOCATION
  Future<Position?> getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    while (true) {
      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        await Geolocator.openLocationSettings();
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          continue;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permissions are permanently denied. Enable them in Settings.',
              style: const TextStyle(
                color: Color.fromARGB(255, 240, 252, 255),
              ),
            ),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              textColor: primary2,
            ),
            elevation: 2,
            backgroundColor: primaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dismissDirection: DismissDirection.down,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(Duration(seconds: 1));
        continue;
      }

      return await Geolocator.getCurrentPosition();
    }
  }

  // SET LOCATION
  Future<void> setLocation(LocationProvider locationProvider) async {
    print('hahahhaha');
    await getLocation().then((coordinates) {
      if (coordinates != null) {
        final latitude = coordinates.latitude;
        final longitude = coordinates.longitude;

        locationProvider.changeCity({
          'Your Location': {
            'cityId': 'Your Location',
            'cityName': 'Your Location',
            'cityLatitude': latitude,
            'cityLongitude': longitude,
          },
        });
      }
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => widget.nextPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: primary2,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_animation.value * height),
                child: Icon(
                  FeatherIcons.mapPin,
                  size: width * 0.2,
                  color: primaryDark,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
