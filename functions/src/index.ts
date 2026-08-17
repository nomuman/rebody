import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as functions from "firebase-functions/v1";
import { HttpsError, onCall } from "firebase-functions/v2/https";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();
const timeZone = "Asia/Tokyo";

type SocialSettings = {
  sharingEnabled?: boolean;
  friendWorkoutNotifications?: boolean;
};

type UserData = {
  displayName?: string;
  socialSettings?: SocialSettings;
};

function requireUser(request: { auth?: { uid: string } | null }): string {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "ログインが必要です。");
  }
  return request.auth.uid;
}

function normalizeDisplayName(value: unknown): string {
  const displayName = typeof value === "string" ? value.trim() : "";
  if (displayName.length < 1 || displayName.length > 20) {
    throw new HttpsError("invalid-argument", "表示名は1〜20文字で入力してください。");
  }
  return displayName;
}

function normalizeInviteCode(value: unknown): string {
  const code = typeof value === "string" ? value.trim().toUpperCase() : "";
  if (!/^[A-Z2-9]{8}$/.test(code)) {
    throw new HttpsError("invalid-argument", "招待コードを確認してください。");
  }
  return code;
}

function dateKey(value: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(value);
}

function dateFromKey(key: string): Date {
  const [year, month, day] = key.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, day));
}

function daysBetween(older: string, newer: string): number {
  return Math.round((dateFromKey(newer).getTime() - dateFromKey(older).getTime()) / 86400000);
}

function currentStreak(keys: string[], today: string): number {
  const available = new Set(keys);
  const start = available.has(today) ? today : dateKey(new Date(Date.now() - 86400000));
  if (!available.has(start)) {
    return 0;
  }

  let streak = 0;
  let day = dateFromKey(start);
  while (available.has(dateKey(day))) {
    streak += 1;
    day = new Date(day.getTime() - 86400000);
  }
  return streak;
}

function weeklyCount(keys: string[], today: string): number {
  return keys.filter((key) => {
    const distance = daysBetween(key, today);
    return distance >= 0 && distance < 7;
  }).length;
}

async function userData(userId: string): Promise<UserData> {
  const snapshot = await db.collection("users").doc(userId).get();
  return (snapshot.data() ?? {}) as UserData;
}

async function recomputePublicProfile(userId: string): Promise<{ dateKey: string | null; isShared: boolean }> {
  const data = await userData(userId);
  const settings = data.socialSettings ?? {};
  const isShared = settings.sharingEnabled === true;
  if (!isShared) {
    await db.collection("publicProfiles").doc(userId).set({
      displayName: data.displayName ?? "仲間",
      sharingEnabled: false,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { dateKey: null, isShared: false };
  }

  const records = await db.collection("users").doc(userId).collection("workoutRecords").get();
  const keys = new Set<string>();
  for (const record of records.docs) {
    const value = record.data();
    if (typeof value.completedDate === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value.completedDate)) {
      keys.add(value.completedDate);
      continue;
    }
    const completedAt = value.completedAt as Timestamp | undefined;
    if (completedAt?.toDate) {
      keys.add(dateKey(completedAt.toDate()));
    }
  }

  const sortedKeys = [...keys].sort().reverse();
  const today = dateKey(new Date());
  const summary = {
    displayName: data.displayName ?? "仲間",
    sharingEnabled: true,
    currentStreakDays: currentStreak(sortedKeys, today),
    totalWorkoutDays: sortedKeys.length,
    weeklyWorkoutDays: weeklyCount(sortedKeys, today),
    lastWorkoutDate: sortedKeys[0] ?? null,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await db.collection("publicProfiles").doc(userId).set(summary, { merge: true });
  return { dateKey: sortedKeys[0] ?? null, isShared: true };
}

async function createUniqueInviteCode(): Promise<string> {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  for (let attempt = 0; attempt < 10; attempt += 1) {
    let code = "";
    for (let index = 0; index < 8; index += 1) {
      code += alphabet[Math.floor(Math.random() * alphabet.length)];
    }
    const existing = await db.collection("friendInvites").doc(code).get();
    if (!existing.exists) {
      return code;
    }
  }
  throw new HttpsError("resource-exhausted", "招待コードを作成できませんでした。");
}

export const updateSocialProfile = onCall(async (request) => {
  const userId = requireUser(request);
  const displayName = normalizeDisplayName(request.data?.displayName);
  await db.collection("users").doc(userId).set({
    displayName,
    socialSettings: { sharingEnabled: true },
  }, { merge: true });
  await recomputePublicProfile(userId);
  return { displayName };
});

export const setFriendSharingEnabled = onCall(async (request) => {
  const userId = requireUser(request);
  if (typeof request.data?.enabled !== "boolean") {
    throw new HttpsError("invalid-argument", "共有設定を確認してください。");
  }
  await db.collection("users").doc(userId).set({
    socialSettings: { sharingEnabled: request.data.enabled },
  }, { merge: true });
  await recomputePublicProfile(userId);
  return { enabled: request.data.enabled };
});

export const createFriendInvite = onCall(async (request) => {
  const userId = requireUser(request);
  const code = await createUniqueInviteCode();
  const expiresAt = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
  await db.collection("friendInvites").doc(code).set({
    ownerId: userId,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt,
    used: false,
  });
  return { code, expiresAt: expiresAt.toDate().toISOString() };
});

export const acceptFriendInvite = onCall(async (request) => {
  const userId = requireUser(request);
  const code = normalizeInviteCode(request.data?.code);
  const inviteReference = db.collection("friendInvites").doc(code);
  let ownerId = "";

  await db.runTransaction(async (transaction) => {
    const invite = await transaction.get(inviteReference);
    if (!invite.exists) {
      throw new HttpsError("not-found", "招待コードが見つかりません。");
    }
    const data = invite.data() ?? {};
    ownerId = typeof data.ownerId === "string" ? data.ownerId : "";
    const expiresAt = data.expiresAt as Timestamp | undefined;
    if (!ownerId || data.used === true || !expiresAt || expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("failed-precondition", "この招待コードは期限切れか使用済みです。");
    }
    if (ownerId === userId) {
      throw new HttpsError("invalid-argument", "自分の招待コードは使えません。");
    }

    const myFriendReference = db.collection("users").doc(userId).collection("friends").doc(ownerId);
    const ownerFriendReference = db.collection("users").doc(ownerId).collection("friends").doc(userId);
    transaction.set(myFriendReference, { status: "accepted", createdAt: FieldValue.serverTimestamp() });
    transaction.set(ownerFriendReference, { status: "accepted", createdAt: FieldValue.serverTimestamp() });
    transaction.update(inviteReference, { used: true, usedBy: userId, usedAt: FieldValue.serverTimestamp() });
  });

  await db.collection("users").doc(userId).set({ socialSettings: { sharingEnabled: true } }, { merge: true });
  await db.collection("users").doc(ownerId).set({ socialSettings: { sharingEnabled: true } }, { merge: true });
  await recomputePublicProfile(userId);
  await recomputePublicProfile(ownerId);
  return { friendId: ownerId };
});

export const removeFriend = onCall(async (request) => {
  const userId = requireUser(request);
  const friendId = typeof request.data?.friendId === "string" ? request.data.friendId : "";
  if (!friendId || friendId === userId) {
    throw new HttpsError("invalid-argument", "友達を確認してください。");
  }

  await db.runTransaction(async (transaction) => {
    transaction.delete(db.collection("users").doc(userId).collection("friends").doc(friendId));
    transaction.delete(db.collection("users").doc(friendId).collection("friends").doc(userId));
  });
  return { removed: true };
});

export const deleteSocialAccount = onCall(async (request) => {
  const userId = requireUser(request);
  const userReference = db.collection("users").doc(userId);
  const friendSnapshot = await userReference.collection("friends").get();
  const tokenSnapshot = await userReference.collection("notificationTokens").get();
  const batch = db.batch();
  for (const friend of friendSnapshot.docs) {
    batch.delete(db.collection("users").doc(friend.id).collection("friends").doc(userId));
    batch.delete(friend.ref);
  }
  for (const token of tokenSnapshot.docs) {
    batch.delete(token.ref);
  }
  batch.delete(db.collection("publicProfiles").doc(userId));
  await batch.commit();
  return { deleted: true };
});

async function sendWorkoutNotification(userId: string, workoutDate: string): Promise<void> {
  const sender = await userData(userId);
  if (sender.socialSettings?.sharingEnabled !== true) {
    return;
  }

  const markerReference = db.collection("socialNotificationDeliveries").doc(`${userId}_${workoutDate}`);
  let shouldSend = false;
  await db.runTransaction(async (transaction) => {
    const marker = await transaction.get(markerReference);
    if (!marker.exists) {
      transaction.create(markerReference, { createdAt: FieldValue.serverTimestamp() });
      shouldSend = true;
    }
  });
  if (!shouldSend) {
    return;
  }

  const friendSnapshot = await db.collection("users").doc(userId).collection("friends")
    .where("status", "==", "accepted").get();
  const tokens: Array<{ token: string; reference: FirebaseFirestore.DocumentReference }> = [];
  for (const friend of friendSnapshot.docs) {
    const friendData = await userData(friend.id);
    if (friendData.socialSettings?.friendWorkoutNotifications !== true) {
      continue;
    }
    const tokenSnapshot = await db.collection("users").doc(friend.id).collection("notificationTokens").get();
    for (const token of tokenSnapshot.docs) {
      const tokenValue = token.data().token;
      if (typeof tokenValue === "string" && tokenValue.length > 0) {
        tokens.push({ token: tokenValue, reference: token.ref });
      }
    }
  }
  if (tokens.length === 0) {
    return;
  }

  const title = `${sender.displayName ?? "友達"}さんが今日の一歩を完了しました`;
  for (let start = 0; start < tokens.length; start += 500) {
    const chunk = tokens.slice(start, start + 500);
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk.map((item) => item.token),
      notification: { title, body: "仲間の活動を見て、あなたも一歩進めましょう" },
      data: { type: "friendWorkoutCompleted", friendId: userId },
      apns: { payload: { aps: { sound: "default" } } },
    });
    const invalidTokens = response.responses
      .map((result, index) => ({ result, reference: chunk[index].reference }))
      .filter(({ result }) => result.error?.code === "messaging/registration-token-not-registered" || result.error?.code === "messaging/invalid-registration-token");
    if (invalidTokens.length > 0) {
      const cleanup = db.batch();
      for (const item of invalidTokens) {
        cleanup.delete(item.reference);
      }
      await cleanup.commit();
    }
  }
}

export const onWorkoutRecordChanged = functions.firestore.document("users/{userId}/workoutRecords/{recordId}").onWrite(async (change, context) => {
  const userId = context.params.userId;
  if (!change.after.exists) {
    await recomputePublicProfile(userId);
    return;
  }
  const summary = await recomputePublicProfile(userId);
  if (summary.isShared && summary.dateKey) {
    await sendWorkoutNotification(userId, summary.dateKey);
  }
});
