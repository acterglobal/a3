abstract class ChatListState {
  @override
  List<Object> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoadSuccess extends ChatListState {}

class ChatListLoadFailed extends ChatListState {}
