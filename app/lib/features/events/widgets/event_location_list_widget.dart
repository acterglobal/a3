import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/features/events/widgets/add_event_location_widget.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class EventLocationListWidget extends ConsumerStatefulWidget {
  final String? eventId;

  const EventLocationListWidget({
    super.key, 
    this.eventId,
  });

  @override
  ConsumerState<EventLocationListWidget> createState() => _EventLocationListWidgetState();
}

class _EventLocationListWidgetState extends ConsumerState<EventLocationListWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      // Load async locations into the provider when widget initializes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final asyncLocations = ref.read(asyncEventLocationsProvider(widget.eventId!)).valueOrNull;
        if (asyncLocations != null) {
          final locations = asyncLocations.map((location) => EventLocationDraft(
            name: location.name() ?? '',
            type: location.locationType().toLowerCase() == LocationType.virtual.name 
                ? LocationType.virtual 
                : LocationType.physical,
            url: location.uri(),
            address: location.address(),
            note: location.notes(),
          )).toList();
          ref.read(eventDraftLocationsProvider.notifier).clearLocations();
          for (final location in locations) {
            ref.read(eventDraftLocationsProvider.notifier).addLocation(location);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final locations = ref.watch(eventDraftLocationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, lang),
        locations.isEmpty
            ? _buildEmptyState(context)
            : _buildLocationList(context, ref, locations),
        locations.isNotEmpty ? _buildActionButton(context, ref) : const SizedBox.shrink(),
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
              onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: true,
              enableDrag: true,
              showDragHandle: true,
              useSafeArea: true,
              builder:
                  (context) => AddEventLocationWidget(),
            ),
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
      trailing: IconButton(
        icon: Icon(PhosphorIcons.trash(), color: theme.colorScheme.error),
        onPressed: () {
          if (location is EventLocationInfo) {
            // Handle deletion of existing location
            final draftLocation = EventLocationDraft(
              name: location.name() ?? '',
              type: location.locationType().toLowerCase() == LocationType.virtual.name 
                  ? LocationType.virtual 
                  : LocationType.physical,
              url: location.uri(),
              address: location.address(),
              note: location.notes(),
            );
            ref.read(eventDraftLocationsProvider.notifier).removeLocation(draftLocation);
          } else {
            // Handle deletion of draft location
            ref.read(eventDraftLocationsProvider.notifier).removeLocation(location);
          }
        },
      ),
      onTap: () {
        final draftLocation = location is EventLocationInfo
            ? EventLocationDraft(
                name: location.name() ?? '',
                type: location.locationType().toLowerCase() == LocationType.virtual.name 
                    ? LocationType.virtual 
                    : LocationType.physical,
                url: location.uri(),
                address: location.address(),
                note: location.notes(),
              )
            : location;
         showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: true,
              enableDrag: true,
              showDragHandle: true,
              useSafeArea: true,
              builder:
                  (context) => AddEventLocationWidget(
                    initialLocation: draftLocation,
                  ),
            );
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
                ref.read(eventDraftLocationsProvider.notifier).clearLocations();
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
