const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.notifyOnNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const { chatId } = context.params;
    const message = snap.data();

    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return null;

    const chat = chatDoc.data();
    const participants = chat.participants || [];
    const receiverId = participants.find((uid) => uid !== message.senderId);
    if (!receiverId) return null;

    const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) return null;

    const receiver = receiverDoc.data();
    const tokens = receiver.fcmTokens || [];
    if (!Array.isArray(tokens) || tokens.length === 0) return null;

    const payload = {
      notification: {
        title: 'New message',
        body: message.text || 'You have a new message',
      },
      data: {
        chatId,
        senderId: message.senderId || '',
      },
    };

    await admin.messaging().sendEachForMulticast({
      tokens,
      ...payload,
    });

    return null;
  });
