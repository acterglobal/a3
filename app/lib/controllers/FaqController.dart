import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FaqController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  List<Faq> searchData = [];
  bool searchValue = false;

  void searchedData(String value, AsyncSnapshot<FfiListFaq> snapshot) {
    searchData.clear();
    for (var element in snapshot.requireData) {
      bool isTitleContains =
          element.title().toLowerCase().contains(value.toLowerCase().trim());
      for (var tag in element.tags()) {
        if (tag.title().toLowerCase() == value.toLowerCase().trim()) {
          if (!isTitleContains) {
            searchData.add(element);
          }
        }
      }
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
