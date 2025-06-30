import 'package:acter/features/activities/widgets/invitation_section/invitation_section_widget.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/invitations/widgets/has_invites_tile.dart';
import 'package:acter/features/invitations/widgets/invitation_item_widget.dart';
import 'package:acter/features/showcases/pages/invitations/mock_invitations.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_util.dart';

class SectionTestWidget extends ConsumerWidget {
  const SectionTestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = InvitationSectionWidget.getInvitations(ref);
    return Column(
      children: [
        SectionHeader(title: '${invitations.length} Invitations'),
        if (InvitationSectionWidget.shouldBeShown(ref))
          Expanded(child: InvitationSectionWidget()),
      ],
    );
  }
}

void main() {
  group('InvitationSectionWidget Static Methods', () {
    late List<MockRoomInvitation> mockInvitations;

    setUp(() {
      mockInvitations = generateMockInvitations(5);
    });
    testWidgets('shows nothing', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [invitationListProvider.overrideWith((ref) => [])],
        child: const SectionTestWidget(),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SectionTestWidget), findsOneWidget);
      expect(find.text('0 Invitations'), findsOneWidget);
      expect(find.byType(InvitationSectionWidget), findsNothing);
    });

    testWidgets('shows  when there is one invitation', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          invitationListProvider.overrideWith((ref) => [mockInvitations[0]]),
        ],
        child: const SectionTestWidget(),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SectionTestWidget), findsOneWidget);
      expect(find.text('1 Invitations'), findsOneWidget);
      expect(find.byType(InvitationSectionWidget), findsOneWidget);
    });

    testWidgets('shows when there are multiple invitations', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          invitationListProvider.overrideWith((ref) => mockInvitations),
        ],
        child: const SectionTestWidget(),
      );

      await tester.pumpAndSettle();
      expect(find.byType(SectionTestWidget), findsOneWidget);
      expect(find.text('5 Invitations'), findsOneWidget);
      expect(find.byType(InvitationSectionWidget), findsOneWidget);
    });
  });

  group('InvitationSectionWidget instance directly', () {
    late List<MockRoomInvitation> mockInvitations;

    setUp(() {
      mockInvitations = List.generate(
        3,
        (index) => MockRoomInvitation(
          roomId: 'roomId$index',
          senderId: 'senderId$index',
          senderDisplayNameStr: 'senderDisplayName$index',
          roomDisplayNameStr: 'roomDisplayName$index',
        ),
      );
    });

    testWidgets('shows nothing when there are no invitations', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [invitationListProvider.overrideWith((ref) => [])],
        child: const InvitationSectionWidget(),
      );

      await tester.pumpAndSettle();
      expect(find.byType(InvitationSectionWidget), findsOneWidget);
      expect(find.byType(InvitationItemWidget), findsNothing);
      expect(find.byType(HasInvitesTile), findsNothing);
    });

    testWidgets('shows InvitationItemWidget when there is one invitation', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          invitationListProvider.overrideWith((ref) => [mockInvitations[0]]),
        ],
        child: const InvitationSectionWidget(),
      );

      await tester.pumpAndSettle();
      expect(find.byType(InvitationSectionWidget), findsOneWidget);
      expect(find.byType(InvitationItemWidget), findsOneWidget);
      expect(find.byType(HasInvitesTile), findsNothing);
    });

    testWidgets('shows HasInvitesTile when there are multiple invitations', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          invitationListProvider.overrideWith((ref) => mockInvitations),
        ],
        child: const InvitationSectionWidget(),
      );

      await tester.pumpAndSettle();
      expect(find.byType(InvitationSectionWidget), findsOneWidget);
      expect(find.byType(InvitationItemWidget), findsNothing);
      expect(find.byType(HasInvitesTile), findsOneWidget);

      final context = tester.element(find.byType(InvitationSectionWidget));
      expect(
        find.text(L10n.of(context).pendingInvitesCount(3)),
        findsOneWidget,
      ); // Verify the count is shown
    });
  });
}
