import 'package:effektio/blocs/chatList/chatList_event.dart';
import 'package:effektio/blocs/chatList/chatList_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  ChatListBloc() : super(ChatListInitial()) {}
}
