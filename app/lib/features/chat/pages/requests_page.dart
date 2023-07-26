import 'package:acter/features/chat/widgets/pending_req_list_view.dart';
import 'package:acter/features/chat/widgets/req_list_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class RequestsPage extends StatefulWidget {
  final Client client;
  final Convo room;

  const RequestsPage({
    Key? key,
    required this.client,
    required this.room,
  }) : super(key: key);

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<UserProfile> userProfiles = [];

  @override
  void initState() {
    super.initState();

    RoomId roomId = widget.room.getRoomId();
    widget.client.suggestedUsersToInvite(roomId.toString()).then((value) {
      if (mounted) {
        if (mounted) {
          setState(() => userProfiles = value.toList());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const AppBarTheme().backgroundColor,
        elevation: 0.0,
        title: const Text('Request & Invites'),
        centerTitle: true,
      ),
      body: _TabBarWidget(
        userProfiles: userProfiles,
        reqLength: 5,
        pendingLength: 3,
      ),
    );
  }
}

class _TabBarWidget extends StatefulWidget {
  final List<UserProfile> userProfiles;
  final int reqLength;
  final int pendingLength;

  const _TabBarWidget({
    required this.userProfiles,
    required this.reqLength,
    required this.pendingLength,
  });

  @override
  State<_TabBarWidget> createState() => _TabBarWidgetState();
}

class _UserItem {
  String userId;
  String? displayName;
  Future<OptionBuffer> avatar;

  _UserItem({
    required this.userId,
    required this.displayName,
    required this.avatar,
  });
}

class _TabBarWidgetState extends State<_TabBarWidget> {
  List<_UserItem> userItems = [];

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  void loadProfiles() async {
    List<_UserItem> items = [];
    for (var profile in widget.userProfiles) {
      OptionText displayName = await profile.getDisplayName();
      var item = _UserItem(
        userId: profile.userId().toString(),
        displayName: displayName.text(),
        avatar: profile.getAvatar(),
      );
      items.add(item);
    }
    if (mounted) {
      setState(() => userItems = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              labelColor: Colors.white, //<-- selected text color
              unselectedLabelColor: Colors.white,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // Creates border
              ),
              indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
              tabs: const [
                Tab(text: 'Invites'),
                Tab(text: 'Requests'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    Visibility(
                      visible: userItems.isNotEmpty,
                      child: ListView.builder(
                        itemCount: userItems.length,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          var item = userItems[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: PendingReqListView(
                              userId: item.userId,
                              avatar: item.avatar,
                              displayName: item.displayName,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: Visibility(
                        visible: (widget.pendingLength == 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.asset('assets/images/no_req.png'),
                              ),
                            ),
                            const Text(
                              'No Invite Yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'People on this list are attempting to join via the group link.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Column(
                  children: [
                    Visibility(
                      visible: (widget.reqLength > 0),
                      child: ListView.builder(
                        itemCount: widget.reqLength,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: ReqListView(name: 'Ben'),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: Visibility(
                        visible: (widget.reqLength == 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.asset('assets/images/no_req.png'),
                              ),
                            ),
                            const Text(
                              'No Requests Yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'People on this list are attempting to join via the group link.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
