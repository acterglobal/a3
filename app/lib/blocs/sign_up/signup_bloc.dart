import 'package:effektio/blocs/sign_up/form_submition_status.dart';
import 'package:effektio/blocs/sign_up/signup_event.dart';
import 'package:effektio/blocs/sign_up/signup_state.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc() : super(SignUpState()) {
    on<SignUpUsernameChanged>(_signUpUsername);
    on<SignUpPasswordChanged>(_signUpPassword);
    on<SignUpNameChanged>(_signUpName);
    on<SignUpTokenChanged>(_signUpToken);
    on<SignUpSubmitted>(_signUpSubmitted);
  }

  void _signUpUsername(SignUpUsernameChanged event, Emitter<SignUpState> emit) {
    emit(state.copywith(username: event.username));
  }

  void _signUpPassword(SignUpPasswordChanged event, Emitter<SignUpState> emit) {
    emit(state.copywith(password: event.password));
  }

  void _signUpToken(SignUpTokenChanged event, Emitter<SignUpState> emit) {
    emit(state.copywith(token: event.token));
  }

  void _signUpName(
    SignUpNameChanged event,
    Emitter<SignUpState> emit,
  ) {
    emit(state.copywith(name: event.name));
  }

  Future<Client> signUp(
    String username,
    String password,
    String displayName,
    String token,
  ) async {
    final sdk = await EffektioSdk.instance;
    if (!username.contains(':')) {
      username = '$username:effektio.org';
    }
    if (!username.startsWith('@')) {
      username = '@$username';
    }
    Client client = await sdk.signUp(
      username,
      password,
      displayName,
      token,
    );
    return client;
  }

  Future<void> _signUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    emit(state.copywith(formStatus: FormSubmitting()));
    try {
      await signUp(event.username, event.password, event.name, event.token);
      emit(state.copywith(formStatus: SubmissionSuccess()));
      emit(state.copywith(formStatus: const InitialFormStatus()));
    } catch (e) {
      emit(state.copywith(formStatus: SubmissionFailed(e as String)));
      emit(state.copywith(formStatus: const InitialFormStatus()));
    }
  }
}
