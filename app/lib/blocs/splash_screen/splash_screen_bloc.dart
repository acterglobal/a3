// ignore_for_file: override_on_non_overriding_member

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'splash_screen_event.dart';
part 'splash_screen_state.dart';

class SplashScreenBloc extends Bloc<SplashScreenEvent, SplashScreenState> {
  SplashScreenBloc() : super(Initial()) {
    on<NavigateToHomeScreenEvent>(_delayScreen);
  }
  // ignore: require_trailing_commas
  void _delayScreen(
      NavigateToHomeScreenEvent event, Emitter<SplashScreenState> emit) async {
    emit(Loading());
    await Future.delayed(
      const Duration(seconds: 4),
    );
    emit(Loaded());
  }

  // @override
  // Stream<SplashScreenState> mapEventToState(
  //   SplashScreenEvent event,
  // ) async* {
  //   if (event is NavigateToHomeScreenEvent) {
  //     yield Loading();

  //     // During the Loading state we can do additional checks like,
  //     // if the internet connection is available or not etc..

  //     await Future.delayed(
  //       const Duration(
  //         seconds: 4,
  //       ),
  //     ); // This is to simulate that above checking process
  //     yield Loaded(); // In this state we can load the HOME PAGE
  //   }
  // }
}
