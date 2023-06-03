import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Member;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceItem extends ConsumerWidget {
  final String? title;
  final List<Member> members;
  final MemoryImage? avatar;
  final Function()? callback;

  const SpaceItem({
    super.key,
    this.title,
    required this.members,
    this.avatar,
    this.callback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    return InkWell(
      onTap: callback,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: ActerAvatar(
                  mode: DisplayMode.Space,
                  uniqueId: client.userId().toString(),
                  size: 36,
                  avatar: avatar,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title ?? '', style: const TextStyle(fontSize: 15)),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${members.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const WidgetSpan(
                            child: SizedBox(width: 4),
                          ),
                          const TextSpan(
                            text: 'Members',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
