import 'package:acter/features/activities/widgets/invitation_section/invitation_section_widget.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/showcases/pages/invitations/mock_invitations.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mockInvitations = generateMockInvitations(5);

class InvitationsSectionShowcasePage extends StatelessWidget {
  const InvitationsSectionShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitations Section')),
      body: Column(
        children: [
          SectionHeader(title: 'One Invitation'),
          ProviderScope(
            overrides: [
              invitationListProvider.overrideWith(
                (ref) => Future.value([mockInvitations[2]]),
              ),
            ],
            child: InvitationSectionWidget(),
          ),

          SectionHeader(title: '5 Invitations'),
          ProviderScope(
            overrides: [
              invitationListProvider.overrideWith(
                (ref) => Future.value(mockInvitations),
              ),
            ],
            child: InvitationSectionWidget(),
          ),
          SectionHeader(title: 'No Invitations'),
          ProviderScope(
            overrides: [
              invitationListProvider.overrideWith((ref) => Future.value([])),
            ],
            child: InvitationSectionWidget(),
          ),
        ],
      ),
    );
  }
}
