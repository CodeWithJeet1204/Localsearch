const { onRequest } = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Logging
const logger = require("firebase-functions/logger");

// New Product Notification Function
// exports.sendNewProductNotification = functions.firestore
//   .document("Business/Data/Products/{productId}")
//   .onCreate(async (snap, context) => {
//     const newValue = snap.data();
//     const productId = context.params.productId;
//     const vendorId = newValue.vendorId;
//     const productName = newValue.productName;

//     const payload = {
//       notification: {
//         title: "New Product Added!",
//         body: `Check out the new product: ${productName}`,
//         click_action: "FLUTTER_NOTIFICATION_CLICK",
//       },
//     };

//     try {
//       const usersSnapshot = await admin.firestore().collection("Users").get();
//       const tokens = [];

//       usersSnapshot.forEach((doc) => {
//         const userData = doc.data();
//         if (
//           userData.followedShops &&
//           userData.followedShops.includes(vendorId)
//         ) {
//           const token = userData.fcmToken;
//           if (token) {
//             tokens.push(token);
//           }
//         }
//       });

//       if (tokens.length > 0) {
//         await admin.messaging().sendToDevice(tokens, payload);
//         console.log(`Notifications sent to ${tokens.length} users.`);
//       } else {
//         console.log("No users found who follow this vendor.");
//       }
//     } catch (error) {
//       console.error("Error sending notification:", error);
//     }
//   });

// Function to delete documents from Status collection every 23 hours 50 minutes
exports.scheduledFunction = functions.region('asia-southeast1').pubsub.schedule('every 5 minutes').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  const cutoff = new admin.firestore.Timestamp(now.seconds - (23 * 60 * 60 + 50 * 60), 0);
  const postsRef = admin.firestore().collection('Business').doc('Data').collection('Status');
  
  try {
    const snapshot = await postsRef.where('statusDateTime', '<=', cutoff).get();
    if (snapshot.empty) {
      console.log('No documents to delete.');
      return null;
    }

    const bucket = admin.storage().bucket();
    const batch = admin.firestore().batch();
    
    const fileDeletions = [];

    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);

      const statusImage = doc.data().statusImage;
      if (statusImage) {
        const filePath = statusImage.split('/o/')[1].split('?')[0].replace(/%2F/g, '/');

        fileDeletions.push(bucket.file(filePath).delete());
      }
    });

    await Promise.all(fileDeletions);

    await batch.commit();

    console.log(`Successfully deleted ${snapshot.size} documents and associated files.`);
  } catch (error) {
    console.error("Error deleting documents or files:", error);
  }
});


// Sample helloWorld function (optional, uncomment if needed)
// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
