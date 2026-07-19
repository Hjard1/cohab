/**
 * notify-partner — push a localized APNs notification to the OTHER household
 * members when someone adds an asset, contribution or expense.
 *
 * Called from the iOS app after a successful insert. The caller's user JWT
 * (Authorization: Bearer <access_token>) identifies the actor; we verify
 * household membership, then push to every other member's device tokens.
 *
 * Required secrets:
 *   APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_P8  — from an Apple APNs Auth Key (.p8)
 *   APNS_TOPIC       — bundle id (default com.hjard.cohab)
 *   APNS_PRODUCTION  — "true" for App Store builds, otherwise sandbox
 */
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import * as jose from "https://esm.sh/jose@5.9.6";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const MESSAGES: Record<string, Record<string, string>> = {
  asset: {
    nb: "{name} la til en eiendel: {label}",
    en: "{name} added an asset: {label}",
    sv: "{name} lade till en tillgång: {label}",
    da: "{name} tilføjede et aktiv: {label}",
    fi: "{name} lisäsi omaisuuden: {label}",
    de: "{name} hat einen Vermögenswert hinzugefügt: {label}",
    fr: "{name} a ajouté un bien : {label}",
    es: "{name} añadió un bien: {label}",
  },
  contribution: {
    nb: "{name} registrerte et bidrag: {label}",
    en: "{name} registered a contribution: {label}",
    sv: "{name} registrerade ett bidrag: {label}",
    da: "{name} registrerede et bidrag: {label}",
    fi: "{name} rekisteröi maksun: {label}",
    de: "{name} hat eine Einzahlung erfasst: {label}",
    fr: "{name} a enregistré un apport : {label}",
    es: "{name} registró una aportación: {label}",
  },
  expense: {
    nb: "{name} la til en utgift: {label}",
    en: "{name} added an expense: {label}",
    sv: "{name} lade till en utgift: {label}",
    da: "{name} tilføjede en udgift: {label}",
    fi: "{name} lisäsi kulun: {label}",
    de: "{name} hat eine Ausgabe hinzugefügt: {label}",
    fr: "{name} a ajouté une dépense : {label}",
    es: "{name} añadió un gasto: {label}",
  },
};

let cachedJwt: { token: string; issuedAt: number } | null = null;

/** APNs provider JWT (ES256, max 60 min old — cache for 50). */
async function apnsJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwt.issuedAt < 50 * 60) return cachedJwt.token;

  const p8 = Deno.env.get("APNS_KEY_P8") ?? "";
  const keyId = Deno.env.get("APNS_KEY_ID") ?? "";
  const teamId = Deno.env.get("APNS_TEAM_ID") ?? "";
  if (!p8 || !keyId || !teamId) throw new Error("APNs not configured");

  const key = await jose.importPKCS8(p8.replace(/\\n/g, "\n"), "ES256");
  const token = await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt(now)
    .sign(key);
  cachedJwt = { token, issuedAt: now };
  return token;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const accessToken = authHeader.replace(/^Bearer\s+/i, "");
    if (!accessToken) return json({ error: "missing auth" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey);

    // Who is calling?
    const { data: { user }, error: authError } = await admin.auth.getUser(accessToken);
    if (authError || !user) return json({ error: "unauthorized" }, 401);

    const { kind, label, household_id } = await req.json();
    if (!kind || !MESSAGES[kind] || !household_id) {
      return json({ error: "bad request" }, 400);
    }

    // Membership + actor's display name (partner label by role).
    const [{ data: members }, { data: household }] = await Promise.all([
      admin.from("household_members").select("user_id, role").eq("household_id", household_id),
      admin.from("households").select("partner_a_label, partner_b_label").eq("id", household_id).single(),
    ]);
    const me = (members ?? []).find((m) => m.user_id === user.id);
    if (!me) return json({ error: "not a household member" }, 403);

    const others = (members ?? []).filter((m) => m.user_id !== user.id).map((m) => m.user_id);
    if (others.length === 0) return json({ sent: 0 });

    const name = me.role === "a"
      ? (household?.partner_a_label ?? "Partner")
      : (household?.partner_b_label ?? "Partner");

    const { data: tokens } = await admin
      .from("device_tokens").select("id, token, language").in("user_id", others);
    if (!tokens || tokens.length === 0) return json({ sent: 0 });

    const jwt = await apnsJwt();
    const topic = Deno.env.get("APNS_TOPIC") ?? "com.hjard.cohab";
    const host = Deno.env.get("APNS_PRODUCTION") === "true"
      ? "https://api.push.apple.com"
      : "https://api.sandbox.push.apple.com";

    let sent = 0;
    const staleIds: string[] = [];
    await Promise.all(tokens.map(async (t) => {
      const template = MESSAGES[kind][t.language] ?? MESSAGES[kind].en;
      const body = template.replace("{name}", name).replace("{label}", String(label ?? ""));
      const res = await fetch(`${host}/3/device/${t.token}`, {
        method: "POST",
        headers: {
          authorization: `bearer ${jwt}`,
          "apns-topic": topic,
          "apns-push-type": "alert",
          "apns-priority": "10",
        },
        body: JSON.stringify({
          aps: { alert: { title: "cohab", body }, sound: "default" },
        }),
      });
      if (res.ok) {
        sent += 1;
      } else if (res.status === 410 || res.status === 400) {
        // Token no longer valid — clean it up.
        staleIds.push(t.id);
      }
      await res.text().catch(() => {});
    }));

    if (staleIds.length > 0) {
      await admin.from("device_tokens").delete().in("id", staleIds);
    }
    return json({ sent });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
