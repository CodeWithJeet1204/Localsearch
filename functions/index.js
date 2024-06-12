/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
console.log("started");

exports.sendNewProductNotification = functions.firestore
  .document("Business/Data/Products/{productId}")
  .onCreate(async (snap, context) => {
    const newValue = snap.data();
    const productId = context.params.productId;
    const vendorId = newValue.vendorId;
    const productName = newValue.productName;

    const payload = {
      notification: {
        title: "New Product Added!",
        body: `Check out the new product: ${productName}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      const usersSnapshot = await admin.firestore().collection("Users").get();
      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (
          userData.followedShops &&
          userData.followedShops.includes(vendorId)
        ) {
          const token = userData.fcmToken;
          if (token) {
            tokens.push(token);
          }
        }
      });

      if (tokens.length > 0) {
        await admin.messaging().sendToDevice(tokens, payload);
        console.log(`Notifications sent to ${tokens.length} users.`);
      } else {
        console.log("No users found who follow this vendor.");
      }
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });
