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
      for (var tagElement in element.tags()) {
        if (tagElement.title() == (value.toLowerCase().trim())) {
          searchData.add(element);
        }
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
