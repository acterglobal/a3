import 'dart:core';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/common/widgets/spaces/has_space_permission.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:go_router/go_router.dart';

class PinPage extends ConsumerWidget {
  final String pinId;
  const PinPage({
    super.key,
    required this.pinId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final pin = ref.watch(pinProvider(pinId));
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: pin.hasValue ? pin.value!.title() : 'Loading pin',
            sectionColor: Colors.blue.shade200,
            actions: pin.hasValue
                ? [
                    HasSpacePermission(
                      spaceId: pin.value!.roomIdStr(),
                      permission: 'CanPostPin',
                      child: IconButton(
                        icon: const Icon(Atlas.pencil_edit_thin),
                        onPressed: () => context.pushNamed(
                          Routes.editPin.name,
                          pathParameters: {'pinId': pin.value!.eventIdStr()},
                        ),
                      ),
                    ),
                  ]
                : [],
          ),
          pin.when(
            data: (pin) {
              final isLink = pin.isLink();
              final spaceId = pin.roomIdStr();
              final List<Widget> content = [];
              if (isLink) {
                content.add(
                  OutlinedButton.icon(
                    icon: const Icon(Atlas.link_chain_thin),
                    label: Text(pin.url() ?? ''),
                    onPressed: () async {
                      final target = pin.url()!;
                      await openLink(target, context);
                    },
                  ),
                );
              }
              if (pin.hasFormattedText()) {
                content.add(RenderHtml(text: pin.contentFormatted() ?? ''));
              } else {
                final text = pin.contentText();
                if (text != null) {
                  content.add(Text(text));
                }
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          key: Key(
                            pin.eventIdStr(),
                          ), // FIXME: causes crashes in ffigen
                          leading: Icon(
                            isLink
                                ? Atlas.link_chain_thin
                                : Atlas.document_thin,
                          ),
                          title: Text(pin.title()),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              children: [SpaceChip(spaceId: spaceId)],
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => showAdaptiveDialog(
                              context: context,
                              builder: (ctx) => ReportContentWidget(
                                title: 'Report this Pin',
                                description:
                                    'Report this content to your homeserver administrator. Please note that your adminstrator won\'t be able to read or view files, if space is encrypted',
                                eventId: pinId,
                                roomId: pin.roomIdStr(),
                                senderId: pin.sender().toString(),
                                isSpace: true,
                              ),
                            ),
                            icon: Icon(
                              Atlas.warning_thin,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(children: content),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: Center(
                child: Text('Loading failed: $error'),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
