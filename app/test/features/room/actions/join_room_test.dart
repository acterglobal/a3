import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' as sdk;
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as sdk_ffi;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:acter/l10n/generated/l10n.dart';

import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_space_providers.dart';

// Mocks
class MockClient extends Mock implements sdk.Client {}

class MockRoom extends Mock implements sdk_ffi.Room {}

class MockSdkApi extends Mock implements sdk_ffi.Api {
  final MockVecStringBuilder _vecStringBuilder;

  MockSdkApi(this._vecStringBuilder);

  @override
  sdk_ffi.VecStringBuilder newVecStringBuilder() => _vecStringBuilder;
}

class MockSdk extends Mock implements sdk.ActerSdk {
  final MockSdkApi _api;

  MockSdk(this._api);

  @override
  sdk_ffi.Api get api => _api;
}

class MockVecStringBuilder extends Mock implements sdk_ffi.VecStringBuilder {}

class MockWidgetRef extends Mock implements WidgetRef {}

class MockBuildContext extends Mock implements BuildContext {
  L10n? _l10n;
  L10n get l10n => _l10n ?? MockL10n();
  set l10n(L10n value) => _l10n = value;
}

class MockL10n extends Mock implements L10n {
  @override
  String tryingToJoin(Object roomId) => 'Joining room...';

  @override
  String joiningFailed(Object error) => 'Failed to join room';
}

class FakeRefreshable extends Fake implements Refreshable<Object?> {}

class TestApp extends StatelessWidget {
  final Widget child;

  const TestApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child, builder: EasyLoading.init());
  }
}

class MockHasRecommendedSpaceJoinedController extends Mock
    implements StateController<bool> {
  @override
  bool get state => false;
  @override
  set state(bool value) {
    // do nothing
  }
}

void main() {
  late MockClient mockClient;
  late MockRoom mockRoom;
  late MockSdk mockSdk;
  late MockVecStringBuilder mockVecStringBuilder;
  late MockWidgetRef mockRef;
  late MockL10n mockL10n;
  late MockHasRecommendedSpaceJoinedController
  mockHasRecommendedSpaceJoinedController;

  setUpAll(() {
    // Register fallback values for types used with any()
    registerFallbackValue(MockVecStringBuilder());
    registerFallbackValue(MockRoom());
    registerFallbackValue(MockClient());
    registerFallbackValue(FakeRefreshable());
  });

  setUp(() {
    mockClient = MockClient();
    mockRoom = MockRoom();
    mockVecStringBuilder = MockVecStringBuilder();
    mockSdk = MockSdk(MockSdkApi(mockVecStringBuilder));
    mockRef = MockWidgetRef();
    mockL10n = MockL10n();
    mockHasRecommendedSpaceJoinedController =
        MockHasRecommendedSpaceJoinedController();

    // Setup default behaviors
    when(
      () => mockRef.read(hasRecommendedSpaceJoinedProvider.notifier),
    ).thenReturn(mockHasRecommendedSpaceJoinedController);
    when(
      () => mockRef.read(alwaysClientProvider.future),
    ).thenAnswer((_) => Future.value(mockClient));
    when(
      () => mockRef.read(sdkProvider.future),
    ).thenAnswer((_) => Future.value(mockSdk));
    when(() => mockRoom.isJoined()).thenReturn(true);
    when(() => mockRoom.isSpace()).thenReturn(false);
  });

  group('joinRoom', () {
    testWidgets('successfully joins a room', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(
        () => mockRef.refresh(maybeRoomProvider('!test:example.com').future),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRoom.roomIdStr()).thenReturn('!test:example.com');
      when(
        () => mockRef.refresh(chatProvider('!test:example.com').future),
      ).thenAnswer((_) => Future.value(MockConvo(roomId: '!test:example.com')));

      // Act
      final result = await joinRoom(
        lang: mockL10n,
        ref: mockRef,
        roomIdOrAlias: '!test:example.com',
        serverNames: ['example.com'],
      );
      // Assert
      expect(result, equals('!test:example.com'));
      verify(() => mockClient.joinRoom('!test:example.com', any())).called(1);
      verify(() => mockVecStringBuilder.add('example.com')).called(1);
      verify(
        () => mockRef.refresh(chatProvider('!test:example.com').future),
      ).called(1);
    });
    testWidgets('successfully joins a chat that takes a while to load', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(
        () => mockRef.refresh(maybeRoomProvider('!test:example.com').future),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRoom.roomIdStr()).thenReturn('!test:example.com');
      int counter = 0;
      when(
        () => mockRef.refresh(chatProvider('!test:example.com').future),
      ).thenAnswer((_) {
        counter++;
        return Future.value(MockConvo(roomId: '!test:example.com'));
      });

      // Act
      final result = await joinRoom(
        lang: mockL10n,
        ref: mockRef,
        roomIdOrAlias: '!test:example.com',
        serverNames: ['example.com'],
      );
      // Assert
      expect(result, equals('!test:example.com'));
      verify(() => mockClient.joinRoom('!test:example.com', any())).called(1);
      verify(() => mockVecStringBuilder.add('example.com')).called(1);
      verify(
        () => mockRef.invalidate(chatProvider('!test:example.com')),
      ).called(1);
      expect(counter, equals(1));
    });

    testWidgets('joins a chat that takes a while to load and doesn\'t load', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(
        () => mockRef.refresh(maybeRoomProvider('!test:example.com').future),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRoom.roomIdStr()).thenReturn('!test:example.com');
      when(
        () => mockRef.refresh(chatProvider('!test:example.com').future),
      ).thenAnswer(
        (_) => Future.error('Failed to load'),
      ); // this provider fails to load

      // Act
      final result = await joinRoom(
        lang: mockL10n,
        ref: mockRef,
        roomIdOrAlias: '!test:example.com',
        serverNames: ['example.com'],
      );
      // Assert
      expect(result, isNull);
      verify(() => mockClient.joinRoom('!test:example.com', any())).called(1);
      verify(() => mockVecStringBuilder.add('example.com')).called(1);
      verify(
        () => mockRef.invalidate(chatProvider('!test:example.com')),
      ).called(1);
    });

    testWidgets('successfully joins a space', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(
        () => mockRef.refresh(maybeRoomProvider('!test2:example.com').future),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRoom.roomIdStr()).thenReturn('!test2:example.com');
      when(() => mockRoom.isSpace()).thenReturn(true);
      when(
        () => mockRef.refresh(maybeSpaceProvider('!test2:example.com').future),
      ).thenAnswer((_) {
        return Future.value(MockSpace());
      });

      // Act
      final result = await joinRoom(
        lang: mockL10n,
        ref: mockRef,
        roomIdOrAlias: '!test2:example.com',
        serverNames: ['otherserver.org'],
      );

      // Assert
      expect(result, equals('!test2:example.com'));
      verify(
        () => mockRef.refresh(maybeSpaceProvider('!test2:example.com').future),
      ).called(1);
      verify(() => mockVecStringBuilder.add('otherserver.org')).called(1);
    });

    testWidgets('successfully joins a space that takes a while to load', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(
        () => mockRef.refresh(maybeRoomProvider('!test2:example.com').future),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRoom.roomIdStr()).thenReturn('!test2:example.com');
      when(() => mockRoom.isSpace()).thenReturn(true);

      int counter = 0;
      when(
        () => mockRef.refresh(maybeSpaceProvider('!test2:example.com').future),
      ).thenAnswer((_) {
        counter++;
        if (counter < 4) {
          return Future.value(null);
        }
        return Future.value(MockSpace());
      });

      // Act
      final result = await tester.runAsync(
        () async => await joinRoom(
          lang: mockL10n,
          ref: mockRef,
          roomIdOrAlias: '!test2:example.com',
          serverNames: ['otherserver.org'],
        ),
      );

      // Assert
      expect(result, equals('!test2:example.com'));
      verify(
        () => mockRef.refresh(maybeSpaceProvider('!test2:example.com').future),
      ).called(4);
      verify(() => mockVecStringBuilder.add('otherserver.org')).called(1);
      expect(counter, equals(4));
    });

    testWidgets('joins a space that takes a while to load and doesn\'t load', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(
        () => mockRef.refresh(maybeRoomProvider('!test2:example.com').future),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRoom.roomIdStr()).thenReturn('!test2:example.com');
      when(() => mockRoom.isSpace()).thenReturn(true);
      when(
        () => mockRef.refresh(maybeSpaceProvider('!test2:example.com').future),
      ).thenAnswer((_) => Future.value(null));

      // Act
      final result = await tester.runAsync(
        () async => await joinRoom(
          lang: mockL10n,
          ref: mockRef,
          roomIdOrAlias: '!test2:example.com',
          serverNames: ['otherserver.org'],
        ),
      );

      // Assert
      expect(result, isNull);
      verify(
        () => mockRef.refresh(maybeSpaceProvider('!test2:example.com').future),
      ).called(20);
      verify(() => mockVecStringBuilder.add('otherserver.org')).called(1);
    });

    testWidgets('handles join failure', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenThrow(Exception('Failed to join'));

      // Act
      final result = await joinRoom(
        lang: mockL10n,
        ref: mockRef,
        roomIdOrAlias: '!test:example.com',
        serverNames: ['example.com'],
      );

      // Assert
      expect(result, isNull);
    });

    testWidgets('throws error when throwOnError is true', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenThrow(Exception('Failed to join'));

      // Act & Assert
      await expectLater(
        joinRoom(
          lang: mockL10n,
          ref: mockRef,
          roomIdOrAlias: '!test:example.com',
          serverNames: ['example.com'],
          throwOnError: true,
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('handles timeout when loading room', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const TestApp(child: SizedBox()));
      await tester.pumpAndSettle();

      when(
        () => mockClient.joinRoom(any(), any()),
      ).thenAnswer((_) => Future.value(mockRoom));
      when(() => mockRef.refresh(any())).thenAnswer((_) => Future.value(null));

      // Act
      final result = await joinRoom(
        lang: mockL10n,
        ref: mockRef,
        roomIdOrAlias: '!test:example.com',
        serverNames: ['example.com'],
      );

      // Assert
      expect(result, isNull);
    });
  });
}
