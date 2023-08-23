import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class LinkSettingsPage extends StatefulWidget {
  final Convo room;

  const LinkSettingsPage({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<LinkSettingsPage> createState() => _LinkSettingsPageState();
}

class _LinkSettingsPageState extends State<LinkSettingsPage> {
  final timeArr = [
    '30 min',
    '1 Hour',
    '24 Hours',
    '7 days',
    'Never',
  ];

  final usesArr = [
    '∞',
    '1',
    '5',
    '50',
    '100',
    '200',
  ];

  List<int> selectedTimeIndexList = [];
  List<int> selectedUsesIndexList = [];

  int? timeIndexing;
  int? usesIndexing;

  Color? tagColor;
  String? displayName;

  @override
  void initState() {
    super.initState();

    final profile = widget.room.getProfile();
    profile.getDisplayName().then((value) {
      if (mounted) {
        String? name = value.text();
        if (name != null && mounted) {
          setState(() => displayName = name);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 10),
              child: const Text(
                'Room',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            _NameWidget(displayName: displayName),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              child: const Text(
                'Expires After',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 20,
                ),
                itemCount: timeArr.length,
                itemBuilder: (BuildContext content, index) {
                  return GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          timeIndexing = index;
                          selectedTimeIndexList.clear();
                          if (!selectedTimeIndexList.contains(index)) {
                            selectedTimeIndexList.add(index);
                          }
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          timeArr[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              child: const Text(
                'Max Uses',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 20,
              ),
              itemCount: usesArr.length,
              itemBuilder: (BuildContext content, index) {
                return GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        usesIndexing = index;
                        selectedUsesIndexList.clear();
                        if (!selectedUsesIndexList.contains(index)) {
                          selectedUsesIndexList.add(index);
                        }
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        usesArr[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NameWidget extends StatelessWidget {
  final String? displayName;

  const _NameWidget({
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    if (displayName == null) {
      return const Text('Loading Name');
    }
    return Text(
      '!${displayName!}',
      overflow: TextOverflow.clip,
    );
  }
}
