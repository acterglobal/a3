// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';

class ReqListView extends StatefulWidget {
  const ReqListView({
    Key? key,
    required this.name,
  }) : super(key: key);

  final String name;

  @override
  ReqListViewState createState() => ReqListViewState();
}

class ReqListViewState extends State<ReqListView> {
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                          color: AppCommonTheme.greenButtonColor,
                          fontSize: 16.0),
                    ),
                  ),
                  Text(
                    'Decline',
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
