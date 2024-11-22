import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::news_action_actions');

class NewsSlideActions extends ConsumerWidget {
  final NewsSlide newsSlide;

  const NewsSlideActions({
    super.key,
    required this.newsSlide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsReferencesList = newsSlide.references().toList();
    if (newsReferencesList.isEmpty) return const SizedBox();
    final referenceDetails = newsReferencesList.first.refDetails();
    final evtType = NewsReferencesType.fromStr(referenceDetails.typeStr());
    final id = referenceDetails.targetIdStr() ?? '';
    return switch (evtType) {
      NewsReferencesType.calendarEvent =>
        renderCalendarEventAction(context, ref, id),
      NewsReferencesType.pin => renderPinAction(context, ref, id),
      NewsReferencesType.link =>
        renderLinkActionButton(context, ref, referenceDetails),
      _ => renderNotSupportedAction(context)
    };
  }

  Widget renderPinAction(
    BuildContext context,
    WidgetRef ref,
    String pinId,
  ) {
    final lang = L10n.of(context);
    final pinData = ref.watch(pinProvider(pinId));
    final pinError = pinData.asError;
    if (pinError != null) {
      _log.severe('Error loading pin', pinError.error, pinError.stackTrace);
      return Card(
        child: ListTile(
          leading: const Icon(Icons.pin),
          title: Text(lang.pinNoLongerAvailable),
          subtitle: Text(
            lang.pinDeletedOrFailedToLoad,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          onTap: () async {
            await ActerErrorDialog.show(
              context: context,
              error: pinError.error,
              stack: pinError.stackTrace,
              onRetryTap: () => ref.invalidate(pinProvider(pinId)),
            );
          },
        ),
      );
    }
    return PinListItemWidget(pinId: pinId);
  }

  Widget renderCalendarEventAction(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) {
    final lang = L10n.of(context);
    final calEventLoader = ref.watch(calendarEventProvider(eventId));
    return calEventLoader.when(
      data: (calEvent) => EventItem(event: calEvent),
      loading: () => const EventItemSkeleton(),
      error: (e, s) {
        _log.severe('Failed to load cal event', e, s);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(lang.eventNoLongerAvailable),
            subtitle: Text(
              lang.eventDeletedOrFailedToLoad,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () async {
              await ActerErrorDialog.show(
                context: context,
                error: e,
                stack: s,
                onRetryTap: () =>
                    ref.invalidate(calendarEventProvider(eventId)),
              );
            },
          ),
        );
      },
    );
  }

  Widget renderLinkActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails referenceDetails,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final uri = referenceDetails.uri();
    if (uri == null) {
      // malformatted
      return renderNotSupportedAction(context);
    }
    if (referenceDetails.title() == 'shareEvent' && uri.startsWith('\$')) {
      // fallback support for older, badly formatted calendar events.
      return renderCalendarEventAction(context, ref, uri);
    }

    final title = referenceDetails.title();
    if (title != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.link),
          onTap: () => openLink(uri, context),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium,
          ),
          subtitle: Text(
            uri,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.link),
          onTap: () => openLink(uri, context),
          title: Text(
            uri,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium,
          ),
        ),
      );
    }
  }

  Widget renderNotSupportedAction(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(L10n.of(context).unsupportedPleaseUpgrade),
      ),
    );
  }
}
