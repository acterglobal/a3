import 'package:acter/features/chat/widgets/invite_user_dialog.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class TaskAssignPage extends StatelessWidget {
  final _controller = TextEditingController();

  TaskAssignPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Atlas.xmark_circle),
        ),
        title: const Text('List Members'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Atlas.dots_horizontal),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 40,
                  margin: const EdgeInsets.only(top: 20, right: 16, left: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Atlas.magnifying_glass,
                            color: Colors.grey,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 42),
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.grey,
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Search User',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        'List Members',
                      ),
                      Container(
                        height: 5,
                        width: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Someone not in the list? Just Invite them',
                ),
                InkWell(
                  onTap: () {
                    showDialogBox(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.group,
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        Text(
                          'Invite Members',
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future showDialogBox(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return const InviteUserDialog();
      },
    );
  }
}
