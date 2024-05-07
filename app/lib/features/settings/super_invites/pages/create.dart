import 'package:acter/common/toolkit/buttons/danger_action_button.dart';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/chat_selector_drawer.dart';
import 'package:acter/common/widgets/checkbox_form_field.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/settings/super_invites/widgets/to_join_room.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateSuperInviteTokenPage extends ConsumerStatefulWidget {
  static Key tokenFieldKey = const Key('super-invites-create-token-token');
  static Key createDmKey = const Key('super-invites-create-token-create-dm');
  static Key addSpaceKey = const Key('super-invites-create-token-add-space');
  static Key addChatKey = const Key('super-invites-create-token-add-chat');
  static Key submitBtn = const Key('super-invites-create-submitBtn');
  static Key deleteBtn = const Key('super-invites-create-delete');
  static Key deleteConfirm = const Key('super-invites-create-delete-confirm');
  final SuperInviteToken? token;

  const CreateSuperInviteTokenPage({super.key, this.token});

  @override
  ConsumerState<CreateSuperInviteTokenPage> createState() =>
      _CreateSuperInviteTokenPageConsumerState();
}

class _CreateSuperInviteTokenPageConsumerState
    extends ConsumerState<CreateSuperInviteTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late SuperInvitesTokenUpdateBuilder tokenUpdater;
  bool isEdit = false;
  int _acceptedCount = 0;
  bool _initialDmCheck = false;
  List<String> _roomIds = [];

  @override
  void initState() {
    super.initState();
    final provider = ref.read(superInvitesProvider);
    if (widget.token != null) {
      // given an update builder we are in an edit mode

      isEdit = true;
      final token = widget.token!;
      _tokenController.text = token.token();
      _roomIds = token.rooms().map((e) => e.toDartString()).toList();
      _acceptedCount = token.acceptedCount();
      _initialDmCheck = token.createDm();
      tokenUpdater = token.updateBuilder();
    } else {
      tokenUpdater = provider.newTokenUpdater();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverScaffold(
      header: isEdit
          ? L10n.of(context).editInviteCode
          : L10n.of(context).createInviteCode,
      addActions: true,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 15),
              isEdit
                  ? ListTile(
                      title: Text(_tokenController.text),
                      subtitle: Text(
                        L10n.of(context).claimedTimes(_acceptedCount),
                      ),
                      trailing: IconButton(
                        key: CreateSuperInviteTokenPage.deleteBtn,
                        icon: const Icon(Atlas.trash_can_thin),
                        onPressed: () => _deleteIt(context),
                      ),
                    )
                  : InputTextField(
                      hintText: L10n.of(context).code,
                      key: CreateSuperInviteTokenPage.tokenFieldKey,
                      textInputType: TextInputType.text,
                      controller: _tokenController,
                      validator: (String? val) => (val?.isNotEmpty == true &&
                              val!.length < 6)
                          ? L10n.of(context).codeMustBeAtLeast6CharactersLong
                          : null,
                    ),
              CheckboxFormField(
                key: CreateSuperInviteTokenPage.createDmKey,
                title: Text(L10n.of(context).createDMWhenRedeeming),
                onChanged: (newValue) =>
                    setState(() => tokenUpdater.createDm(newValue ?? false)),
                initialValue: _initialDmCheck,
              ),
              Text(L10n.of(context).spacesAndChatsToAddThemTo),
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
                            title: Text(L10n.of(context).addSpace),
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
                        child: Text(L10n.of(context).addSpace),
                      ),
                      OutlinedButton(
                        key: CreateSuperInviteTokenPage.addChatKey,
                        onPressed: () async {
                          final newSpace = await selectChatDrawer(
                            context: context,
                            currentChatId: null,
                            canCheck: 'CanInvite',
                            title: Text(L10n.of(context).addChat),
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
                        child: Text(L10n.of(context).addChat),
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
                tokenUpdater.removeRoom(roomId);
                setState(
                  () => _roomIds = List.from(_roomIds)..remove(roomId),
                );
              },
            );
          },
          itemCount: _roomIds.length,
        ),
      ],
      confirmActionTitle:
          isEdit ? L10n.of(context).save : L10n.of(context).createCode,
      confirmActionKey: CreateSuperInviteTokenPage.submitBtn,
      confirmActionOnPressed: _submit,
      cancelActionTitle: L10n.of(context).cancel,
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  Future<void> _submit() async {
    final status =
        isEdit ? L10n.of(context).savingCode : L10n.of(context).creatingCode;
    EasyLoading.show(status: status);
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
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // pop the create sheet
    } catch (err) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      final status = isEdit
          ? L10n.of(context).saveInviteCodeFailed(err)
          : L10n.of(context).createInviteCodeFailed(err);
      EasyLoading.showError(status, duration: const Duration(seconds: 3));
    }
  }

  Future<void> _deleteIt(BuildContext context) async {
    final bool? confirm = await showAdaptiveDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(L10n.of(context).deleteCode),
          content: Text(
            L10n.of(context).doYouWantToDeleteInviteCode,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
                onPressed: () => ctx.pop(),
                child: Text(
                  L10n.of(context).no,
                ),),
            ActerDangerActionButton(
              key: CreateSuperInviteTokenPage.deleteConfirm,
              onPressed: () async {
                ctx.pop(true);
              },
              child: Text(
                L10n.of(context).delete,
              ),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) {
      return;
    }

    EasyLoading.show(status: L10n.of(context).deletingCode);
    try {
      final tokenTxt = _tokenController.text;
      // all other changes happen on the object itself;
      final provider = ref.read(superInvitesProvider);
      await provider.delete(tokenTxt);
      ref.invalidate(superInvitesTokensProvider);
      EasyLoading.dismiss();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // pop the create sheet
    } catch (err) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).deleteInviteCodeFailed(err),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
