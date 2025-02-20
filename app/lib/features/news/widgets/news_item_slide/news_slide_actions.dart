import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/themes/components/text_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UpdateSlideActions extends ConsumerWidget {
  final UpdateSlide newsSlide;

  const UpdateSlideActions({
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
    final roomId = referenceDetails.roomIdStr() ?? '';
    return switch (evtType) {
      NewsReferencesType.calendarEvent => EventItem(
          eventId: id,
          refDetails: referenceDetails,
        ),
      NewsReferencesType.pin => PinListItemWidget(
          pinId: id,
          refDetails: referenceDetails,
          showPinIndication: true,
        ),
      NewsReferencesType.taskList => TaskListItemCard(
          taskListId: id,
          refDetails: referenceDetails,
          showOnlyTaskList: true,
          canExpand: false,
          showTaskListIndication: true,
        ),
      NewsReferencesType.link =>
        renderLinkActionButton(context, ref, referenceDetails),
      NewsReferencesType.space => RoomCard(
          roomId: roomId,
          refDetails: referenceDetails,
        ),
      NewsReferencesType.chat => RoomCard(
          roomId: roomId,
          refDetails: referenceDetails,
          onTap: () {
            goToChat(context, roomId);
          },
        ),
      NewsReferencesType.superInvite =>
        renderInvitationCodeActionButton(context, ref, referenceDetails),
      _ => renderNotSupportedAction(context),
    };
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
      return EventItem(
        eventId: uri,
        refDetails: referenceDetails,
      );
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
          ),
          subtitle: Text(
            uri,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall,
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

  Widget renderInvitationCodeActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails referenceDetails,
  ) {
    final lang = L10n.of(context);
    final title = referenceDetails.title();
    if (title == null) return SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Atlas.ticket_coupon),
        onTap: () async {
          try {
            final token =
                await ref.read(superInviteTokenProvider(title).future);
            if (!context.mounted) return;
            context.pushNamed(
              Routes.createSuperInvite.name,
              extra: token,
            );
          } catch (e) {
            await Clipboard.setData(ClipboardData(text: title));
            EasyLoading.showToast(lang.messageCopiedToClipboard);
          }
        },
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          L10n.of(context).inviteCode,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall,
        ),
      ),
    );
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
