import 'package:acter/common/dialogs/invite_to_room_dialog.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_bottom_sheet.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _selectedUsersProvider =
    StateProvider.autoDispose<List<ffi.UserProfile>>((ref) => []);

class CreateChatWidget extends ConsumerStatefulWidget {
  const CreateChatWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateChatWidgetState();
}

class _CreateChatWidgetState extends ConsumerState<CreateChatWidget> {
  @override
  Widget build(BuildContext context) {
    final selectedUsers = ref.watch(_selectedUsersProvider);
    final size = MediaQuery.of(context).size;
    return size.width > 600
        ? DefaultDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Text(
                  'New Chat',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Visibility(
                  visible: selectedUsers.isNotEmpty,
                  replacement: IconButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    icon: const Icon(Atlas.xmark_circle_thin),
                  ),
                  child: TextButton(
                    onPressed: () => {},
                    child: Text(
                      'Next',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.success,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            width: size.width * 0.5,
            height: size.height,
            minHeight: size.height * 0.5,
            description: const _ContentWidget(),
          )
        : DefaultBottomSheet(
            header: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                Text(
                  'New Chat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Visibility(
                  visible: selectedUsers.isNotEmpty,
                  replacement: const SizedBox.shrink(),
                  child: TextButton(
                    onPressed: () => {},
                    child: Text(
                      'Next',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.success,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            content: const _ContentWidget(),
            sheetHeight: size.height,
          );
  }
}

class _ContentWidget extends ConsumerWidget {
  const _ContentWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUsers = ref.watch(_selectedUsersProvider).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: ref.watch(searchController),
          style: Theme.of(context).textTheme.labelMedium,
          decoration: InputDecoration(
            isCollapsed: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.secondaryContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Search Username',
            hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
            contentPadding: const EdgeInsets.all(18),
            hintMaxLines: 1,
          ),
          onChanged: (String val) =>
              ref.read(searchValueProvider.notifier).update((state) => val),
        ),
        const SizedBox(height: 15),
        Visibility(
          visible: selectedUsers.isNotEmpty,
          replacement: const SizedBox.shrink(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 5.0,
              runSpacing: 5.0,
              children: List.generate(
                selectedUsers.length,
                (index) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final avatarProv =
                          ref.watch(userAvatarProvider(selectedUsers[index]));
                      final displayName =
                          ref.watch(displayNameProvider(selectedUsers[index]));
                      final userId = selectedUsers[index].userId().toString();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ActerAvatar(
                            uniqueId: userId,
                            mode: DisplayMode.User,
                            displayName: displayName.valueOrNull ?? userId,
                            avatar: avatarProv.valueOrNull,
                            size: avatarProv.valueOrNull != null ? 14 : 28,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            displayName.valueOrNull ?? userId,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => ref
                                .read(_selectedUsersProvider.notifier)
                                .update(
                                  (state) => [
                                    for (int j = 0; j < state.length; j++)
                                      if (j != index) state[j],
                                  ],
                                ),
                            child: Icon(
                              Icons.close_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        ListTile(
          onTap: () {
            Navigator.of(context).pop();
            context.pushNamed(Routes.createChat.name);
          },
          contentPadding: const EdgeInsets.only(left: 0),
          leading: ActerAvatar(
            uniqueId: '#',
            mode: DisplayMode.Space,
            size: 48,
          ),
          title: Text(
            'Create Group Chat',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: const Icon(Icons.chevron_right_outlined, size: 24),
        ),
        const SizedBox(height: 15),
        Text('Suggestions', style: Theme.of(context).textTheme.bodyMedium),
        Consumer(
          builder: (context, ref, child) {
            final foundUsers = ref.watch(searchResultProvider);
            return foundUsers.when(
              data: (data) => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (context, index) =>
                    _UserWidget(profile: data[index]),
              ),
              error: (e, st) => Text('Error loading users $e'),
              loading: () => const Center(
                heightFactor: 5,
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UserWidget extends ConsumerWidget {
  final ffi.UserProfile profile;
  const _UserWidget({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarProv = ref.watch(userAvatarProvider(profile));
    final displayName = ref.watch(displayNameProvider(profile));
    final userId = profile.userId().toString();
    return ListTile(
      onTap: () {
        final users = ref.read(_selectedUsersProvider);
        if (!users.contains(profile)) {
          ref
              .read(_selectedUsersProvider.notifier)
              .update((state) => [...state, profile]);
        }
      },
      title: displayName.when(
        data: (data) => Text(
          data ?? userId,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        error: (err, stackTrace) => Text('Error: $err'),
        loading: () => const Text('Loading display name'),
      ),
      subtitle: displayName.when(
        data: (data) {
          return (data == null)
              ? null
              : Text(
                  userId,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                );
        },
        error: (err, stackTrace) => Text('Error: $err'),
        loading: () => const Text('Loading display name'),
      ),
      leading: ActerAvatar(
        uniqueId: userId,
        mode: DisplayMode.User,
        uniqueName: displayName.valueOrNull,
        displayName: displayName.valueOrNull,
        avatar: avatarProv.valueOrNull,
        size: avatarProv.valueOrNull != null ? 18 : 36,
      ),
    );
  }
}
