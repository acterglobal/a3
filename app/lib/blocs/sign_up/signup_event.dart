abstract class SignUpEvent {}

class SignUpUsernameChanged extends SignUpEvent {
  final String username;

  SignUpUsernameChanged({required this.username});
}

class SignUpPasswordChanged extends SignUpEvent {
  final String password;

  SignUpPasswordChanged({required this.password});
}

class SignUpFirstNameChanged extends SignUpEvent {
  final String firstName;

  SignUpFirstNameChanged({required this.firstName});
}

class SignUpLastNameChanged extends SignUpEvent {
  final String lastName;

  SignUpLastNameChanged({required this.lastName});
}

class SignUpSubmitted extends SignUpEvent {
  final String username;
  final String password;

  SignUpSubmitted({required this.username, required this.password});
}
