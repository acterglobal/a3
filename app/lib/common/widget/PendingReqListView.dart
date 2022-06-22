// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';

class PendingReqListView extends StatefulWidget {
  const PendingReqListView({
    Key? key,
    required this.name,
  }) : super(key: key);

  final String name;

  @override
  PendingReqListViewState createState() => PendingReqListViewState();
}

class PendingReqListViewState extends State<PendingReqListView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  widget.name,
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Row(
                children: const [
                  Text(
                    'Withdraw',
                    style: TextStyle(
                        color: AppCommonTheme.primaryColor, fontSize: 16.0),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
