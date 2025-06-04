import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class EventLocationListWidget extends ConsumerWidget {
  final VoidCallback onAdd;
  final Function(EventLocationDraft location)? onEdit;
  final String? eventId;

  const EventLocationListWidget({
    super.key, 
    required this.onAdd,
    this.onEdit,
    this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final locations = eventId != null 
        ? ref.watch(asyncEventLocationsProvider(eventId!)).valueOrNull ?? []
        : ref.watch(eventLocationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, lang),
        locations.isEmpty
            ? _buildEmptyState(context)
            : _buildLocationList(context, ref, locations),
        _buildActionButton(context, ref),
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
    List<dynamic> locations,
  ) {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: locations.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final location = locations[index];
          return _buildLocationTile(context, ref, location);
        },
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
    WidgetRef ref,
    dynamic location,
  ) {
    final theme = Theme.of(context);
    final isVirtual = location is EventLocationInfo 
        ? location.locationType().toLowerCase() == LocationType.virtual.name
        : location.type == LocationType.virtual;

    return ListTile(
      leading: Icon(
        isVirtual ? Icons.language : Icons.map_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(location is EventLocationInfo ? location.name() ?? '' : location.name),
      subtitle: Text(
        isVirtual
            ? (location is EventLocationInfo ? location.uri() ?? '' : location.url ?? '')
            : (location is EventLocationInfo 
                ? location.address()?.split('\n').first ?? ''
                : location.address?.split('\n').first ?? ''),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: location is EventLocationInfo
          ? IconButton(
              icon: Icon(PhosphorIcons.trash(), color: theme.colorScheme.error),
              onPressed: () {
    
              },
            )
          : IconButton(
              icon: Icon(PhosphorIcons.trash(), color: theme.colorScheme.error),
              onPressed: () => ref
                  .read(eventLocationsProvider.notifier)
                  .removeLocation(location),
            ),
      onTap: () {
        final draftLocation = EventLocationDraft(
            name: location.name() ?? '',
            type: location.locationType().toLowerCase() == LocationType.virtual.name 
                ? LocationType.virtual 
                : LocationType.physical,
            url: location.uri(),
            address: location.address(),
            note: location.notes(),
          );
          if (onEdit != null) {
            onEdit?.call(draftLocation);
          }
      },
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                showDiscardLocationDialog(context, ref);
              },
              child: Text(L10n.of(context).cancel),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ActerPrimaryActionButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context).save),
            ),
          ),
        ],
      ),
    );
  }

  void showDiscardLocationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final lang = L10n.of(context);
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(lang.discardChanges)],
          ),
          content: Text(lang.discardChangesDescription),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(child: Text(lang.keepChanges), onPressed: () => Navigator.pop(context)),
            ActerPrimaryActionButton(
              onPressed: () {
                ref.read(eventLocationsProvider.notifier).clearLocations();
                Navigator.pop(context);
              },
              child: Text(lang.discard),
            ),
          ],
        );
      },
    );
  }
}
