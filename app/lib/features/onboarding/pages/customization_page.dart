import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/actions/customization_actions.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CustomizationPage extends ConsumerStatefulWidget {
  final CallNextPage? callNextPage;

  const CustomizationPage({super.key, required this.callNextPage});

  @override
  ConsumerState<CustomizationPage> createState() => _CustomizationPageState();
}

class _CustomizationPageState extends ConsumerState<CustomizationPage> {
  List<CustomizationType> selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedItems();
  }

  Future<void> _loadSelectedItems() async {
    final items = await loadSelectedCustomizations();
    setState(() {
      selectedItems = items;
    });
  }

  Future<void> _updateSelectedItems(CustomizationType type, bool isSelected) async {
    await updateSelectedCustomizations(
      selectedItems,
      type,
      isSelected
    );
    setState(() {
      if (isSelected) {
        if (!selectedItems.contains(type)) {
          selectedItems.add(type);
        }
      } else {
        selectedItems.remove(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeadlineText(context),
                  const SizedBox(height: 10),
                  _buildTitleText(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ..._buildOrganizeCards(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  _actionButtons(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Headline text widget
  Widget _buildHeadlineText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).yourActer,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Title text widget
  Widget _buildTitleText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).goingToOrganize,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // List of organization option cards
  List<Widget> _buildOrganizeCards(BuildContext context) {
    final lang = L10n.of(context);
    final items = [
      (CustomizationType.activism, lang.activism, PhosphorIcons.handPalm()),
      (CustomizationType.localGroup, lang.localGroup, Icons.location_on_outlined),
      (CustomizationType.unionizing, lang.unionizing, Icons.format_underline_rounded),
      (CustomizationType.cooperation, lang.cooperation, Icons.groups),
      (CustomizationType.networkingLearning, lang.networkingLearning, PhosphorIcons.network()),
      (CustomizationType.communityDrivenProjects, lang.communityDrivenProjects, Icons.connect_without_contact_sharp),
      (CustomizationType.forAnEvent, lang.forAnEvent, PhosphorIcons.calendarCheck()),
      (CustomizationType.justFrdAndFamily, lang.justFrdAndFamily, Icons.other_houses_outlined),
      (CustomizationType.lookAround, lang.lookAround, Icons.person_pin),
    ];

    return items
        .map((item) => _buildOrganizeCardItem(context, item.$1, item.$2, item.$3))
        .toList();
  }

  // Single card widget
  Widget _buildOrganizeCardItem(
    BuildContext context,
    CustomizationType type,
    String title,
    IconData icon,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedItems.contains(type);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () async {
          await _updateSelectedItems(type, !isSelected);
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          title: Text(title, style: textTheme.bodyMedium),
          leading: Icon(icon),
        ),
      ),
    );
  }

  // Action buttons
  Widget _actionButtons(BuildContext context) {
    final lang = L10n.of(context);
    final isEnabled = selectedItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: isEnabled ? () => widget.callNextPage?.call() : null,
          child: Text(lang.wizzardContinue),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => widget.callNextPage?.call(),
          child: Text(lang.skip),
        ),
      ],
    );
  }
}
