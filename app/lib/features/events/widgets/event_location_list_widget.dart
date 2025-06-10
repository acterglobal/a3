import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/events/actions/save_event_locations.dart';
import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:acter/features/events/widgets/add_event_location_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';

class EventLocationListWidget extends ConsumerStatefulWidget {
  final String? eventId;

  const EventLocationListWidget({super.key, this.eventId});

  @override
  ConsumerState<EventLocationListWidget> createState() => _EventLocationListWidgetState();
}

class _EventLocationListWidgetState extends ConsumerState<EventLocationListWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadExistingLocations(ref, widget.eventId!);
      });
    }
  }

Future<void> loadExistingLocations(WidgetRef ref, String eventId) async {
  final asyncLocations = ref.read(asyncEventLocationsProvider(eventId)).valueOrNull;
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
}

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final locations = ref.watch(eventDraftLocationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, lang),
        if (locations.isEmpty)
          _buildEmptyState(context)
        else ...[
          _buildLocationList(context, locations),
          _buildActionButtons(context),
        ],
      ],
    );
  }

  /// Header with title and Add button
  Widget _buildHeader(BuildContext context, L10n lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Text(lang.eventLocations, style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: lang.addLocation,
            onPressed: () => _openAddLocationModal(context),
          ),
        ],
      ),
    );
  }

  /// Message when there are no locations
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        L10n.of(context).noLocationsAdded,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// List of locations
  Widget _buildLocationList(BuildContext context, List<EventLocationDraft> locations) {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return _buildLocationTile(context, location);
        },
      ),
    );
  }

  /// Individual location tile
  Widget _buildLocationTile(BuildContext context, EventLocationDraft draftLocation) {
    final theme = Theme.of(context);
    final isVirtual = draftLocation.type == LocationType.virtual;

    return ListTile(
      leading: Icon(isVirtual ? Icons.language : Icons.map_outlined, color: theme.colorScheme.primary),
      title: Text(draftLocation.name),
      subtitle: Text(
        isVirtual ? (draftLocation.url ?? '') : (draftLocation.address?.split('\n').first ?? ''),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(PhosphorIcons.trash(), color: theme.colorScheme.error),
        onPressed: () => ref.read(eventDraftLocationsProvider.notifier).removeLocation(draftLocation),
      ),
      onTap: () => _openEditLocationModal(context, draftLocation),
    );
  }

  /// Bottom save/discard buttons
  Widget _buildActionButtons(BuildContext context) {
    final lang = L10n.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showDiscardDialog(context),
              child: Text(lang.cancel),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ActerPrimaryActionButton(
              onPressed: () {
                final eventId = widget.eventId;
                if (eventId != null) {
                  saveEventLocations(
                    context: context,
                    ref: ref,
                    calendarId: eventId,
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(lang.save),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddLocationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const AddEventLocationWidget(),
    );
  }

  void _openEditLocationModal(BuildContext context, EventLocationDraft draftLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AddEventLocationWidget(initialLocation: draftLocation),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    final lang = L10n.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.discardChanges),
        content: Text(lang.discardChangesDescription),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text(lang.keepChanges),
          ),
          ActerPrimaryActionButton(
            onPressed: () {
              ref.read(eventDraftLocationsProvider.notifier).clearLocations();
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close EventLocationListWidget
            },
            child: Text(lang.discard),
          ),
        ],
      ),
    );
  }
}
