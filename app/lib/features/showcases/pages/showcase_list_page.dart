import 'package:acter/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const List<ShowCaseItem> _chatShowcase = [
  (title: 'Chat List', route: Routes.chatListShowcase),
];

const List<ShowCaseItem> _activityShowcase = [
  (title: 'Activity List', route: Routes.activityListShowcase),
];

const List<ShowCaseItem> _onboardingShowcase = [
  (
    title: 'Encryption Recovery',
    route: Routes.showCaseOnboardingEncryptionRecovery,
  ),
  (
    title: 'Encryption Backup',
    route: Routes.showCaseOnboardingEncryptionBackup,
  ),
];

const List<ShowCaseItem> _invitationsShowcase = [
  (title: 'Invitations', route: Routes.invitationsSectionShowcase),
];

typedef ShowCaseGroup = ({String title, List<ShowCaseItem> items});

typedef ShowCaseItem = ({String title, Routes route});

// The actual group of items in their order
const List<ShowCaseGroup> _showCases = [
  (title: 'Onboarding Wizard', items: _onboardingShowcase),
  (title: 'Chat Ng', items: _chatShowcase),
  (title: 'Activities', items: _activityShowcase),
  (title: 'Invitations', items: _invitationsShowcase),
];

class ShowcaseListPage extends StatelessWidget {
  const ShowcaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Showcase List')),
      body: ListView.builder(
        itemCount: _showCases.length,
        itemBuilder: (BuildContext context, int index) {
          final showcase = _showCases[index];
          final title = showcase.title;
          final items = showcase.items;

          // Return a widget representing the title and its items
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = items[index];
                  // Return a widget representing the item
                  return ListTile(
                    title: Text(item.title),
                    onTap: () => context.pushNamed(item.route.name),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
