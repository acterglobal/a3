import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/convo_list.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// interface providers
final _searchToggleProvider = StateProvider.autoDispose<bool>((ref) => false);

class ChatPage extends ConsumerWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final showSearch = ref.watch(_searchToggleProvider);
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              pinned: false,
              snap: false,
              floating: true,
              flexibleSpace: showSearch
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: 5,
                        bottom: 6,
                        left: 10,
                        right: 5,
                      ),
                      child: TextFormField(
                        autofocus: true,
                        onChanged: (value) => ref
                            .read(chatListProvider.notifier)
                            .searchRoom(value),
                        cursorColor: Theme.of(context).colorScheme.tertiary2,
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(color: Colors.white),
                          suffixIcon: GestureDetector(
                            onTap: () => ref
                                .read(_searchToggleProvider.notifier)
                                .update((state) => !state),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 12,
                            bottom: 2,
                            top: 2,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        AppLocalizations.of(context)!.chat,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
              actions: showSearch
                  ? []
                  : [
                      IconButton(
                        onPressed: () => ref
                            .read(_searchToggleProvider.notifier)
                            .update((state) => !state),
                        padding: const EdgeInsets.only(right: 10, left: 5),
                        icon: const Icon(Atlas.magnifying_glass),
                      ),
                      IconButton(
                        onPressed: () {
                          customMsgSnackbar(
                            context,
                            'Multiselect is not implemented yet',
                          );
                        },
                        padding: const EdgeInsets.only(right: 10, left: 5),
                        icon: const Icon(Atlas.menu_square),
                      ),
                      IconButton(
                        onPressed: () =>
                            context.pushNamed(Routes.createChat.name),
                        padding: const EdgeInsets.only(right: 10, left: 10),
                        icon: const Icon(
                          Atlas.plus_circle_thin,
                        ),
                      ),
                    ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (client.isGuest()) empty else const ConvosList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SvgPicture get empty {
    return SvgPicture.asset('assets/images/empty_messages.svg');
  }
}
