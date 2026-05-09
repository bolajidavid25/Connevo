const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = functions.firestore
    .document("/chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const chatId = context.params.chatId;

        const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
        if (!chatDoc.exists) {
            return console.log("Chat room not found.");
        }
        
        const chatData = chatDoc.data();
        const participants = chatData.participants;

        const senderId = message.senderId;
        const recipientId = participants.find((uid) => uid !== senderId);

        if (!recipientId) {
            return console.log("Recipient not found.");
        }

        const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
        if (!recipientDoc.exists) {
            return console.log("Recipient user document not found.");
        }
        
        const recipientData = recipientDoc.data();
        const recipientToken = recipientData.fcmToken;
        const senderName = chatData.names[senderId] || "Someone";
        
        if (!recipientToken) {
            return console.log("Recipient FCM token not found.");
        }

        const payload = {
            notification: {
                title: `New message from ${senderName}`,
                body: message.text,
                sound: "default",
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                chatId: chatId,
            },
        };

        try {
            await admin.messaging().sendToDevice(recipientToken, payload);
            console.log("Notification sent successfully.");
        } catch (error) {
            console.error("Error sending notification:", error);
        }
        
        return null;
    });
