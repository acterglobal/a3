import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/features/onboarding/widgets/create_new_space_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingSpaceCreationPage extends ConsumerWidget {
  final CallNextPage? callNextPage;

  const OnboardingSpaceCreationPage({super.key, required this.callNextPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIcon(context),
                      const SizedBox(height: 20),
                      _buildHeadlineText(context),
                      const SizedBox(height: 10),
                      _buildDescriptionText(context),
                    ],
                  ),
                ),
                _buildActionButton(context, L10n.of(context)),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Icon(
      Icons.groups_rounded,
      color: Theme.of(context).colorScheme.primary,
      size: 120,
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).createNewSpace,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Title text widget
  Widget _buildDescriptionText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).createOnboardingSpaceDes,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {
            showCreateNewSpaceView(context);
          },
          child: Text(
            lang.createFirstSpace,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            EasyLoading.dismiss();
            callNextPage?.call();
          },
          child: Text(lang.skip),
        ),
      ],
    );
  }

  Future<void> showCreateNewSpaceView(BuildContext context) async {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return const CreateNewSpaceWidget();
      },
    );
  }
}
