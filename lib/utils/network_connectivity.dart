// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';

// class ConnectivityNotificationWidget extends StatefulWidget {
//   const ConnectivityNotificationWidget({Key? key}) : super(key: key);

//   @override
//   ConnectivityNotificationWidgetState createState() =>
//       ConnectivityNotificationWidgetState();
// }

// class ConnectivityNotificationWidgetState
//     extends State<ConnectivityNotificationWidget> {
//   // ignore: unused_field
//   ConnectivityResult _connectionStatus = ConnectivityResult.none;
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;

//   @override
//   void initState() {
//     super.initState();
//     connectivityInitialize();
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription.cancel();
//     super.dispose();
//   }

//   Future<void> connectivityInitialize() async {
//     final initialResult = await Connectivity().checkConnectivity();
//     await updateConnectionStatus(initialResult);

//     _connectivitySubscription = Connectivity()
//         .onConnectivityChanged
//         .listen((ConnectivityResult result) {
//       updateConnectionStatus(result);
//     });
//   }

//   Future<void> updateConnectionStatus(ConnectivityResult result) async {
//     setState(() {
//       _connectionStatus = result;
//     });

//     if (result == ConnectivityResult.none) {
//       await _showConnectivityDialog(context);
//     } else {
//       if (Navigator.canPop(context)) {
//         Navigator.pop(context);
//       }
//     }
//   }

//   Future<dynamic> _showConnectivityDialog(BuildContext context) async {
//     return await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('No Internet Connection'),
//           content: const SingleChildScrollView(
//             child: ListBody(
//               children: <Widget>[
//                 Text('You are currently offline.'),
//                 Text('Connect to network to continue using the app.'),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Retry'),
//               onPressed: () async {
//                 final currentStatus = await Connectivity().checkConnectivity();
//                 if (currentStatus != ConnectivityResult.none) {
//                   if (mounted) {
//                     Navigator.pop(context);
//                   }
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const SizedBox.shrink();
//   }
// }
