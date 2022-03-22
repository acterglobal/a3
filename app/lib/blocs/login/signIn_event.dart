abstract class SignInEvent {}

class SignInUsernameChanged extends SignInEvent {
  final String username;

  SignInUsernameChanged({required this.username});
}

class SignInPasswordChanged extends SignInEvent {
  final String password;

  SignInPasswordChanged({required this.password});
}

class SignInSubmitted extends SignInEvent {
  final String username;
  final String password;

  SignInSubmitted({required this.username, required this.password});
}
