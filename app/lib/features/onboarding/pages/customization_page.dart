import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CutomizationPage extends ConsumerStatefulWidget {
  final CallNextPage? callNextPage;

  const CutomizationPage({super.key, required this.callNextPage});

  @override
  ConsumerState<CutomizationPage> createState() => _CutomizationPageState();
}

class _CutomizationPageState extends ConsumerState<CutomizationPage> {
  List<String> selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedItems();
  }

  Future<void> _loadSelectedItems() async {
    final prefs = await sharedPrefs();
    final items = prefs.getStringList('selected_organizations') ?? [];
    setState(() {
      selectedItems = items;
    });
  }

  Future<void> _updateSelectedItems(String title, bool isSelected) async {
    final prefs = await sharedPrefs();
    final currentItems = List<String>.from(selectedItems);
    
    if (isSelected) {
      if (!currentItems.contains(title)) {
        currentItems.add(title);
      }
    } else {
      currentItems.remove(title);
    }
    
    await prefs.setStringList('selected_organizations', currentItems);
    setState(() {
      selectedItems = currentItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
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
                  ..._buildOrganizeCards(context),
                  const SizedBox(height: 20),
                  _actionButtons(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
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
      (lang.activism, PhosphorIcons.handPalm()),
      (lang.localGroup, Icons.location_on_outlined),
      (lang.unionizing, Icons.format_underline_rounded),
      (lang.cooperation, Icons.groups),
      (lang.networkingLearning, PhosphorIcons.network()),
      (lang.communityDrivenProjects, Icons.connect_without_contact_sharp),
      (lang.forAnEvent, PhosphorIcons.calendarCheck()),
      (lang.justFrdAndFamily, Icons.other_houses_outlined),
      (lang.lookAround, Icons.person_pin),
    ];

    return items
        .map((item) => _buildOrganizeCardItem(context, item.$1, item.$2))
        .toList();
  }

  // Single card widget
  Widget _buildOrganizeCardItem(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedItems.contains(title);

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
          await _updateSelectedItems(title, !isSelected);
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
