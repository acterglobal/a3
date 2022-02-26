import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

void main() async {
  final api = await EffektioSdk.instance;
  runApp(MyApp(await api.currentClient));
}

class MyApp extends StatefulWidget {
  final Client api;
  const MyApp(this.api, {Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(widget.api.isGuest().toString()),
        ),
      ),
    );
  }
}
