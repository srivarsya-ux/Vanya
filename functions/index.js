/**
 * Deploys as a Firebase Cloud Function. Triggers whenever a new document is
 * created in the `requests` collection (i.e. someone tapped "Request Key")
 * and pushes a notification to the Co-Keeper's registered device, so they
 * actually find out about it instead of the request just sitting silently
 * in Firestore.
 *
 * Deploy with:
 *   cd functions && npm install && firebase deploy --only functions
 *
 * Requires the Firebase project to be on the Blaze (pay-as-you-go) plan --
 * Cloud Functions aren't available on the free Spark plan.
 */
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// Vanya's server-side AI decision proxy -- see intervention.js for the
// full explanation of why this exists (keeps the Anthropic API key out
// of the compiled app). Re-exported from here so `firebase deploy
// --only functions` picks it up alongside the existing push-notification
// function without needing a separate deploy target.
exports.decideIntervention = require("./intervention").decideIntervention;

exports.onKeyRequestCreated = onDocumentCreated("requests/{requestId}", async (event) => {
  const request = event.data?.data();
  if (!request) return;

  const db = getFirestore();
  const coKeeperDoc = await db.collection("users").doc(request.coKeeperId).get();
  const token = coKeeperDoc.data()?.fcmToken;
  if (!token) {
    console.log(`No FCM token on file for Co-Keeper ${request.coKeeperId}; can't notify them.`);
    return;
  }

  const requesterName = request.requesterName || "Someone you're keeping";

  await getMessaging().send({
    token,
    notification: {
      title: `${requesterName} is requesting a key`,
      body: request.reason
        ? `Wants to open ${request.appPackage} -- ${request.reason}`
        : `Wants to open ${request.appPackage}`,
    },
    data: {
      type: "key_request",
      requestId: event.params.requestId,
    },
  });
});
