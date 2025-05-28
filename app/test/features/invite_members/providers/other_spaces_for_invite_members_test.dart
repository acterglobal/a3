import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/invite_members/providers/other_spaces_for_invite_members.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../helpers/mock_space_providers.dart';

class MockSpace extends Mock implements Space {}

void main() {
  late List<MockSpace> mockSpaces;
  late MockSpace mockSpace1;
  late MockSpace mockSpace2;
  late MockSpace mockSpace3;
  late MockSpace mockSpace4;

  setUp(() {
    mockSpace1 = MockSpace();
    mockSpace2 = MockSpace();
    mockSpace3 = MockSpace();
    mockSpace4 = MockSpace();

    // Setup mock spaces with different room IDs
    when(() => mockSpace1.getRoomIdStr()).thenReturn('space1');
    when(() => mockSpace2.getRoomIdStr()).thenReturn('space2');
    when(() => mockSpace3.getRoomIdStr()).thenReturn('space3');
    when(() => mockSpace4.getRoomIdStr()).thenReturn('space4');

    mockSpaces = [mockSpace1, mockSpace2, mockSpace3, mockSpace4];
  });

  group('otherSpacesForInviteMembersProvider', () {
    testWidgets('returns all spaces except current space and parent spaces', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWith(() => MockSpaceListNotifiers(mockSpaces)),
          parentIdsProvider('space1').overrideWith(
            (ref) => Future.value(['space2']), // space2 is a parent of space1
          ),
        ],
      );

      addTearDown(() => container.dispose());

      // Wait for the provider to complete
      final result = await container.read(
        otherSpacesForInviteMembersProvider('space1').future,
      );

      // Should exclude space1 (current space) and space2 (parent space)
      expect(result.length, 2);
      expect(result, contains(mockSpace3));
      expect(result, contains(mockSpace4));
      expect(result, isNot(contains(mockSpace1)));
      expect(result, isNot(contains(mockSpace2)));
    });

    testWidgets('returns all spaces when no parent spaces exist', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWith(() => MockSpaceListNotifiers(mockSpaces)),
          parentIdsProvider('space1').overrideWith((ref) => Future.value([])),
        ],
      );

      addTearDown(() => container.dispose());

      // Wait for the provider to complete
      final result = await container.read(
        otherSpacesForInviteMembersProvider('space1').future,
      );

      // Should exclude only space1 (current space)
      expect(result.length, 3);
      expect(result, contains(mockSpace2));
      expect(result, contains(mockSpace3));
      expect(result, contains(mockSpace4));
      expect(result, isNot(contains(mockSpace1)));
    });

    testWidgets('throws error when parent spaces are not available', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          spacesProvider.overrideWith(() => MockSpaceListNotifiers(mockSpaces)),
          parentIdsProvider(
            'space1',
          ).overrideWith((ref) => Future.error('Parent spaces not available')),
        ],
      );

      addTearDown(() => container.dispose());

      // Wait for the provider to complete and expect error
      await expectLater(
        container.read(otherSpacesForInviteMembersProvider('space1').future),
        throwsA('Parent spaces not available'),
      );
    });

    testWidgets(
      'returns empty list when all spaces are either current or parent spaces',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            spacesProvider.overrideWith(
              () => MockSpaceListNotifiers(mockSpaces),
            ),
            parentIdsProvider('space1').overrideWith(
              (ref) => Future.value(['space2', 'space3', 'space4']),
            ),
          ],
        );

        addTearDown(() => container.dispose());

        // Wait for the provider to complete
        final result = await container.read(
          otherSpacesForInviteMembersProvider('space1').future,
        );

        expect(result, isEmpty);
      },
    );
  });
}
