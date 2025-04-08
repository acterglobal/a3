import 'package:acter/common/utils/routes.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DesktopSetupPage extends ConsumerStatefulWidget {
  const DesktopSetupPage({super.key});

  @override
  ConsumerState<DesktopSetupPage> createState() => _DesktopSetupPageState();
}

class _DesktopSetupPageState extends ConsumerState<DesktopSetupPage> {
  bool _isFeaturesEnabled = false;

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button at the top right
            Positioned(
              top: 0,
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
                      _buildTitleText(context, lang, textTheme),
                      const SizedBox(height: 20),
                      _buildDescriptionText(lang, textTheme),
                      const SizedBox(height: 20),
                      _buildActivateFeatures(context, lang, textTheme),
                      const SizedBox(height: 20),
                      _buildActionButton(context, lang, textTheme),
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
  Widget _buildTitleText(BuildContext context, L10n lang, TextTheme textTheme) {
    return Text(
      lang.desktopSetup,
      style: textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Description text for the page
  Widget _buildDescriptionText(L10n lang, TextTheme textTheme) {
    return Text(
      lang.desktopSetupInfo,
      style: textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  // Activate features button
  Widget _buildActivateFeatures(
    BuildContext context,
    L10n lang,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _isFeaturesEnabled,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              setState(() {
                _isFeaturesEnabled = newValue;
              });
            }
          },
        ),
        Text(lang.activateFeatures, style: textTheme.bodySmall),
      ],
    );
  }

  // Action button for the page
  Widget _buildActionButton(
    BuildContext context,
    L10n lang,
    TextTheme textTheme,
  ) {
    return OutlinedButton(
      onPressed: () => context.goNamed(Routes.main.name),
      child: Text(
        L10n.of(context).gotIt,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
