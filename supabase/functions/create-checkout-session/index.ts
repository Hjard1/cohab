import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Creates a Stripe Checkout Session for the "formal" one-time purchase
 * (same access as the iOS in-app purchase com.hjard.cohab.formal), used by
 * the mycohab web site.
 *
 * Request:  POST with `Authorization: Bearer <supabase user JWT>` and a JSON
 *           body { success_url, cancel_url }.
 * Response: { "url": "<stripe checkout url>" }
 *
 * Required secrets (supabase secrets set ...):
 *   STRIPE_SECRET_KEY         — Stripe secret key (sk_live_... / sk_test_...)
 *   STRIPE_PRICE_ID_FORMAL    — Stripe Price id for the formal product (price_...)
 * Optional:
 *   ALLOWED_WEB_ORIGIN        — allowed origin for the web app, e.g.
 *                               https://mycohab.no. success_url/cancel_url must
 *                               start with this origin, and it is used as the
 *                               CORS Access-Control-Allow-Origin. If unset,
 *                               only http://localhost:8080 is allowed (fail-safe).
 */

function allowedOrigin(): string {
  return Deno.env.get("ALLOWED_WEB_ORIGIN") ?? "http://localhost:8080";
}

function corsHeaders(reqOrigin: string | null): Record<string, string> {
  const allowed = allowedOrigin();
  return {
    "Access-Control-Allow-Origin": reqOrigin === allowed ? reqOrigin : allowed,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

serve(async (req) => {
  const cors = corsHeaders(req.headers.get("Origin"));
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, "Content-Type": "application/json" },
    });

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "No authorization header" }, 401);
    }

    // Verify the requesting user via their JWT (same pattern as delete-account).
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    const priceId = Deno.env.get("STRIPE_PRICE_ID_FORMAL") ?? "";
    if (!stripeSecretKey || !priceId) {
      console.error("Missing STRIPE_SECRET_KEY or STRIPE_PRICE_ID_FORMAL");
      return json({ error: "Server misconfigured" }, 500);
    }

    // Validate redirect URLs against the allowed web origin.
    const body = await req.json().catch(() => ({}));
    const successUrl = String(body?.success_url ?? "");
    const cancelUrl = String(body?.cancel_url ?? "");
    const origin = allowedOrigin();
    if (!successUrl.startsWith(origin) || !cancelUrl.startsWith(origin)) {
      return json({ error: "success_url/cancel_url must start with the allowed web origin" }, 400);
    }

    const params = new URLSearchParams({
      mode: "payment",
      "line_items[0][price]": priceId,
      "line_items[0][quantity]": "1",
      client_reference_id: user.id,
      success_url: successUrl,
      cancel_url: cancelUrl,
    });
    if (user.email) {
      params.set("customer_email", user.email);
    }

    const stripeRes = await fetch("https://api.stripe.com/v1/checkout/sessions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    });

    if (!stripeRes.ok) {
      const errText = await stripeRes.text();
      console.error("Stripe error", stripeRes.status, errText);
      return json({ error: "Stripe checkout session failed" }, 500);
    }

    const session = await stripeRes.json();
    return json({ url: session.url });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
