import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Stripe webhook for cohab.
 *
 * Configure in the Stripe dashboard as:
 *   https://yvckcujoopwqjjnoxsze.supabase.co/functions/v1/stripe-webhook
 * listening for:
 *   - checkout.session.completed
 *   - customer.subscription.created
 *   - customer.subscription.updated
 *   - customer.subscription.deleted
 *
 * checkout.session.completed binds the Stripe subscription to the Supabase
 * user (client_reference_id, set by create-checkout-session) and unlocks
 * access. The subscription lifecycle events then keep cohab_entitlements in
 * sync: expires_at follows current_period_end, and access is revoked when
 * the subscription ends. The subscription carries the user id in
 * metadata.supabase_user_id, so lifecycle events map to a user even if the
 * checkout event was missed.
 *
 * Access rule shared by app and web: formal_unlocked = true AND
 * (expires_at IS NULL OR expires_at > now()). Rows from the old one-time
 * purchase have expires_at NULL = lifetime.
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

// Stripe subscription statuses that mean "the customer currently has access".
// past_due keeps access while Stripe retries the payment.
const ACTIVE_STATUSES = new Set(["active", "trialing", "past_due"]);

function periodEndIso(sub: Record<string, unknown>): string | null {
  const end = sub.current_period_end;
  return typeof end === "number" ? new Date(end * 1000).toISOString() : null;
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
    const eventType = String(event?.type ?? "");
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    if (eventType === "checkout.session.completed") {
      const session = event?.data?.object ?? {};
      const userId = String(session.client_reference_id ?? "");
      const sessionId = String(session.id ?? "");
      const subscriptionId = session.subscription ? String(session.subscription) : null;
      if (!userId || !sessionId) {
        console.error("checkout.session.completed missing client_reference_id or id", sessionId);
        return json({ received: true, ignored: "missing user reference" });
      }

      const { error } = await supabaseAdmin
        .from("cohab_entitlements")
        .upsert(
          {
            user_id: userId,
            formal_unlocked: true,
            source: "stripe_web",
            product_id: "stripe_yearly",
            status: "active",
            stripe_session_id: sessionId,
            stripe_subscription_id: subscriptionId,
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
    }

    if (
      eventType === "customer.subscription.created" ||
      eventType === "customer.subscription.updated" ||
      eventType === "customer.subscription.deleted"
    ) {
      const sub = event?.data?.object ?? {};
      const subscriptionId = String(sub.id ?? "");
      const userId = String(sub?.metadata?.supabase_user_id ?? "");
      const stripeStatus = String(sub.status ?? "");
      const isDeleted = eventType === "customer.subscription.deleted";
      const unlocked = !isDeleted && ACTIVE_STATUSES.has(stripeStatus);
      const status = isDeleted ? "canceled" : unlocked ? "active" : stripeStatus;
      const expiresAt = periodEndIso(sub);

      // Prefer the user id from subscription metadata; fall back to the row
      // already bound to this subscription by checkout.session.completed.
      let targetUserId = userId;
      if (!targetUserId && subscriptionId) {
        const { data } = await supabaseAdmin
          .from("cohab_entitlements")
          .select("user_id")
          .eq("stripe_subscription_id", subscriptionId)
          .limit(1)
          .maybeSingle();
        targetUserId = data?.user_id ?? "";
      }
      if (!targetUserId) {
        console.error("Subscription event without user mapping:", subscriptionId, eventType);
        return json({ received: true, ignored: "no user mapping" });
      }

      const payload = {
        formal_unlocked: unlocked,
        source: "stripe_web",
        product_id: "stripe_yearly",
        status,
        expires_at: expiresAt,
        stripe_subscription_id: subscriptionId || null,
        updated_at: new Date().toISOString(),
      };

      // Update first so an existing row keeps its stripe_session_id (audit
      // trail from checkout); insert when checkout.session.completed never
      // created a row for this user.
      const { data: updated, error: updateError } = await supabaseAdmin
        .from("cohab_entitlements")
        .update(payload)
        .eq("user_id", targetUserId)
        .select("user_id");

      if (updateError) {
        console.error("Failed to sync subscription state:", updateError);
        return json({ error: "Database error" }, 500);
      }

      if (!updated || updated.length === 0) {
        const { error: insertError } = await supabaseAdmin
          .from("cohab_entitlements")
          .insert({ user_id: targetUserId, ...payload });
        if (insertError) {
          console.error("Failed to insert entitlement:", insertError);
          return json({ error: "Database error" }, 500);
        }
      }
      return json({ received: true });
    }

    // Acknowledge and ignore everything else.
    return json({ received: true, ignored: eventType || "unknown" });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
