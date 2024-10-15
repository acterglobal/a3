import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route {}

class RoutableMainPage extends StatelessWidget {
  static Key gotoBtn = const Key('routable-main-page-to-button');
  final Widget Function(BuildContext) builder;

  const RoutableMainPage({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing navigation'),
      ),
      body: TextButton(
        key: gotoBtn,
        onPressed: () {
          final route = MaterialPageRoute(builder: builder);
          Navigator.of(context).push(route);
        },
        child: const Text('Navigate to details page!'),
      ),
    );
  }
}
