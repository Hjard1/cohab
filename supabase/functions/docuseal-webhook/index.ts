import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DOCUSEAL_BASE_URL =
  Deno.env.get("DOCUSEAL_BASE_URL") ?? "https://api.docuseal.eu";
const DOCUSEAL_API_KEY = Deno.env.get("DOCUSEAL_API_KEY") ?? "";

/**
 * DocuSeal webhook handler for cohab.
 *
 * ISOLATION: The DocuSeal account is shared with Samboappen.
 * We only act on events where the submission id is in our own
 * cohab_docuseal_submissions table. Everything else is acknowledged
 * and ignored — Samboappen's webhook handles its own submissions.
 *
 * TRUST: A submission.completed event is never taken at face value.
 * We re-fetch the submission from the DocuSeal API and require that
 * EVERY submitter has completed before the agreement counts as signed.
 */
serve(async (req) => {
  try {
    const payload = await req.json();

    if (payload.event_type !== "submission.completed") {
      return new Response(
        JSON.stringify({ ok: true, action: "ignored", reason: "not submission.completed" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    const eventSubmissionId = String(payload.submission?.id ?? "");
    const eventSlug = payload.submission?.slug ?? "";

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Match on the numeric submission id. NOTE: the `slug` column holds
    // Partner A's *submitter* slug, while webhook events carry the
    // *submission* slug — those are different identifiers, so matching on
    // slug alone never worked. Slug match is kept only as a fallback for
    // rows that may store the submission slug.
    let data = null;
    if (eventSubmissionId) {
      const res = await supabase
        .from("cohab_docuseal_submissions")
        .select("id, submission_id")
        .eq("submission_id", eventSubmissionId)
        .maybeSingle();
      data = res.data;
    }
    if (!data && eventSlug) {
      const res = await supabase
        .from("cohab_docuseal_submissions")
        .select("id, submission_id")
        .eq("slug", eventSlug)
        .maybeSingle();
      data = res.data;
    }

    if (!data) {
      // Not a cohab submission — could be Samboappen. Acknowledge and ignore.
      return new Response(
        JSON.stringify({ ok: true, action: "ignored", reason: "not a cohab submission" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Verify with the DocuSeal API that BOTH parties actually signed. ──────
    const submissionId = data.submission_id || eventSubmissionId;
    const dsResp = await fetch(`${DOCUSEAL_BASE_URL}/submissions/${submissionId}`, {
      headers: { "X-Auth-Token": DOCUSEAL_API_KEY },
    });
    if (!dsResp.ok) {
      return new Response(
        JSON.stringify({ ok: true, action: "deferred", reason: `DocuSeal API ${dsResp.status}` }),
        { headers: { "Content-Type": "application/json" } }
      );
    }
    const submission = await dsResp.json();
    const submitters = submission.submitters ?? [];
    const allSigned =
      submission.status === "completed" &&
      submitters.length >= 2 &&
      submitters.every((s: { completed_at?: string | null }) => !!s.completed_at);

    if (!allSigned) {
      // Someone completed their part, but not everybody — do NOT mark signed.
      return new Response(
        JSON.stringify({
          ok: true,
          action: "deferred",
          reason: "not all submitters have signed",
          submitters: submitters.map((s: { role?: string; completed_at?: string | null }) => ({
            role: s.role,
            completed: !!s.completed_at,
          })),
        }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // All parties signed — mark as completed.
    await supabase
      .from("cohab_docuseal_submissions")
      .update({ status: "completed", completed_at: new Date().toISOString() })
      .eq("id", data.id);

    return new Response(
      JSON.stringify({ ok: true, action: "completed", submission_id: submissionId }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    // Always return 200 to DocuSeal to prevent retries
    return new Response(
      JSON.stringify({ ok: true, error: String(err) }),
      { headers: { "Content-Type": "application/json" } }
    );
  }
});
