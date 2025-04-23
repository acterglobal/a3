import 'package:acter/features/desktop_setup/providers/desktop_setup_provider.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DesktopLaunchAtStartupWidget extends ConsumerStatefulWidget {
  final CallNextPage? callNextPage; 
  const DesktopLaunchAtStartupWidget({super.key, required this.callNextPage});

  @override
  ConsumerState<DesktopLaunchAtStartupWidget> createState() => _DesktopLaunchAtStartupWidgetState();
}

class _DesktopLaunchAtStartupWidgetState extends ConsumerState<DesktopLaunchAtStartupWidget> {
  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
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
                      _buildTitleText(context, lang),
                      const SizedBox(height: 20),
                      _buildDescriptionText(context, lang),
                      const SizedBox(height: 20),
                      _buildActivateFeatures(
                        context,
                        lang,
                        ref,
                      ),
                      const SizedBox(height: 40),
                      _buildActionButton(context, lang),
                    ],
                  ),
                ),
            ),
        ),
      ),
    );
  }

  // Icon at the top of the page
  Widget _buildIcon(BuildContext context) {
    return Icon(
      PhosphorIcons.desktop(),
      color: Theme.of(context).colorScheme.primary,
      size: 100,
    );
  }

  // Title text for the page
  Widget _buildTitleText(BuildContext context, L10n lang) {
    return Text(
      lang.desktopSetup,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Description text for the page
  Widget _buildDescriptionText(BuildContext context, L10n lang) {
    return Text(
      lang.desktopSetupInfo,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  // Activate features button
  Widget _buildActivateFeatures(
    BuildContext context,
    L10n lang,
    WidgetRef ref,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = ref.watch(desktopLaunchAtStartupNotifierProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: isEnabled,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              ref.read(desktopLaunchAtStartupNotifierProvider.notifier)
                  .toggleLaunchAtStartup(newValue);
            }
          },
        ),
        Text(lang.activateFeatures, style: textTheme.bodySmall),
      ],
    );
  }

  // Action button for the page
  Widget _buildActionButton(BuildContext context, L10n lang) {
    final textTheme = Theme.of(context).textTheme;
    return ElevatedButton(
      onPressed: widget.callNextPage,
      child: Text(
        lang.wizzardContinue,
        style: textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }
}
