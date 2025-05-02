import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OnboardingSkeleton extends StatelessWidget {
  const OnboardingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIcon(context),
                    const SizedBox(height: 20),
                    _buildTitleText(context),
                    const SizedBox(height: 20),
                    _buildDescriptionText(context),
                    const SizedBox(height: 20),
                    _buildSettingsList(context),
                    const SizedBox(height: 20),
                    _buildActionButton(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Icon(
      PhosphorIcons.bell(),
      color: Theme.of(context).colorScheme.primary,
      size: 100,
    );
  }

  Widget _buildTitleText(BuildContext context) {
    final lang = L10n.of(context);
    return Text(
      lang.pushNotification,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    final lang = L10n.of(context);
    return Text(
      lang.pushNotificationDesc,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      children: [
        _buildSettingItem(context),
        _buildSettingItem(context),
        _buildSettingItem(context),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context) {
    return const ListTile(
      leading: Icon(Icons.notifications),
      title: Text('Notification Setting'),
      subtitle: Text('Setting description'),
      trailing: Switch(value: true, onChanged: null),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: null,
      child: const Text('Enable Notifications'),
    );
  }
}
