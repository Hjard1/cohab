import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * DealBuilder webhook for cohab.
 *
 * Configure in the DealBuilder dashboard as:
 *   https://yvckcujoopwqjjnoxsze.supabase.co/functions/v1/dealbuilder-webhook?token=<DEALBUILDER_WEBHOOK_SECRET>
 *
 * Security (improved over Samboappen's version):
 *  - If DEALBUILDER_WEBHOOK_SECRET is set, the ?token= query param must match.
 *  - We only act on document IDs present in cohab_dealbuilder_cases —
 *    Samboappen events and arbitrary guesses are acknowledged and ignored.
 *
 * Always returns 200 to prevent DealBuilder retries.
 */
serve(async (req) => {
  const json = (body: unknown) =>
    new Response(JSON.stringify(body), {
      headers: { "Content-Type": "application/json" },
    });

  if (req.method === "GET") {
    return json({ status: "ok" });
  }

  try {
    const secret = Deno.env.get("DEALBUILDER_WEBHOOK_SECRET") ?? "";
    if (secret) {
      const token = new URL(req.url).searchParams.get("token") ?? "";
      if (token !== secret) {
        return json({ ok: true, action: "ignored", reason: "bad token" });
      }
    }

    const payload = await req.json();

    // Tolerantly extract fields — DealBuilder event shapes vary.
    const documentId = String(
      payload?.documentId ??
        payload?.document?.id ??
        payload?.data?.id ??
        payload?.data?.documentId ??
        payload?.id ??
        ""
    );
    const eventType = String(payload?.eventType ?? payload?.event ?? payload?.type ?? "");
    const rawStatus = String(
      payload?.status ?? payload?.data?.status ?? payload?.document?.status ?? ""
    );

    if (!documentId) {
      return json({ ok: true, action: "ignored", reason: "no document id" });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Only act on cases this app created.
    const { data } = await supabase
      .from("cohab_dealbuilder_cases")
      .select("id")
      .eq("document_id", documentId)
      .maybeSingle();

    if (!data) {
      return json({ ok: true, action: "ignored", reason: "not a cohab case" });
    }

    const signed = /sign|complet/i.test(eventType) || /^(signed|completed)$/i.test(rawStatus);
    const dead = /revok|expir|declin/i.test(eventType) || /^(revoked|expired|declined)$/i.test(rawStatus);

    if (!signed && !dead) {
      return json({ ok: true, action: "ignored", reason: "unhandled event", eventType });
    }

    const update: Record<string, unknown> = signed
      ? { status: "completed", completed_at: new Date().toISOString() }
      : { status: "revoked" };

    await supabase
      .from("cohab_dealbuilder_cases")
      .update(update)
      .eq("document_id", documentId);

    return json({ ok: true, action: signed ? "completed" : "revoked", documentId });
  } catch (err) {
    // Always 200 — prevents DealBuilder retry storms.
    return json({ ok: true, error: String(err) });
  }
});
