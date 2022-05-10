// ignore_for_file: require_trailing_commas

import 'package:effektio/blocs/sign_up/form_submition_status.dart';

class SignUpState {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final FormSubmissionStatus formStatus;

  SignUpState(
      {this.username = '',
      this.password = '',
      this.firstName = '',
      this.lastName = '',
      this.formStatus = const InitialFormStatus()});

  SignUpState copywith(
      {String? username,
      String? password,
      String? firstName,
      String? lastName,
      FormSubmissionStatus? formStatus}) {
    return SignUpState(
      username: username ?? this.username,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      formStatus: formStatus ?? this.formStatus,
    );
  }
}
