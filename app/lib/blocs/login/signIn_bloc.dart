// ignore_for_file: require_trailing_commas

import 'package:effektio/blocs/login/form_submission_status.dart';
import 'package:effektio/blocs/login/signIn_event.dart';
import 'package:effektio/blocs/login/signIn_state.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(SignInState()) {
    on<SignInUsernameChanged>(_signInUsername);
    on<SignInPasswordChanged>(_signInPassword);
    on<SignInSubmitted>(_signInSubmitted);
  }

  void _signInUsername(SignInUsernameChanged event, Emitter<SignInState> emit) {
    emit(state.copywith(username: event.username));
  }

  void _signInPassword(SignInPasswordChanged event, Emitter<SignInState> emit) {
    emit(state.copywith(password: event.password));
  }

  Future<Client> login(String username, String password) async {
    final sdk = await EffektioSdk.instance;
    if (!username.contains(':')) {
      username = '${username}:effektio.org';
    }
    if (!username.startsWith('@')) {
      username = '@${username}';
    }
    Client client = await sdk.login(username, password);
    return client;
  }

  Future<void> _signInSubmitted(
      SignInSubmitted event, Emitter<SignInState> emit) async {
    emit(state.copywith(formStatus: FormSubmitting()));
    try {
      await login(event.username, event.password);
      emit(state.copywith(formStatus: SubmissionSuccess()));
    } catch (e) {
      emit(state.copywith(formStatus: SubmissionFailed(e as String)));
    }
  }
}
