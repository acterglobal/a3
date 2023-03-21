import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditGroupInfoScreen extends StatefulWidget {
  final Conversation room;
  final String name;
  final String description;

  const EditGroupInfoScreen({
    Key? key,
    required this.room,
    required this.name,
    required this.description,
  }) : super(key: key);

  @override
  _EditGroupInfoState createState() => _EditGroupInfoState();
}

class _EditGroupInfoState extends State<EditGroupInfoScreen> {
  Future<FfiBufferUint8>? avatar;
  String? displayName;
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  ChatRoomController chatController = Get.find<ChatRoomController>();

  @override
  void initState() {
    super.initState();

    nameController.text = widget.name;
    descController.text = widget.description;
    widget.room.getProfile().then((value) {
      if (mounted) {
        setState(() {
          if (value.hasAvatar()) {
            avatar = value.getAvatar();
          }
          displayName = value.getDisplayName();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                chatController.handleImageSelection(context);
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 38, bottom: 12),
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CustomAvatar(
                        uniqueKey: widget.room.getRoomId(),
                        avatar: avatar,
                        displayName: displayName,
                        radius: 20,
                        isGroup: true,
                        stringName: simplifyRoomId(widget.room.getRoomId())!,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              child: const Text(
                'Group Name',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SingleChildScrollView(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                controller: nameController,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.all(12),
                  filled: true,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              child: const Text(
                'Group Description',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Flexible(
              child: TextField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                controller: descController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  isCollapsed: false,
                  filled: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
