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
 *   ALLOWED_WEB_ORIGIN        — comma-separated list of allowed origins for
 *                               the web app, e.g. "https://mycohab.app,http://localhost:8080".
 *                               success_url/cancel_url must start with one of
 *                               them, and a matching request origin is echoed
 *                               as CORS Access-Control-Allow-Origin. If unset,
 *                               only http://localhost:8080 is allowed (fail-safe).
 */

// Hjard AS er MVA-registrert i Norge. Forbrukerprisen (f.eks. 45 USD) er
// INKLUSIV 25 % MVA — momsen trekkes ut av prisen, ingenting legges på toppen.
let _cachedNoVatRateId: string | null = null;
async function getNorwayVatRateId(stripeSecretKey: string): Promise<string | null> {
  if (_cachedNoVatRateId) return _cachedNoVatRateId;
  const headers = {
    Authorization: `Bearer ${stripeSecretKey}`,
    "Content-Type": "application/x-www-form-urlencoded",
  };
  try {
    const listRes = await fetch("https://api.stripe.com/v1/tax_rates?active=true&limit=100", { headers });
    if (listRes.ok) {
      const list = await listRes.json();
      const existing = (list.data ?? []).find(
        (r: { country?: string; percentage?: number; inclusive?: boolean }) =>
          r.country === "NO" && Number(r.percentage) === 25 && r.inclusive === true
      );
      if (existing) {
        _cachedNoVatRateId = existing.id;
        return existing.id;
      }
    }
    const createRes = await fetch("https://api.stripe.com/v1/tax_rates", {
      method: "POST",
      headers,
      body: new URLSearchParams({
        display_name: "MVA",
        description: "Merverdiavgift Norge",
        jurisdiction: "NO",
        percentage: "25",
        inclusive: "true",
        country: "NO",
        tax_type: "vat",
      }).toString(),
    });
    if (createRes.ok) {
      const created = await createRes.json();
      _cachedNoVatRateId = created.id;
      return created.id;
    }
    console.error("Failed to create MVA tax rate:", createRes.status, await createRes.text());
  } catch (err) {
    console.error("Failed to resolve MVA tax rate:", err);
  }
  // Non-fatal: fall back to a session without tax rate rather than blocking the purchase.
  return null;
}

// "MVA" skal kun stå etter selskapsnavn (Hjard AS), ikke etter org.nr.
const INVOICE_FOOTER = "Hjard AS (MVA-registrert) — Org.nr 933 786 021";

function allowedOrigins(): string[] {
  return (Deno.env.get("ALLOWED_WEB_ORIGIN") ?? "http://localhost:8080")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);
}

function corsHeaders(reqOrigin: string | null): Record<string, string> {
  const allowed = allowedOrigins();
  const echo = reqOrigin && allowed.includes(reqOrigin) ? reqOrigin : allowed[0];
  return {
    "Access-Control-Allow-Origin": echo,
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

    // Validate redirect URLs against the allowed web origins.
    const body = await req.json().catch(() => ({}));
    const successUrl = String(body?.success_url ?? "");
    const cancelUrl = String(body?.cancel_url ?? "");
    const origins = allowedOrigins();
    const ok = (u: string) => origins.some((o) => u.startsWith(o));
    if (!ok(successUrl) || !ok(cancelUrl)) {
      return json({ error: "success_url/cancel_url must start with an allowed web origin" }, 400);
    }

    const params = new URLSearchParams({
      mode: "payment",
      "line_items[0][price]": priceId,
      "line_items[0][quantity]": "1",
      client_reference_id: user.id,
      success_url: successUrl,
      cancel_url: cancelUrl,
      // Managed Payments er påslått som standard på kontoen (ny API-versjon)
      // og støtter ikke invoice_creation[invoice_data]. Vi slår det av per
      // request slik at Hjard AS forblir selger og faktura utstedes med
      // org.nr og inkludert MVA — samme klassiske flyt som Samboappen.
      "managed_payments[enabled]": "false",
      // invoice_creation krever en Stripe-customer — opprett alltid (payment mode).
      customer_creation: "always",
      "invoice_creation[enabled]": "true",
      "invoice_creation[invoice_data][description]": "Cohab formal — engangsbetaling",
      "invoice_creation[invoice_data][custom_fields][0][name]": "Org.nr",
      "invoice_creation[invoice_data][custom_fields][0][value]": "933 786 021",
      "invoice_creation[invoice_data][footer]": INVOICE_FOOTER,
      "invoice_creation[invoice_data][rendering_options][amount_tax_display]": "include_inclusive_tax",
    });
    const vatRateId = await getNorwayVatRateId(stripeSecretKey);
    if (vatRateId) {
      params.set("line_items[0][tax_rates][0]", vatRateId);
    }
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
      // Include Stripe's own message so the failing parameter is visible
      // (same level of detail Samboappen returns from create-payment).
      let detail = errText.slice(0, 300);
      try {
        const parsed = JSON.parse(errText);
        if (parsed?.error?.message) detail = parsed.error.message;
      } catch { /* keep raw text */ }
      return json({ error: "Stripe checkout session failed", details: detail }, 500);
    }

    const session = await stripeRes.json();
    return json({ url: session.url });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
