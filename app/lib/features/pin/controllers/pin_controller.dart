import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PinController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  List<ActerPin> searchData = [];
  bool searchValue = false;

  void searchedData(String value, AsyncSnapshot<FfiListActerPin> snapshot) {
    searchData.clear();
    for (var element in snapshot.requireData) {
      bool isTitleContains =
          element.title().toLowerCase().contains(value.toLowerCase().trim());
      // for (var tag in element.tags()) {
      //   if (tag.title().toLowerCase() == value.toLowerCase().trim()) {
      //     if (!isTitleContains) {
      //       searchData.add(element);
      //     }
      //   }
      // }
      if (isTitleContains) {
        searchData.add(element);
      }
    }
    update();
  }

  @override
  void onClose() {
    searchData.clear();
    update();
    super.onClose();
  }
}
