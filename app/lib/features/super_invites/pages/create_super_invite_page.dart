import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/chat_selector_drawer.dart';
import 'package:acter/common/widgets/checkbox_form_field.dart';
import 'package:acter/common/widgets/info_widget.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/invite_list_item.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::super_invites::create');

class CreateSuperInvitePage extends ConsumerStatefulWidget {
  static Key tokenFieldKey = const Key('super-invites-create-token-token');
  static Key createDmKey = const Key('super-invites-create-token-create-dm');
  static Key addSpaceKey = const Key('super-invites-create-token-add-space');
  static Key addSubmenu = const Key('super-invites-create-token-add-submenu');
  static Key addChatKey = const Key('super-invites-create-token-add-chat');
  static Key submitBtn = const Key('super-invites-create-submitBtn');
  static Key deleteBtn = const Key('super-invites-create-delete');
  static Key deleteConfirm = const Key('super-invites-create-delete-confirm');

  final SuperInviteToken? token;

  const CreateSuperInvitePage({
    super.key,
    this.token,
  });

  @override
  ConsumerState<CreateSuperInvitePage> createState() =>
      _CreateSuperInvitePageState();
}

class _CreateSuperInvitePageState extends ConsumerState<CreateSuperInvitePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late SuperInvitesTokenUpdateBuilder tokenUpdater;
  bool isEdit = false;
  bool _initialDmCheck = false;
  List<String> _roomIds = [];

  @override
  void initState() {
    super.initState();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final token = widget.token;
    if (token != null) {
      // given an update builder we are in an edit mode
      isEdit = true;
      _tokenController.text = token.token();
      _roomIds = asDartStringList(token.rooms());
      _initialDmCheck = token.createDm();
      tokenUpdater = token.updateBuilder();
    } else {
      final superInvites = await ref.read(superInvitesProvider.future);
      tokenUpdater = superInvites.newTokenUpdater();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: _buildAppBarView(lang),
      body: _buildBodyView(lang),
    );
  }

  AppBar _buildAppBarView(L10n lang) {
    return AppBar(
      title: Text(
        isEdit ? lang.editInviteCode : lang.createInviteCode,
      ),
    );
  }

  Widget _buildBodyView(L10n lang) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isEdit && widget.token != null
                ? InviteListItem(
                    inviteToken: widget.token!,
                    cardMargin:
                        EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                  )
                : Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _tokenController,
                      decoration: InputDecoration(hintText: lang.inviteCode),
                    ),
                  ),
            if (!isEdit) ...[
              SizedBox(height: 22),
              InfoWidget(
                title: lang.selectSpacesAndChats,
                subTitle: lang.autoJoinSpacesAndChatsInfo,
              ),
              SizedBox(height: 12),
            ],
            selectRoomsSections(lang),
            SizedBox(height: 12),
            createDmCheckBoxUI(lang),
            SizedBox(height: 32),
            createInvite(lang),
          ],
        ),
      ),
    );
  }

  Widget selectRoomsSections(L10n lang) {
    final spaces = List<String>.empty(growable: true);
    final chats = List<String>.empty(growable: true);
    for (final roomId in _roomIds) {
      final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
      if (room?.isSpace() == true) {
        spaces.add(roomId);
      } else {
        chats.add(roomId);
      }
    }

    return Column(
      children: [
        roomSection(
          title: lang.spaces,
          rooms: spaces,
          onTapAdd: () async {
            final selectedSpaceId = await selectSpaceDrawer(
              context: context,
              currentSpaceId: null,
              canCheck: 'CanInvite',
              title: Text(lang.addSpace),
            );
            if (selectedSpaceId != null) {
              if (!_roomIds.contains(selectedSpaceId)) {
                tokenUpdater.addRoom(selectedSpaceId);
                setState(() => _roomIds.add(selectedSpaceId));
              }
            }
          },
        ),
        roomSection(
          title: lang.chats,
          rooms: chats,
          onTapAdd: () async {
            final selectedChatId = await selectChatDrawer(
              context: context,
              currentChatId: null,
              canCheck: 'CanInvite',
              title: Text(lang.addChat),
            );
            if (selectedChatId != null) {
              if (!_roomIds.contains(selectedChatId)) {
                tokenUpdater.addRoom(selectedChatId);
                setState(() => _roomIds.add(selectedChatId));
              }
            }
          },
        ),
      ],
    );
  }

  Widget roomSection({
    required String title,
    required List<String> rooms,
    required VoidCallback onTapAdd,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(title: title)),
            IconButton(
              onPressed: onTapAdd,
              icon: const Icon(Atlas.plus_circle_thin),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, idx) {
            final roomId = rooms[idx];
            return RoomCard(
              roomId: roomId,
              onTap: () async {
                final room = await ref.read(maybeRoomProvider(roomId).future);
                if (!context.mounted) return;
                if (room?.isSpace() == true) {
                  goToSpace(context, roomId);
                } else {
                  goToChat(context, roomId);
                }
              },
              trailing: InkWell(
                onTap: () {
                  tokenUpdater.removeRoom(roomId);
                  setState(() => _roomIds.remove(roomId));
                },
                child: Icon(
                  PhosphorIcons.trash(),
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          },
          itemCount: rooms.length,
        ),
      ],
    );
  }

  Widget createDmCheckBoxUI(L10n lang) {
    return CheckboxFormField(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(lang.createDM),
          Text(
            lang.autoDMWhileRedeemCode,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
      onChanged: (isCreateDM) {
        setState(() => tokenUpdater.createDm(isCreateDM ?? false));
      },
      initialValue: _initialDmCheck,
    );
  }

  Widget createInvite(L10n lang) {
    return ActerPrimaryActionButton(
      onPressed: _submit,
      child: Text(isEdit ? lang.save : lang.createCode),
    );
  }

  Future<void> _submit() async {
    final lang = L10n.of(context);
    if (!_formKey.currentState!.validate()) return;
    final status = isEdit ? lang.savingCode : lang.creatingCode;
    EasyLoading.show(status: status);
    try {
      final tokenTxt = _tokenController.text;
      if (tokenTxt.isNotEmpty) {
        tokenUpdater.token(tokenTxt);
      } else if (_roomIds.isNotEmpty) {
        final displayName =
            await ref.read(roomDisplayNameProvider(_roomIds[0]).future);
        final inviteCode = generateInviteCodeName(displayName);
        tokenUpdater.token(inviteCode);
      }
      // all other changes happen on the object itself;
      final superInvites = await ref.read(superInvitesProvider.future);
      await superInvites.createOrUpdateToken(tokenUpdater);
      ref.invalidate(superInvitesTokensProvider);
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context); // pop the create sheet
    } catch (e, s) {
      if (isEdit) {
        _log.severe('Failed to change the invitation code', e, s);
      } else {
        _log.severe('Failed to create the invitation code', e, s);
      }
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      final status = isEdit
          ? lang.saveInviteCodeFailed(e)
          : lang.createInviteCodeFailed(e);
      EasyLoading.showError(
        status,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
