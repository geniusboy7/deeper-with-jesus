import * as admin from "firebase-admin";
import {
  onDocumentUpdated,
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ---------------------------------------------------------------------------
// 1. onPostPublished — Firestore trigger: when a post's isPublished flips to true
// ---------------------------------------------------------------------------
export const onPostPublished = onDocumentUpdated(
  "posts/{postId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only fire when isPublished changes from false → true
    if (before.isPublished === true || after.isPublished !== true) return;

    const postId = event.params.postId;
    const title = (after.caption as string) || "New Devotional";
    const scheduledFor = after.scheduledFor?.toDate?.()?.toISOString() ?? "";

    await messaging.send({
      topic: "new_posts",
      notification: {
        title: "Deeper With Jesus",
        body: title,
      },
      data: {
        postId,
        scheduledFor,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "devotional_posts",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    console.log(`Notification sent for post ${postId}: "${title}"`);
  }
);

// ---------------------------------------------------------------------------
// 2. onPostCreatedPublished — Firestore trigger: post created already published
// ---------------------------------------------------------------------------
export const onPostCreatedPublished = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.isPublished !== true) return;

    const postId = event.params.postId;
    const title = (data.caption as string) || "New Devotional";
    const scheduledFor = data.scheduledFor?.toDate?.()?.toISOString() ?? "";

    await messaging.send({
      topic: "new_posts",
      notification: {
        title: "Deeper With Jesus",
        body: title,
      },
      data: {
        postId,
        scheduledFor,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "devotional_posts",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    console.log(
      `Notification sent for newly created post ${postId}: "${title}"`
    );
  }
);

// ---------------------------------------------------------------------------
// 3. sendCustomNotification — HTTPS Callable (admin-only)
// ---------------------------------------------------------------------------
export const sendCustomNotification = onCall(async (request) => {
  // Verify caller is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }

  // Verify caller is an admin
  const callerEmail = request.auth.token.email;
  if (!callerEmail) {
    throw new HttpsError("permission-denied", "No email on auth token.");
  }

  const adminDoc = await db
    .collection("admin_emails")
    .doc(callerEmail.toLowerCase())
    .get();

  if (!adminDoc.exists) {
    throw new HttpsError("permission-denied", "Not an admin.");
  }

  const { title, body } = request.data as { title: string; body: string };
  if (!title || !body) {
    throw new HttpsError(
      "invalid-argument",
      "Title and body are required."
    );
  }

  // Send to FCM topic
  await messaging.send({
    topic: "new_posts",
    notification: { title, body },
    android: {
      priority: "high",
      notification: {
        channelId: "devotional_posts",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  // Log to notifications collection
  await db.collection("notifications").add({
    title,
    body,
    sentBy: callerEmail,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    audience: "all",
  });

  console.log(`Custom notification sent by ${callerEmail}: "${title}"`);
  return { success: true };
});

// ---------------------------------------------------------------------------
// 4. autoPublishScheduledPosts — Runs every minute, publishes posts whose
//    scheduledFor time has passed and isPublished is still false.
// ---------------------------------------------------------------------------
export const autoPublishScheduledPosts = onSchedule(
  {
    schedule: "every 1 minutes",
    timeoutSeconds: 60,
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const snapshot = await db
      .collection("posts")
      .where("isPublished", "==", false)
      .where("scheduledFor", "<=", now)
      .get();

    if (snapshot.empty) {
      console.log("No posts to auto-publish.");
      return;
    }

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.update(doc.ref, {
        isPublished: true,
        updatedAt: now,
      });
    }
    await batch.commit();

    console.log(`Auto-published ${snapshot.size} post(s).`);
  }
);
