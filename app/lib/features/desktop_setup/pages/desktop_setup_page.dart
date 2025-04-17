import 'package:acter/features/desktop_setup/providers/desktop_setup_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DesktopSetupWidget extends ConsumerStatefulWidget {
  const DesktopSetupWidget({super.key});

  @override
  ConsumerState<DesktopSetupWidget> createState() => _DesktopSetupWidgetState();
}

class _DesktopSetupWidgetState extends ConsumerState<DesktopSetupWidget> {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final launchAtStartup = ref.read(launchAtStartupProvider);
    final isEnabled = await launchAtStartup.isEnabled();
    if (mounted) {
      ref.read(desktopFeaturesProvider.notifier).state = isEnabled;
    }
  }

  Future<void> handleEnable() async {
    final launchAtStartup = ref.read(launchAtStartupProvider);
    final success = await launchAtStartup.enable();
    if (success) {
      await _init();
    }
  }

  Future<void> handleDisable() async {
    final launchAtStartup = ref.read(launchAtStartupProvider);
    final success = await launchAtStartup.disable();
    if (success) {
      await _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final isFeaturesEnabled = ref.watch(desktopFeaturesProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button at the top right
            Positioned(
              top: 20,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            Center(
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
                        isFeaturesEnabled,
                        ref,
                      ),
                      const SizedBox(height: 40),
                      _buildActionButton(context, lang),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    bool isFeaturesEnabled,
    WidgetRef ref,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: isFeaturesEnabled,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              ref.read(desktopFeaturesProvider.notifier).state = newValue;
              if (newValue) {
                handleEnable();
              } else {
                handleDisable();
              }
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
      onPressed: () => Navigator.pop(context),
      child: Text(
        lang.wizzardContinue,
        style: textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }
}
