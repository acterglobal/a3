import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const List<ShowCaseItem> _chatShowcase = [
  (
    title: 'Chat List',
    route: Routes.chatListShowcase,
    icon: Icons.chat_bubble_outline,
  ),
];

const List<ShowCaseItem> _activityShowcase = [
  (
    title: 'Activity List',
    route: Routes.activityListShowcase,
    icon: Icons.timeline,
  ),
];

const List<ShowCaseItem> _onboardingShowcase = [
  (
    title: 'Encryption Recovery',
    route: Routes.showCaseOnboardingEncryptionRecovery,
    icon: Icons.security,
  ),
  (
    title: 'Encryption Backup',
    route: Routes.showCaseOnboardingEncryptionBackup,
    icon: Icons.backup,
  ),
];

const List<ShowCaseItem> _invitationsShowcase = [
  (
    title: 'Invitations',
    route: Routes.invitationsSectionShowcase,
    icon: Icons.mail_outline,
  ),
];

typedef ShowCaseGroup =
    ({String title, List<ShowCaseItem> items});

typedef ShowCaseItem = ({String title, Routes route, IconData icon});

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
      appBar: AppBar(title: Text(L10n.of(context).showcaseList)),
      body: ListView(
        children:
            _showCases
                .map((showcase) => _buildShowcaseSection(context, showcase))
                .toList(),
      ),
    );
  }

  Widget _buildShowcaseSection(BuildContext context, ShowCaseGroup showcase) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(showcase.title, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),  
          const SizedBox(height: 16),

          // Items List
          ...showcase.items.map((item) => _buildShowcaseItem(context, item)),
        ],
      ),
    );
  }

    Widget _buildShowcaseItem(BuildContext context, ShowCaseItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: colorScheme.primary,
          size: 24,
        ),
        title: Text(
          item.title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        onTap: () => context.pushNamed(item.route.name),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withAlpha(20),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
