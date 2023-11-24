import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/chat_selector_drawer.dart';
import 'package:acter/common/widgets/checkbox_form_field.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/settings/super_invites/widgets/to_join_room.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateSuperInviteTokenPage extends ConsumerStatefulWidget {
  static Key tokenFieldKey = const Key('super-invites-create-token-token');
  static Key createDmKey = const Key('super-invites-create-token-create-dm');
  static Key addSpaceKey = const Key('super-invites-create-token-add-space');
  static Key addChatKey = const Key('super-invites-create-token-add-chat');
  static Key submitBtn = const Key('super-invites-create-submitBtn');
  final SuperInvitesTokenUpdateBuilder? tokenUpdater;
  const CreateSuperInviteTokenPage({super.key, this.tokenUpdater});

  @override
  ConsumerState<CreateSuperInviteTokenPage> createState() =>
      _CreateSuperInviteTokenPageConsumerState();
}

class _CreateSuperInviteTokenPageConsumerState
    extends ConsumerState<CreateSuperInviteTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late SuperInvitesTokenUpdateBuilder tokenUpdater;
  List<String> _roomIds = [];

  @override
  void initState() {
    super.initState();
    final provider = ref.read(superInvitesProvider);
    tokenUpdater = widget.tokenUpdater ?? provider.newTokenUpdater();
    // WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
    //   final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
    //   parentNotifier.state = widget.initialParentsSpaceId;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return SideSheet(
      header: 'Create Invite Token',
      addActions: true,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 15),
              InputTextField(
                hintText: 'Token',
                key: CreateSuperInviteTokenPage.tokenFieldKey,
                textInputType: TextInputType.text,
                controller: _tokenController,
                validator: (String? val) =>
                    (val != null && val.isNotEmpty && val.length < 6)
                        ? 'Token must be at least 6 characters long'
                        : null,
              ),
              CheckboxFormField(
                key: CreateSuperInviteTokenPage.createDmKey,
                title: const Text('Create DM when redeeming'),
                onChanged: (newValue) =>
                    setState(() => tokenUpdater.createDm(newValue ?? false)),
                initialValue: false,
              ),
              const Text('Spaces & Chats to add them to'),
              Card(
                child: ListTile(
                  title: ButtonBar(
                    children: [
                      OutlinedButton(
                        key: CreateSuperInviteTokenPage.addSpaceKey,
                        onPressed: () async {
                          final newSpace = await selectSpaceDrawer(
                            context: context,
                            currentSpaceId: null,
                            canCheck: 'CanInvite',
                            title: const Text('Add Space'),
                          );
                          if (newSpace != null) {
                            if (!_roomIds.contains(newSpace)) {
                              tokenUpdater.addRoom(newSpace);
                              setState(
                                () => _roomIds = List.from(_roomIds)
                                  ..add(newSpace),
                              );
                            }
                          }
                        },
                        child: const Text('Add Space'),
                      ),
                      OutlinedButton(
                        key: CreateSuperInviteTokenPage.addChatKey,
                        onPressed: () async {
                          final newSpace = await selectChatDrawer(
                            context: context,
                            currentChatId: null,
                            canCheck: 'CanInvite',
                            title: const Text('Add Chat'),
                          );
                          if (newSpace != null) {
                            if (!_roomIds.contains(newSpace)) {
                              tokenUpdater.addRoom(newSpace);
                              setState(
                                () => _roomIds = List.from(_roomIds)
                                  ..add(newSpace),
                              );
                            }
                          }
                        },
                        child: const Text('Add Chat'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      delegates: [
        ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, idx) {
            final roomId = _roomIds[idx];
            return RoomToInviteTo(
              roomId: roomId,
              onRemove: () {
                setState(
                  () => _roomIds = List.from(_roomIds)..remove(roomId),
                );
              },
            );
          },
          itemCount: _roomIds.length,
        ),
      ],
      confirmActionTitle: 'Create Token',
      confirmActionKey: CreateSuperInviteTokenPage.submitBtn,
      confirmActionOnPressed: _submit,
      cancelActionTitle: 'Cancel',
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  Future<void> _submit() async {
    EasyLoading.show(status: 'Creating Token');
    try {
      final tokenTxt = _tokenController.text;
      if (tokenTxt.isNotEmpty) {
        tokenUpdater.token(tokenTxt);
      }
      // all other changes happen on the object itself;
      final provider = ref.read(superInvitesProvider);
      await provider.createOrUpdateToken(tokenUpdater);
      ref.invalidate(superInvitesTokensProvider);
      EasyLoading.dismiss();
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop(); // pop the create sheet
    } catch (err) {
      EasyLoading.showError(
        'Creating token failed $err',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
