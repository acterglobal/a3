import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:effektio/common/constants.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  String errorText = '';
  bool isSubmitting = false;

  Future<Client> login(String username, String password) async {
    update();
    final sdk = await EffektioSdk.instance;
    if (!username.contains(':')) {
      username = '$username:$defaultDomain';
    }
    if (!username.startsWith('@')) {
      username = '@$username';
    }
    Client client = await sdk.login(username, password);
    return client;
  }

  Future<bool> loginSubmitted() async {
    try {
      await login(username.text, password.text);
      isSubmitting = false;
      update();
      return true;
    } catch (e) {
      errorText = e.toString();
      isSubmitting = false;
      update();
      return false;
    }
  }
}
