import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../services/listing_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  final String chatId;
  final String otherUserId;
  final String otherUserName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        ref.read(chatServiceProvider).markAsRead(widget.chatId, uid);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    _controller.clear();
    await ref.read(chatServiceProvider).sendMessage(widget.chatId, uid, text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).value;
    if (auth == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final chatsAsync = ref.watch(userChatsProvider(auth.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/${widget.otherUserId}'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Column(
        children: [
          chatsAsync.when(
            data: (chats) {
              ChatModel? chat;
              for (final item in chats) {
                if (item.id == widget.chatId) {
                  chat = item;
                  break;
                }
              }
              if (chat == null) return const SizedBox.shrink();

              return FutureBuilder(
                future: ref.read(listingServiceProvider).getListingById(chat.listingId),
                builder: (context, snapshot) {
                  final listing = snapshot.data;
                  if (listing == null) return const SizedBox.shrink();

                  return ListTile(
                    onTap: () => context.push('/listing/${listing.id}'),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(imageUrl: listing.images.first, width: 44, height: 44, fit: BoxFit.cover)
                          : Container(width: 44, height: 44, color: Colors.grey.shade300),
                    ),
                    title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('\$${listing.price.toStringAsFixed(0)}'),
                  );
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, stack) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message.senderId == auth.uid;
                    return _Bubble(message: message, mine: mine);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text('Failed to load messages: $e')),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final MessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFE65100) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: mine ? Colors.white : Colors.black87)),
            const SizedBox(height: 2),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(color: mine ? Colors.white70 : Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
