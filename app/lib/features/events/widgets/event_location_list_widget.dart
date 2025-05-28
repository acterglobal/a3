import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EventLocationListWidget extends ConsumerWidget {
  final VoidCallback onAdd;

  const EventLocationListWidget({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final locations = ref.watch(eventLocationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, lang),
        locations.isEmpty ? _buildEmptyState(context) : _buildLocationList(context, ref, locations),
        if (locations.isNotEmpty) _buildActionButton(context, ref),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, L10n lang) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lang.eventLocations,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: lang.addLocation,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        L10n.of(context).noLocationsAdded,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildLocationList(
    BuildContext context,
    WidgetRef ref,
    List<EventLocationDraft> locations,
  ) {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: locations.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return _buildLocationTile(context, ref, locations[index]);
        },
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
    WidgetRef ref,
    EventLocationDraft location,
  ) {
    final theme = Theme.of(context);
    final isVirtual = location.type == LocationType.virtual;

    return ListTile(
      leading: Icon(
        isVirtual ? Icons.language : Icons.map_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(location.name),
      subtitle: Text(
        isVirtual ? (location.url ?? '') : (location.address?.split('\n').first ?? ''),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(PhosphorIcons.trash(), color: theme.colorScheme.error),
        onPressed: () =>
            ref.read(eventLocationsProvider.notifier).removeLocation(location),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    return Padding(padding: const EdgeInsets.all(16.0), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      Expanded(child: OutlinedButton(
        onPressed: () {
          ref.read(eventLocationsProvider.notifier).clearLocations();
          Navigator.of(context).pop();
        },
        child: Text(L10n.of(context).cancel),
       )),
       const SizedBox(width: 16),
       Expanded(child: ActerPrimaryActionButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L10n.of(context).save),
        ),
       ),
      ],
    ));
  }
}
