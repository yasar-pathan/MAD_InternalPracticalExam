import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

final userChatsProvider = StreamProvider.family<List<ChatModel>, String>((ref, uid) {
  return ref.watch(chatServiceProvider).getUserChats(uid);
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).getMessages(chatId);
});

final unreadChatCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return ref.watch(chatServiceProvider).getUserChats(uid).map((chats) {
    return chats.fold<int>(0, (sum, chat) => sum + (chat.unreadCounts[uid] ?? 0));
  });
});
