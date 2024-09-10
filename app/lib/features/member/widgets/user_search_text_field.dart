import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSearchTextField extends ConsumerStatefulWidget {
  final String hintText;
  const UserSearchTextField({super.key, required this.hintText});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SearchUserFieldTextState();
}

class _SearchUserFieldTextState extends ConsumerState<UserSearchTextField> {
  final searchTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchTextCtrl.text = ref.read(userSearchValueProvider) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: searchTextCtrl,
        decoration: InputDecoration(
          prefixIcon: const Icon(Atlas.magnifying_glass_thin),
          hintText: widget.hintText,
          suffix: ref.watch(userSearchValueProvider)?.isNotEmpty == true
              ? InkWell(
                  onTap: () {
                    ref.read(userSearchValueProvider.notifier).state = null;
                    searchTextCtrl.clear();
                  },
                  child: const Icon(
                    Atlas.xmark_circle_thin,
                  ),
                )
              : null,
        ),
        onChanged: (String value) {
          ref.read(userSearchValueProvider.notifier).update((state) => value);
        },
      ),
    );
  }
}
