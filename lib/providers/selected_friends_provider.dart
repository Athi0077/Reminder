import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend.dart';

class SelectedFriendsNotifier extends StateNotifier<List<Friend>> {
  SelectedFriendsNotifier() : super([]);

  void toggleFriend(Friend friend) {
    if (state.any((f) => f.id == friend.id)) {
      state = state.where((f) => f.id != friend.id).toList();
    } else {
      state = [...state, friend];
    }
  }

  void clear() {
    state = [];
  }
  
  void setFriends(List<Friend> friends) {
    state = friends;
  }
}

final selectedFriendsProvider = StateNotifierProvider.autoDispose<SelectedFriendsNotifier, List<Friend>>((ref) {
  return SelectedFriendsNotifier();
});
