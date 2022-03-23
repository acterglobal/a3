// ignore_for_file: require_trailing_commas

import 'package:effektio/blocs/login/form_submission_status.dart';

class SignInState {
  final String username;
  final String password;
  final FormSubmissionStatus formStatus;

  SignInState(
      {this.username = '',
      this.password = '',
      this.formStatus = const InitialFormStatus()});

  SignInState copywith(
      {String? username, String? password, FormSubmissionStatus? formStatus}) {
    return SignInState(
      username: username ?? this.username,
      password: password ?? this.password,
      formStatus: formStatus ?? this.formStatus,
    );
  }
}
