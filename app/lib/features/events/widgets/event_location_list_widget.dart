import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventLocationListWidget extends ConsumerWidget {
  final VoidCallback onAdd;

  const EventLocationListWidget({
    super.key,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = L10n.of(context);
    final locations = ref.watch(eventLocationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
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
        ),
        if (locations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              lang.noLocationsAdded,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                return ListTile(
                  leading: Icon(
                    loc.type == LocationType.virtual
                        ? Icons.language
                        : Icons.map_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(loc.name),
                  subtitle: Text(
                    loc.type == LocationType.virtual
                        ? (loc.url ?? '')
                        : (loc.address?.split('\n').first ?? ''),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: theme.colorScheme.error),
                    onPressed: () => ref
                        .read(eventLocationsProvider.notifier)
                        .removeLocation(loc),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
