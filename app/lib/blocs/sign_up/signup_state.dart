// ignore_for_file: require_trailing_commas

import 'package:effektio/blocs/sign_up/form_submition_status.dart';

class SignUpState {
  final String username;
  final String password;
  final String name;
  final String token;
  final FormSubmissionStatus formStatus;

  SignUpState(
      {this.username = '',
      this.password = '',
      this.name = '',
      this.token = '',
      this.formStatus = const InitialFormStatus()});

  SignUpState copywith(
      {String? username,
      String? password,
      String? name,
      String? token,
      FormSubmissionStatus? formStatus}) {
    return SignUpState(
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      token: token?? this.token,
      formStatus: formStatus ?? this.formStatus,
    );
  }
}
