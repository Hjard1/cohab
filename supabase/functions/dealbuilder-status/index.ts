import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * DealBuilder (BankID) — active status poll.
 *
 * The DealBuilder API key only lives server-side, so the app calls this
 * function to refresh the signing status. Updates cohab_dealbuilder_cases
 * and returns the mapped status.
 */
const DEALBUILDER_BASE_URL = "https://api.dealbuilder.io";
const DEALBUILDER_API_KEY = Deno.env.get("DEALBUILDER_API_KEY_P") ?? "";

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
    if (!DEALBUILDER_API_KEY) {
      return json({ error: "DealBuilder not configured" }, 500);
    }

    const body = await req.json();
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Resolve which case to check: explicit document_id, or the household's
    // current case.
    let documentId = String(body.document_id ?? "");
    if (!documentId && body.household_id) {
      const { data } = await supabase
        .from("cohab_dealbuilder_cases")
        .select("document_id")
        .eq("household_id", String(body.household_id))
        .eq("is_current", true)
        .maybeSingle();
      documentId = data?.document_id ?? "";
    }
    if (!documentId) {
      return json({ error: "No DealBuilder case found" }, 404);
    }

    const statusResp = await fetch(`${DEALBUILDER_BASE_URL}/v1/Documents/${documentId}`, {
      headers: { "X-API-Key": DEALBUILDER_API_KEY },
    });
    if (!statusResp.ok) {
      const err = await statusResp.text();
      return json({ error: `DealBuilder status error ${statusResp.status}: ${err}` }, 502);
    }
    const payload = await statusResp.json();
    const doc = payload?.data ?? payload;
    // DealBuilder statuses: Draft, Sent, Signed, Revoked, Expired
    const raw = String(doc?.status ?? "unknown");
    const isCompleted = /^(signed|completed)$/i.test(raw);
    const isDead = /^(revoked|expired|declined)$/i.test(raw);
    const mapped = isCompleted ? "completed" : isDead ? "revoked" : "sent";

    const update: Record<string, unknown> = { status: mapped };
    if (isCompleted) update.completed_at = new Date().toISOString();
    await supabase
      .from("cohab_dealbuilder_cases")
      .update(update)
      .eq("document_id", documentId);

    return json({
      status: mapped,
      dealbuilder_status: raw,
      is_completed: isCompleted,
      document_id: documentId,
      app_url: doc?.appUrl ?? "",
      signed_url: doc?.uploadedDocumentUrl ?? doc?.previewUrl ?? "",
    });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});
