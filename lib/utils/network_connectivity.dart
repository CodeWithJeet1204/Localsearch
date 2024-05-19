import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityNotificationWidget extends StatefulWidget {
  const ConnectivityNotificationWidget({super.key});

  @override
  _ConnectivityNotificationWidgetState createState() =>
      _ConnectivityNotificationWidgetState();
}

class _ConnectivityNotificationWidgetState
    extends State<ConnectivityNotificationWidget> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // connectivityInitialize();
  }

  @override
  void dispose() {
    // _connectivitySubscription.cancel();
    super.dispose();
  }

  // Future<void> connectivityInitialize() async {
  //   Connectivity().onConnectivityChanged.first.then((initialResult) async {
  //     await updateConnectionStatus(initialResult);
  //   }).then((_) {
  //     _connectivitySubscription =
  //         Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
  //   });
  // }

  Future<void> updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });

    if (result == ConnectivityResult.none) {
      await _showConnectivityDialog(context);
    }
  }

  Future<void> _showConnectivityDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection',
              overflow: TextOverflow.ellipsis),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You are currently offline.',
                    overflow: TextOverflow.ellipsis),
                Text('Connect to network to continue using the app',
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry', overflow: TextOverflow.ellipsis),
              onPressed: () async {
                final currentStatus = await Connectivity().checkConnectivity();
                if (currentStatus != ConnectivityResult.none) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _connectionStatus == ConnectivityResult.none,
      child: const Align(
        alignment: Alignment.topCenter,
      ),
    );
  }
}
