import { createHash } from "node:crypto";

import OpenAI from "openai";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();
setGlobalOptions({ region: "asia-northeast1", maxInstances: 10 });

const openAIAPIKey = defineSecret("OPENAI_API_KEY");
const defaultModel = "gpt-5.6-luna";
const maxDailyCalls = 3;

type Energy = "low" | "normal" | "high";
type BodyStatus = "good" | "sensitive" | "pain";
type Focus = "appearance" | "upperBody" | "ability" | "balanced";

type RecentSession = {
  sessionType: "rescue" | "standard" | "extended";
  durationMinutes: number;
  daysAgo: number;
};

type CoachInput = {
  availableMinutes: number;
  energy: Energy;
  bodyStatus: BodyStatus;
  interruptionRisk: boolean;
  focus: Focus;
  recommendedPlanID: string;
  recentSessions: RecentSession[];
};

type CoachResult = {
  message: string;
  source: "ai" | "fallback" | "safety" | "rateLimited";
};

const validValues = {
  energy: new Set<Energy>(["low", "normal", "high"]),
  bodyStatus: new Set<BodyStatus>(["good", "sensitive", "pain"]),
  focus: new Set<Focus>(["appearance", "upperBody", "ability", "balanced"]),
  sessionType: new Set<RecentSession["sessionType"]>(["rescue", "standard", "extended"]),
};

export const generateCoachMessage = onCall(
  { secrets: [openAIAPIKey], timeoutSeconds: 20, memory: "256MiB" },
  async (request): Promise<CoachResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "匿名認証が必要です。");
    }

    const input = parseInput(request);
    const safeMessage = fallbackMessage(input);

    if (input.bodyStatus === "pain") {
      return { message: safeMessage, source: "safety" };
    }

    let key = "";
    try {
      key = openAIAPIKey.value();
    } catch {
      return { message: safeMessage, source: "fallback" };
    }
    if (!key || key === "CONFIGURE_ME") {
      return { message: safeMessage, source: "fallback" };
    }

    if (!(await consumeDailyAllowance(request.auth.uid))) {
      return { message: safeMessage, source: "rateLimited" };
    }

    try {
      const client = new OpenAI({ apiKey: key });
      const response = await client.responses.create({
        model: process.env.OPENAI_MODEL || defaultModel,
        store: false,
        safety_identifier: createHash("sha256").update(request.auth.uid).digest("hex"),
        max_output_tokens: 160,
        input: [
          {
            role: "system",
            content: [
              {
                type: "input_text",
                text: [
                  "あなたはRe:Bodyの短いコーチです。",
                  "忙しい人が自由時間を失わず、今日の2〜15分を始めやすくなる一言だけ返してください。",
                  "入力された状態と最近の実行履歴だけを使い、人格を評価しないでください。",
                  "痛みの診断や治療、無理な運動、食事や体重の断定はしないでください。",
                  "痛みがある場合は休む提案を最優先します。",
                  "既存メニューの種目を追加・変更せず、70文字以内の自然な日本語を1文だけ返してください。",
                ].join("\n"),
              },
            ],
          },
          {
            role: "user",
            content: [
              {
                type: "input_text",
                text: JSON.stringify(input),
              },
            ],
          },
        ],
      });

      const message = response.output_text?.trim();
      if (message && message.length <= 120) {
        return { message, source: "ai" };
      }
    } catch (error) {
      console.error("AI coach request failed", error);
    }

    return { message: safeMessage, source: "fallback" };
  },
);

function parseInput(request: CallableRequest<unknown>): CoachInput {
  if (!request.data || typeof request.data !== "object") {
    throw new HttpsError("invalid-argument", "入力がありません。");
  }

  const raw = request.data as Record<string, unknown>;
  const availableMinutes = integerInRange(raw.availableMinutes, 2, 120);
  const energy = enumValue(raw.energy, validValues.energy);
  const bodyStatus = enumValue(raw.bodyStatus, validValues.bodyStatus);
  const focus = enumValue(raw.focus, validValues.focus);
  const recommendedPlanID = stringInRange(raw.recommendedPlanID, 1, 80);
  const interruptionRisk = raw.interruptionRisk === true;

  const recentSessions = Array.isArray(raw.recentSessions)
    ? raw.recentSessions.slice(0, 8).map(parseRecentSession)
    : [];

  return {
    availableMinutes,
    energy,
    bodyStatus,
    interruptionRisk,
    focus,
    recommendedPlanID,
    recentSessions,
  };
}

function parseRecentSession(value: unknown): RecentSession {
  if (!value || typeof value !== "object") {
    throw new HttpsError("invalid-argument", "最近の記録が不正です。");
  }

  const raw = value as Record<string, unknown>;
  return {
    sessionType: enumValue(raw.sessionType, validValues.sessionType),
    durationMinutes: integerInRange(raw.durationMinutes, 1, 120),
    daysAgo: integerInRange(raw.daysAgo, 0, 365),
  };
}

function integerInRange(value: unknown, minimum: number, maximum: number): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < minimum || value > maximum) {
    throw new HttpsError("invalid-argument", "数値の範囲が不正です。");
  }
  return value;
}

function stringInRange(value: unknown, minimumLength: number, maximumLength: number): string {
  if (typeof value !== "string" || value.length < minimumLength || value.length > maximumLength) {
    throw new HttpsError("invalid-argument", "文字列の長さが不正です。");
  }
  return value;
}

function enumValue<T extends string>(value: unknown, valid: Set<T>): T {
  if (typeof value !== "string" || !valid.has(value as T)) {
    throw new HttpsError("invalid-argument", "選択値が不正です。");
  }
  return value as T;
}

async function consumeDailyAllowance(uid: string): Promise<boolean> {
  const dateKey = new Date().toISOString().slice(0, 10);
  const reference = getFirestore().collection("users").doc(uid).collection("coachUsage").doc(dateKey);

  return getFirestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const current = snapshot.exists && typeof snapshot.data()?.count === "number" ? snapshot.data()?.count : 0;
    if (current >= maxDailyCalls) {
      return false;
    }

    transaction.set(reference, { count: current + 1, updatedAt: Timestamp.now() }, { merge: true });
    return true;
  });
}

function fallbackMessage(input: CoachInput): string {
  if (input.bodyStatus === "pain") {
    return "痛みがある日は休むのが、魅力と能力を守る今日の一手です。";
  }

  if (input.interruptionRisk || input.availableMinutes <= 2 || input.energy === "low") {
    return "今日は2分で十分。自由時間の前に、未来の自分へ一歩だけ渡しましょう。";
  }

  if (input.focus === "appearance") {
    return "お腹まわりを整える一回を、胸と体幹の土台づくりとして始めましょう。";
  }

  if (input.focus === "upperBody") {
    return "胸と腕の厚みは、今日の一回を積み重ねた先で少しずつ戻ってきます。";
  }

  if (input.focus === "ability") {
    return "テニスと抱っこを支える力は、脚と体幹の短い一回から育ちます。";
  }

  return "見た目と動ける力を、今日できる分だけ更新してから自分の時間へ戻りましょう。";
}
