import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

class PendingReqListView extends StatelessWidget {
  final String name;

  const PendingReqListView({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          const Text(
            'Withdraw',
            style: TextStyle(color: AppCommonTheme.primaryColor, fontSize: 16),
          )
        ],
      ),
    );
  }
}
