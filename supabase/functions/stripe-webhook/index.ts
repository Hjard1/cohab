import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Stripe webhook for cohab.
 *
 * Configure in the Stripe dashboard as:
 *   https://yvckcujoopwqjjnoxsze.supabase.co/functions/v1/stripe-webhook
 * listening for `checkout.session.completed` and `invoice.paid`.
 *
 * On checkout.session.completed the user's cohab_entitlements row is upserted
 * with formal_unlocked=true (source 'stripe_web'), keyed by
 * client_reference_id (the Supabase user id set by create-checkout-session).
 *
 * On invoice.paid the invoice PDF is fetched from Stripe and forwarded to the
 * accountant (hjardas@ebilag.com) via Resend — same flow as Samboappen.
 *
 * Signature is verified manually (HMAC-SHA256 over `${t}.${rawBody}` against
 * the v1 signature in the Stripe-Signature header; timestamp tolerance 5 min).
 * No Stripe SDK.
 *
 * Required secrets (supabase secrets set ...):
 *   STRIPE_WEBHOOK_SECRET — webhook signing secret (whsec_...) from the
 *                           Stripe dashboard for this endpoint.
 *   RESEND_API_KEY        — Resend API key for invoice forwarding (optional;
 *                           forwarding is skipped with a warning if unset).
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

    // Forward paid invoices to the accountant (ebilag) — same flow as Samboappen.
    // Always returns 200 so a Resend/PDF hiccup never triggers Stripe retries.
    if (event?.type === "invoice.paid") {
      const invoice = event?.data?.object ?? {};
      console.log("Invoice paid:", {
        invoice_id: invoice.id,
        invoice_number: invoice.number,
        customer_email: invoice.customer_email,
        amount_paid: invoice.amount_paid,
        currency: invoice.currency,
        invoice_pdf: invoice.invoice_pdf,
      });

      if (invoice.invoice_pdf) {
        const resendApiKey = Deno.env.get("RESEND_API_KEY");
        if (resendApiKey) {
          try {
            const pdfResponse = await fetch(invoice.invoice_pdf);
            if (pdfResponse.ok) {
              const pdfBuffer = await pdfResponse.arrayBuffer();
              const pdfBase64 = btoa(String.fromCharCode(...new Uint8Array(pdfBuffer)));

              const currency = String(invoice.currency || "nok").toUpperCase();
              const amountFormatted = ((invoice.amount_paid || 0) / 100).toFixed(2);
              const invoiceDate = invoice.created
                ? new Date(invoice.created * 1000).toLocaleDateString("nb-NO")
                : "ukjent";

              const emailRes = await fetch("https://api.resend.com/emails", {
                method: "POST",
                headers: {
                  Authorization: `Bearer ${resendApiKey}`,
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({
                  from: "Cohab <noreply@mycohab.app>",
                  to: ["hjardas@ebilag.com"],
                  subject: `Cohab faktura #${invoice.number || invoice.id}`,
                  html: `
                    <h2>Faktura fra Cohab</h2>
                    <p><strong>Fakturanummer:</strong> ${invoice.number || "N/A"}</p>
                    <p><strong>Dato:</strong> ${invoiceDate}</p>
                    <p><strong>Kunde:</strong> ${invoice.customer_email || "ukjent"}</p>
                    <p><strong>Beløp:</strong> ${amountFormatted} ${currency}</p>
                    <p>Faktura-PDF er vedlagt.</p>
                    <p><a href="${invoice.hosted_invoice_url}">Se faktura hos Stripe</a></p>
                  `,
                  attachments: [
                    {
                      filename: `faktura-${invoice.number || invoice.id}.pdf`,
                      content: pdfBase64,
                    },
                  ],
                }),
              });

              if (emailRes.ok) {
                console.log("Invoice forwarded to accountant (hjardas@ebilag.com):", invoice.number);
              } else {
                console.error("Failed to forward invoice to accountant:", await emailRes.text());
              }
            } else {
              console.error("Failed to fetch invoice PDF from Stripe:", pdfResponse.status);
            }
          } catch (emailErr) {
            console.error("Error forwarding invoice to accountant:", emailErr);
          }
        } else {
          console.warn("RESEND_API_KEY not configured, skipping invoice forwarding");
        }
      }

      return json({ received: true });
    }

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
