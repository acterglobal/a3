import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController token = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController name = TextEditingController();
  String errorText = '';
  bool isSubmitting = false;

  Future<Client> signUp(
    String username,
    String password,
    String displayName,
    String token,
  ) async {
    update();
    final sdk = await EffektioSdk.instance;
    Client client = await sdk.signUp(
      username,
      password,
      displayName,
      token,
    );
    return client;
  }

  Future<bool> signUpSubmitted() async {
    try {
      await signUp(username.text, password.text, name.text, token.text);
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
