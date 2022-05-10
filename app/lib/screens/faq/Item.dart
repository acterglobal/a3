// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/FaqListItem.dart';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FaqItemScreen extends StatefulWidget {
  const FaqItemScreen({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  _FaItemqScreenState createState() => _FaItemqScreenState();
}

class _FaItemqScreenState extends State<FaqItemScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.faq.title()),
        ),
        body: Center(child: Text(widget.faq.body())));
  }
}
