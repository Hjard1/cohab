import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * DealBuilder (BankID) signing — create case.
 *
 * Mirrors docuseal-submit but for BankID signing via DealBuilder.
 * Flow: upload PDF → create signing case (mode SendByEmail) → track in
 * cohab_dealbuilder_cases. DealBuilder emails each signatory a personal
 * link; signing happens in their browser with BankID.
 */
const DEALBUILDER_BASE_URL = "https://api.dealbuilder.io";
const DEALBUILDER_API_KEY = Deno.env.get("DEALBUILDER_API_KEY_P") ?? "";
const DEALBUILDER_TEMPLATE_ID = Deno.env.get("DEALBUILDER_TEMPLATE_ID_P") ?? "";
// Must be a real user inside the DealBuilder organization.
const DEALBUILDER_SENDER_EMAIL =
  Deno.env.get("DEALBUILDER_SENDER_EMAIL_P") ?? "fredrik@samboappen.no";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const {
      pdf_base64,
      name_a,
      email_a,
      name_b,
      email_b,
      title,
      household_id,
    } = await req.json();

    if (!DEALBUILDER_API_KEY || !DEALBUILDER_TEMPLATE_ID) {
      return json({ error: "DealBuilder not configured (API key / template missing)" }, 500);
    }
    if (!pdf_base64 || !email_a || !email_b || !household_id) {
      return json({ error: "Missing pdf_base64, emails or household_id" }, 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // ── Allowance: 1 BankID signing included, ever. ─────────────────────────
    // Every further signing consumes one purchased credit (125 NOK
    // consumable IAP in the app). No monthly reset.
    const { count } = await supabase
      .from("cohab_dealbuilder_cases")
      .select("id", { count: "exact", head: true })
      .eq("household_id", household_id);

    if ((count ?? 0) >= 1) {
      const { data: credits } = await supabase
        .from("cohab_household_credits")
        .select("bankid_extra_credits")
        .eq("household_id", household_id)
        .maybeSingle();
      const available = credits?.bankid_extra_credits ?? 0;
      if (available < 1) {
        return json({
          error: "BANKID_CREDITS_EXHAUSTED",
          message: "One BankID signing per month is included. Purchase an extra signing to continue.",
        }, 402);
      }
      await supabase
        .from("cohab_household_credits")
        .update({
          bankid_extra_credits: available - 1,
          updated_at: new Date().toISOString(),
        })
        .eq("household_id", household_id);
    }

    // ── Step 1: Upload PDF ───────────────────────────────────────────────────
    const pdfBytes = Uint8Array.from(atob(pdf_base64), (c) => c.charCodeAt(0));
    const pdfBlob = new Blob([pdfBytes], { type: "application/pdf" });
    const formData = new FormData();
    formData.append("files", pdfBlob, `${title || "agreement"}.pdf`);

    const uploadResp = await fetch(`${DEALBUILDER_BASE_URL}/v1/uploads`, {
      method: "POST",
      headers: { "X-API-Key": DEALBUILDER_API_KEY },
      body: formData,
    });
    if (!uploadResp.ok) {
      const err = await uploadResp.text();
      return json({ error: `DealBuilder upload error ${uploadResp.status}: ${err}` }, 502);
    }
    const upload = await uploadResp.json();
    const uploadedPdfUrl = upload?.fileUrls?.[0] ?? "";
    if (!uploadedPdfUrl) {
      return json({ error: "DealBuilder upload returned no file URL" }, 502);
    }

    // ── Step 2: Create signing case ──────────────────────────────────────────
    const validUntil = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString();
    const createResp = await fetch(`${DEALBUILDER_BASE_URL}/v1/Documents`, {
      method: "POST",
      headers: {
        "X-API-Key": DEALBUILDER_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        mode: "SendByEmail",
        templateId: DEALBUILDER_TEMPLATE_ID,
        title: title || "Cohabitation Agreement",
        validUntil,
        creatorEmail: DEALBUILDER_SENDER_EMAIL,
        senderEmail: DEALBUILDER_SENDER_EMAIL,
        uploadedPdfUrl,
        externalSignatories: [
          { name: name_a, email: email_a },
          { name: name_b, email: email_b },
        ],
      }),
    });
    if (!createResp.ok) {
      const err = await createResp.text();
      return json({ error: `DealBuilder create error ${createResp.status}: ${err}` }, 502);
    }
    const created = await createResp.json();
    const doc = created?.data ?? created;
    const documentId = String(doc?.id ?? "");
    const appUrl = doc?.appUrl ?? "";
    const previewUrl = doc?.previewUrl ?? "";
    if (!documentId) {
      return json({ error: "DealBuilder create returned no document id" }, 502);
    }

    // Personal, login-free signing links per signatory. Matched by email —
    // never hand out appUrl (that is the DealBuilder admin view and
    // requires a login, which signatories must never need).
    const norm = (v: unknown) => String(v ?? "").trim().toLowerCase();
    let parties: { email?: string; signingUrl?: string }[] = doc?.parties ?? [];
    let signingUrlA =
      parties.find((p) => norm(p.email) === norm(email_a))?.signingUrl ?? "";
    let signingUrlB =
      parties.find((p) => norm(p.email) === norm(email_b))?.signingUrl ?? "";

    // Some responses omit the party links at creation time — refetch once.
    if (!signingUrlA || !signingUrlB) {
      const detailResp = await fetch(`${DEALBUILDER_BASE_URL}/v1/Documents/${documentId}`, {
        headers: { "X-API-Key": DEALBUILDER_API_KEY },
      });
      if (detailResp.ok) {
        const detail = await detailResp.json();
        parties = (detail?.data ?? detail)?.parties ?? [];
        signingUrlA = signingUrlA ||
          parties.find((p) => norm(p.email) === norm(email_a))?.signingUrl || "";
        signingUrlB = signingUrlB ||
          parties.find((p) => norm(p.email) === norm(email_b))?.signingUrl || "";
      }
    }

    // ── Step 3: Track in Supabase DB ─────────────────────────────────────────
    // Supersede any previous case for this household.
    await supabase
      .from("cohab_dealbuilder_cases")
      .update({ is_current: false })
      .eq("household_id", household_id)
      .eq("is_current", true);

    await supabase.from("cohab_dealbuilder_cases").insert({
      household_id,
      document_id: documentId,
      status: "sent",
      app_url: appUrl,
      preview_url: previewUrl,
      signing_url_a: signingUrlA,
      signing_url_b: signingUrlB,
      email_a,
      email_b,
      is_current: true,
    });

    return json({
      document_id: documentId,
      app_url: appUrl,
      preview_url: previewUrl,
      signing_url_a: signingUrlA,
      signing_url_b: signingUrlB,
    });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});
