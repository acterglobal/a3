import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mocktail/mocktail.dart';

class MockGoRouter extends Mock implements GoRouter {
  @override
  Future<T?> pushNamed<T extends Object?>(
    String? name, {
    Map<String, String>? pathParameters = const <String, String>{},
    Map<String, dynamic>? queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    super.noSuchMethod(Invocation.method(
        #pushNamed, [name, extra, pathParameters, queryParameters],),);
    return Future.value(null);
  }
}

class MockGoRouterProvider extends StatelessWidget {
  const MockGoRouterProvider({
    required this.goRouter,
    required this.child,
    super.key,
  });

  /// The mock navigator used to mock navigation calls.
  final GoRouter goRouter;

  /// The child [Widget] to render.
  final Widget child;

  @override
  Widget build(BuildContext context) => InheritedGoRouter(
        goRouter: goRouter,
        child: child,
      );
}
