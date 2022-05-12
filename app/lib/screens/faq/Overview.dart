// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/FaqListItem.dart';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class FaqOverviewScreen extends StatefulWidget {
  const FaqOverviewScreen({Key? key, required this.client}) : super(key: key);
  final Client client;

  @override
  _FaOverviewqScreenState createState() => _FaOverviewqScreenState();
}

class _FaOverviewqScreenState extends State<FaqOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FfiListFaq>(
      future: widget.client.faqs(),
      builder: (BuildContext context, AsyncSnapshot<FfiListFaq> snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: AppColors.backgroundColor,
            child: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          );
        } else {
          return Container(
            color: AppColors.backgroundColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.requireData.length,
              itemBuilder: (BuildContext context, int index) {
                return FaqListItem(
                  client: widget.client,
                  faq: snapshot.requireData[index],
                );
              },
            ),
          );
        }
      },
    );
  }
}
