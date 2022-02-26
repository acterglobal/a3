import 'package:effektio_flutter_sdk_example/constants.dart';
import 'package:effektio_flutter_sdk_example/test_suites/interface.dart';
import 'package:effektio_flutter_sdk_example/test_suites/login.dart';
import 'package:effektio_flutter_sdk_example/test_suites/profile_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

void main() async {
  runApp(MyApp());
}

final testSuites = {
  "Login": () => LoginTest(),
  "Avatar": () => AvatarTest(),
};

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Effektio SDK tests'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: testSuites.keys
                .map(
                  (name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) {
                            return TestPage(name, key: UniqueKey());
                          }),
                        );
                      },
                      child: Text(name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class TestPage extends StatefulWidget {
  final String name;

  const TestPage(this.name, {Key? key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late TestSuite suite;
  SuiteState suiteState = SuiteState.Uninitialized;
  List<String> logLines = [];

  @override
  void initState() {
    super.initState();
    suite = testSuites[widget.name]!();
    suite.setup().then((_) async {
      setState(() {
        suiteState = SuiteState.Executing;
      });
      await suite.executeTest().forEach((line) {
        setState(() {
          logLines.add(line);
        });
      });
    })
    .then((_) async {
      await suite.teardown();
      setState(() {
        suiteState = SuiteState.Finished;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildTitle(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logLines.map((e) => Text(e)).toList(),
          ),
        ),
      ),
    );
  }

  Widget buildTitle() {
    switch (suiteState) {
      case SuiteState.Uninitialized:
        return Text('${widget.name}: Initializing...');
      case SuiteState.Executing:
        return Text('${widget.name}: Executing...');
      case SuiteState.Finished:
        return Text('${widget.name}: Finished');
    }
  }
}
