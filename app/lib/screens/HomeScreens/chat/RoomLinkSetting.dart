import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class RoomLinkSettingsScreen extends StatefulWidget {
  final Conversation room;

  const RoomLinkSettingsScreen({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  _RoomLinkSettingsScreenState createState() => _RoomLinkSettingsScreenState();
}

class _RoomLinkSettingsScreenState extends State<RoomLinkSettingsScreen> {
  var timeArr = [
    '30 min',
    '1 Hour',
    '24 Hours',
    '7 days',
    'Never',
  ];

  var usesArr = [
    '∞',
    '1',
    '5',
    '50',
    '100',
    '200',
  ];

  List<int> selectedTimeIndexList = [];
  List<int> selectedUsesIndexList = [];

  var isTimeSelected = false;
  int? timeIndexing;
  int? usesIndexing;

  Color? tagColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Settings'),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: AppCommonTheme.backgroundColor,
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
            FutureBuilder<String>(
              future: widget.room.displayName(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '@' + snapshot.requireData,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      color: AppCommonTheme.primaryColor,
                      fontSize: 16,
                    ),
                  );
                } else {
                  return const Text('Loading Name');
                }
              },
            ),
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
                      setState(() {
                        timeIndexing = index;
                        if (!selectedTimeIndexList.contains(index)) {
                          selectedTimeIndexList.clear();
                          selectedTimeIndexList.add(index);
                        } else {
                          selectedTimeIndexList.clear();
                        }
                      });
                    },
                    child: Container(
                      child: Center(
                        child: Text(
                          timeArr[index],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: selectedTimeIndexList.contains(index)
                            ? AppCommonTheme.primaryColor
                            : AppCommonTheme.darkShade,
                        borderRadius: BorderRadius.circular(15),
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
                    setState(() {
                      usesIndexing = index;
                      if (!selectedUsesIndexList.contains(index)) {
                        selectedUsesIndexList.clear();
                        selectedUsesIndexList.add(index);
                      } else {
                        selectedUsesIndexList.clear();
                      }
                    });
                  },
                  child: Container(
                    child: Center(
                      child: Text(
                        usesArr[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: selectedUsesIndexList.contains(index)
                          ? AppCommonTheme.primaryColor
                          : AppCommonTheme.darkShade,
                      borderRadius: BorderRadius.circular(15),
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
