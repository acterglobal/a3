import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/chat_selector_drawer.dart';
import 'package:acter/common/widgets/checkbox_form_field.dart';
import 'package:acter/common/widgets/info_widget.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CreateSuperInvitePage extends ConsumerStatefulWidget {
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
  late TabController tabController;
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
    tabController = TabController(length: 2, vsync: this);
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final token = widget.token;
    if (token != null) {
      // given an update builder we are in an edit mode
      isEdit = true;
      _tokenController.text = token.token();
      _roomIds = asDartStringList(token.rooms());
      _acceptedCount = token.acceptedCount();
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
      appBar: AppBar(
        title: Text('Create'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(key: _formKey, child: tokenInputUI(lang)),
            SizedBox(height: 22),
            InfoWidget(
              title: 'Select Spaces and Chats',
              subTitle:
                  'While redeeming code, selected spaces and chats are auto joined',
            ),
            SizedBox(height: 12),
            Expanded(child: selectedRoomsSections()),
            createDmCheckBoxUI(lang),
            SizedBox(height: 12),
            ActerPrimaryActionButton(
              onPressed: () {},
              child: Text(isEdit ? lang.save : lang.createCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget tokenInputUI(L10n lang) {
    return TextFormField(
      onSaved: (value) {},
      decoration: InputDecoration(
        hintText: 'Invite code',
        suffixIcon: IconButton(
          onPressed: () {},
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.generating_tokens),
              SizedBox(width: 6),
              Text('Auto'),
              SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget selectedRoomsSections() {
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

    final tabPadding = const EdgeInsets.all(8.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TabBar(
                controller: tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
                dividerColor: Colors.transparent,
                tabs: [
                  Padding(padding: tabPadding, child: Text('Spaces')),
                  Padding(padding: tabPadding, child: Text('Chats')),
                ],
              ),
            ),
            addRoomButtonUI()
          ],
        ),
        Expanded(
          child: TabBarView(controller: tabController, children: [
            roomListView(spaces),
            roomListView(chats),
          ]),
        ),
      ],
    );
  }

  Widget addRoomButtonUI() {
    final lang = L10n.of(context);
    return IconButton(
      onPressed: () async {
        String? selectedRoomId;
        if (tabController.index == 0) {
          selectedRoomId = await selectSpaceDrawer(
            context: context,
            currentSpaceId: null,
            canCheck: 'CanInvite',
            title: Text(lang.addSpace),
          );
        } else if (tabController.index == 1) {
          selectedRoomId = await selectChatDrawer(
            context: context,
            currentChatId: null,
            canCheck: 'CanInvite',
            title: Text(lang.addChat),
          );
        }
        if (selectedRoomId != null) {
          if (!_roomIds.contains(selectedRoomId)) {
            tokenUpdater.addRoom(selectedRoomId);
            setState(() => _roomIds.add(selectedRoomId!));
          }
        }
      },
      icon: const Icon(Atlas.plus_circle_thin),
    );
  }

  Widget roomListView(List<String> rooms) {
    return ListView.builder(
      itemBuilder: (context, idx) {
        final roomId = rooms[idx];
        return RoomCard(
          roomId: roomId,
          trailing: InkWell(
            onTap: () {
              tokenUpdater.removeRoom(roomId);
              setState(() => _roomIds.remove(roomId));
            },
            child: Icon(Atlas.trash_can_thin),
          ),
        );
      },
      itemCount: rooms.length,
    );
  }

  Widget createDmCheckBoxUI(L10n lang) {
    return CheckboxFormField(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text('Create DM'),
          Text(
            'While redeeming code, DM will be created',
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
}
