import 'package:effektio_flutter_sdk_example/test_suites/interface.dart';
import 'package:effektio_flutter_sdk_example/test_suites/login.dart';
import 'package:effektio_flutter_sdk_example/test_suites/profile_image.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(const MyApp());
}

final testSuites = {
  "Login": () => LoginTest(),
  "Avatar": () => AvatarTest(),
};

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
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
  SuiteState suiteState = SuiteState.uninitialized;
  List<String> logLines = [];

  @override
  void initState() {
    super.initState();
    suite = testSuites[widget.name]!();
    suite.setup().then((_) async {
      setState(() {
        suiteState = SuiteState.executing;
      });
      try {
        await suite.executeTest().forEach((line) {
          setState(() {
            logLines.add(line);
          });
        });
      } catch (e) {
        setState(() {
          logLines.add(e.toString());
        });
        rethrow;
      }
    })
    .then((_) async {
      await suite.teardown();
      setState(() {
        suiteState = SuiteState.finished;
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
      case SuiteState.uninitialized:
        return Text('${widget.name}: Initializing...');
      case SuiteState.executing:
        return Text('${widget.name}: Executing...');
      case SuiteState.finished:
        return Text('${widget.name}: Finished');
    }
  }
}
