import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * DocuSeal webhook handler for cohab.
 *
 * ISOLATION: The DocuSeal account is shared with Samboappen.
 * We only act on events where the submission slug is in our own
 * cohab_docuseal_submissions table. Everything else is acknowledged
 * and ignored — Samboappen's webhook handles its own submissions.
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

    const slug = payload.submission?.slug ?? "";

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Check if this submission belongs to cohab
    const { data } = await supabase
      .from("cohab_docuseal_submissions")
      .select("id")
      .eq("slug", slug)
      .maybeSingle();

    if (!data) {
      // Not a cohab submission — could be Samboappen. Acknowledge and ignore.
      return new Response(
        JSON.stringify({ ok: true, action: "ignored", reason: "not a cohab submission" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // Mark as completed
    await supabase
      .from("cohab_docuseal_submissions")
      .update({ status: "completed", completed_at: new Date().toISOString() })
      .eq("slug", slug);

    return new Response(
      JSON.stringify({ ok: true, action: "completed", slug }),
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
