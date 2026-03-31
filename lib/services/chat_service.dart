import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getOrCreateChat(String currentUid, String otherUid, String listingId) async {
    final existing = await _firestore
        .collection('chats')
        .where('listingId', isEqualTo: listingId)
        .where('participants', arrayContains: currentUid)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    final ref = _firestore.collection('chats').doc();
    await ref.set({
      'participants': [currentUid, otherUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'listingId': listingId,
      'unreadCounts': {currentUid: 0, otherUid: 0},
    });
    return ref.id;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await _firestore.runTransaction((tx) async {
      final chatSnap = await tx.get(chatRef);
      final participants = List<String>.from(chatSnap.data()?['participants'] ?? []);
      final unread = Map<String, dynamic>.from(chatSnap.data()?['unreadCounts'] ?? {});

      for (final uid in participants) {
        if (uid != senderId) {
          unread[uid] = ((unread[uid] ?? 0) as num).toInt() + 1;
        }
      }

      tx.set(messageRef, {
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      tx.update(chatRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': unread,
      });
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<ChatModel>> getUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> markAsRead(String chatId, String uid) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final unread = Map<String, dynamic>.from((await chatRef.get()).data()?['unreadCounts'] ?? {});
    unread[uid] = 0;
    await chatRef.update({'unreadCounts': unread});

    final unreadMessages = await chatRef
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
