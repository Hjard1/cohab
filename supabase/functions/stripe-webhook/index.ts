import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Stripe webhook for cohab.
 *
 * Configure in the Stripe dashboard as:
 *   https://yvckcujoopwqjjnoxsze.supabase.co/functions/v1/stripe-webhook
 * listening for (at least) `checkout.session.completed`.
 *
 * On checkout.session.completed the user's cohab_entitlements row is upserted
 * with formal_unlocked=true (source 'stripe_web'), keyed by
 * client_reference_id (the Supabase user id set by create-checkout-session).
 *
 * Signature is verified manually (HMAC-SHA256 over `${t}.${rawBody}` against
 * the v1 signature in the Stripe-Signature header; timestamp tolerance 5 min).
 * No Stripe SDK.
 *
 * Required secrets (supabase secrets set ...):
 *   STRIPE_WEBHOOK_SECRET — webhook signing secret (whsec_...) from the
 *                           Stripe dashboard for this endpoint.
 * SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically
 * in Supabase edge functions.
 */

const SIGNATURE_TOLERANCE_SECONDS = 300;

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

async function verifyStripeSignature(
  rawBody: string,
  header: string,
  secret: string
): Promise<boolean> {
  // Header format: t=1492774577,v1=5257a869...,v1=...
  const parts = header.split(",");
  let timestamp = "";
  const signatures: string[] = [];
  for (const part of parts) {
    const [key, value] = part.split("=");
    if (key === "t") timestamp = value;
    else if (key === "v1") signatures.push(value);
  }
  if (!timestamp || signatures.length === 0) return false;

  // Reject events older than the tolerance (replay protection).
  const ageSeconds = Math.floor(Date.now() / 1000) - parseInt(timestamp, 10);
  if (!Number.isFinite(ageSeconds) || Math.abs(ageSeconds) > SIGNATURE_TOLERANCE_SECONDS) {
    return false;
  }

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"]
  );

  const signedPayload = new TextEncoder().encode(`${timestamp}.${rawBody}`);
  for (const sig of signatures) {
    try {
      const ok = await crypto.subtle.verify("HMAC", key, hexToBytes(sig), signedPayload);
      if (ok) return true;
    } catch {
      // malformed signature — try the next one
    }
  }
  return false;
}

serve(async (req) => {
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    });

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const secret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
    if (!secret) {
      console.error("Missing STRIPE_WEBHOOK_SECRET");
      return json({ error: "Server misconfigured" }, 500);
    }

    const rawBody = await req.text();
    const signatureHeader = req.headers.get("Stripe-Signature") ?? "";
    if (!(await verifyStripeSignature(rawBody, signatureHeader, secret))) {
      return json({ error: "Invalid signature" }, 400);
    }

    const event = JSON.parse(rawBody);
    if (event?.type !== "checkout.session.completed") {
      // Acknowledge and ignore everything else.
      return json({ received: true, ignored: event?.type ?? "unknown" });
    }

    const session = event?.data?.object ?? {};
    const userId = String(session.client_reference_id ?? "");
    const sessionId = String(session.id ?? "");
    if (!userId || !sessionId) {
      console.error("checkout.session.completed missing client_reference_id or id", sessionId);
      return json({ received: true, ignored: "missing user reference" });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { error } = await supabaseAdmin
      .from("cohab_entitlements")
      .upsert(
        {
          user_id: userId,
          formal_unlocked: true,
          source: "stripe_web",
          stripe_session_id: sessionId,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" }
      );

    if (error) {
      // stripe_session_id is unique — a duplicate means Stripe retried an
      // already-processed event. Acknowledge instead of triggering retries.
      if (error.code === "23505") {
        console.log("Duplicate stripe_session_id, already processed:", sessionId);
        return json({ received: true, duplicate: true });
      }
      console.error("Failed to upsert entitlement:", error);
      return json({ error: "Database error" }, 500);
    }

    return json({ received: true });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
