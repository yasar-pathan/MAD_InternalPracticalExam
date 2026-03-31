import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/chat_model.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/listing_service.dart';
import '../../services/review_service.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view chats.')));
    }

    final chatsAsync = ref.watch(userChatsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _ChatTile(chat: chats[index], currentUid: user.uid),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error loading chats: $e')),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat, required this.currentUid});

  final ChatModel chat;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = chat.participants.firstWhere((id) => id != currentUid, orElse: () => '');
    final unread = chat.unreadCounts[currentUid] ?? 0;

    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        ref.read(reviewServiceProvider).getUser(otherUid),
        ref.read(listingServiceProvider).getListingById(chat.listingId),
      ]),
      builder: (context, snapshot) {
        final user = snapshot.data?[0] as UserModel?;
        final listing = snapshot.data?[1] as ListingModel?;

        return ListTile(
          onTap: () => context.push(
            '/chat/${chat.id}',
            extra: {'otherUserId': otherUid, 'otherUserName': user?.name ?? 'User'},
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user?.avatar != null ? CachedNetworkImageProvider(user!.avatar!) : null,
                child: user?.avatar == null ? const Icon(Icons.person) : null,
              ),
              if (listing != null && listing.images.isNotEmpty)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: listing.images.first,
                      width: 18,
                      height: 18,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(user?.name ?? 'User', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(chat.lastMessage.isEmpty ? 'Start chatting' : chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('hh:mm a').format(chat.lastMessageTime), style: const TextStyle(fontSize: 11)),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
            ],
          ),
        );
      },
    );
  }
}
