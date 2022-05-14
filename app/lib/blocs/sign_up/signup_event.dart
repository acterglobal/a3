abstract class SignUpEvent {}

class SignUpUsernameChanged extends SignUpEvent {
  final String username;

  SignUpUsernameChanged({required this.username});
}

class SignUpPasswordChanged extends SignUpEvent {
  final String password;

  SignUpPasswordChanged({required this.password});
}

class SignUpTokenChanged extends SignUpEvent {
  final String token;

  SignUpTokenChanged({required this.token});
}

class SignUpNameChanged extends SignUpEvent {
  final String name;

  SignUpNameChanged({required this.name});
}

class SignUpSubmitted extends SignUpEvent {
  final String username;
  final String password;
  final String token;
  final String name;

  SignUpSubmitted(
      {required this.username,
      required this.password,
      required this.name,
      required this.token,});
}
