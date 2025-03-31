// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/spaces/has_space_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HasSpacePermission', () {
    const testSpaceId = 'test_space_id';
    const testPermission = 'test_permission';
    const testChild = Text('Child Widget');
    const testFallback = Text('Fallback Widget');

    testWidgets('shows child when permission is granted', (tester) async {
      final container = ProviderContainer(
        overrides: [
          roomPermissionProvider((
            roomId: testSpaceId,
            permission: testPermission,
          )).overrideWith((ref) => Future.value(true)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HasSpacePermission(
                spaceId: testSpaceId,
                permission: testPermission,
                fallback: testFallback,
                child: testChild,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Child Widget'), findsOneWidget);
      expect(find.text('Fallback Widget'), findsNothing);
    });

    testWidgets('shows fallback when permission is denied', (tester) async {
      final container = ProviderContainer(
        overrides: [
          roomPermissionProvider((
            roomId: testSpaceId,
            permission: testPermission,
          )).overrideWith((ref) => Future.value(false)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HasSpacePermission(
                spaceId: testSpaceId,
                permission: testPermission,
                fallback: testFallback,
                child: testChild,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Child Widget'), findsNothing);
      expect(find.text('Fallback Widget'), findsOneWidget);
    });

    testWidgets(
      'shows nothing when fallback is not provided and permission is denied',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            roomPermissionProvider((
              roomId: testSpaceId,
              permission: testPermission,
            )).overrideWith((ref) => Future.value(false)),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: const MaterialApp(
              home: Scaffold(
                body: HasSpacePermission(
                  spaceId: testSpaceId,
                  permission: testPermission,
                  child: testChild,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Child Widget'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );

    testWidgets('shows fallback while permission is loading', (tester) async {
      final completer = Completer<bool>();
      final container = ProviderContainer(
        overrides: [
          roomPermissionProvider((
            roomId: testSpaceId,
            permission: testPermission,
          )).overrideWith((ref) => completer.future),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HasSpacePermission(
                spaceId: testSpaceId,
                permission: testPermission,
                fallback: testFallback,
                child: testChild,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Fallback Widget'), findsOneWidget);
    });

    testWidgets('shows nothing when permission has error', (tester) async {
      final container = ProviderContainer(
        overrides: [
          roomPermissionProvider((
            roomId: testSpaceId,
            permission: testPermission,
          )).overrideWith((ref) => Future.error('Error')),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HasSpacePermission(
                spaceId: testSpaceId,
                permission: testPermission,
                fallback: testFallback,
                child: testChild,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Child Widget'), findsNothing);
      expect(find.text('Fallback Widget'), findsOneWidget);
    });
  });
}
