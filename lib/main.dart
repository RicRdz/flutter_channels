import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  static const String sendFromFlutterToNativeChannelName =
      "sendFromFlutterToNativeChannel";
  var sendFromFlutterToAndroidChannel =
      const MethodChannel(sendFromFlutterToNativeChannelName);

  showToast() {
    sendFromFlutterToAndroidChannel.invokeMethod(
        "showToastNative", {"message": "Hi Native, this is sent from Flutter"});
  }

  static const String sendFromNativeToFlutterChannelName =
      "sendFromNativeToFlutterChannel";
  var sendFromAndroidToFlutterChannel =
      const MethodChannel(sendFromNativeToFlutterChannelName);

  askNativeForAMessage() async {
    var result = await sendFromAndroidToFlutterChannel
        .invokeMethod("tellMeSomethingNative");
    final scaffold = _scaffoldKey.currentState;
    final snackBar = SnackBar(
      content: Text(result),
      duration: const Duration(seconds: 5),
    );
    scaffold?.showSnackBar(snackBar);
  }

  static const String counterReadingEventChannelName =
      "counterReadingEventChannel";
  final EventChannel _eventChannel =
      const EventChannel(counterReadingEventChannelName);
  late StreamSubscription _streamSubscription;
  double _currentValue = 0.0;

  void _startListener() {
    _streamSubscription =
        _eventChannel.receiveBroadcastStream().listen(_listenStream);
  }

  void _listenStream(value) {
    debugPrint("Received From Native:  $value\n");
    setState(() {
      _currentValue = value;
    });
  }

  void _cancelListener() {
    _streamSubscription.cancel();
    setState(() {
      _currentValue = 0;
    });
  }

  @override
  void initState() {
    _startListener();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldKey,
      title: 'Flutter Channels Demo',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blueGrey,
          accentColor: Colors.amber,
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Flutter Channels Demo',
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => showToast(),
                child: const Text(
                  'Show Message in Native UI Component',
                  style: TextStyle(
                    color: Colors.amber,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  askNativeForAMessage();
                },
                child: const Text(
                  'Show Flutter SnackBar with Native message',
                  style: TextStyle(
                    color: Colors.amber,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  32,
                  0,
                  8,
                ),
                child: Text(
                  'Event Channels Demo',
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              Text(
                'Value from native side: ${_currentValue.toString()}',
                style: const TextStyle(
                  fontSize: 18.0,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
