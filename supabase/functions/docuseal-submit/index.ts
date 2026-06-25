import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DOCUSEAL_BASE_URL =
  Deno.env.get("DOCUSEAL_BASE_URL") ?? "https://api.docuseal.eu";
const DOCUSEAL_API_KEY = Deno.env.get("DOCUSEAL_API_KEY") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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
      sig_y,
      title,
      household_id,
    } = await req.json();

    if (!DOCUSEAL_API_KEY) {
      return new Response(
        JSON.stringify({ error: "DOCUSEAL_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const dsHeaders = {
      "X-Auth-Token": DOCUSEAL_API_KEY,
      "Content-Type": "application/json",
    };

    // ── Step 1: Create PDF template ──────────────────────────────────────────
    const templateResp = await fetch(`${DOCUSEAL_BASE_URL}/templates/pdf`, {
      method: "POST",
      headers: dsHeaders,
      body: JSON.stringify({
        name: title,
        documents: [
          {
            name: title,
            file: pdf_base64,
            fields: [
              {
                name: `${name_a} Signature`,
                role: "Partner A",
                type: "signature",
                required: true,
                areas: [{ x: 56, y: sig_y, w: 200, h: 50, page: 1 }],
              },
              {
                name: `${name_b} Signature`,
                role: "Partner B",
                type: "signature",
                required: true,
                areas: [{ x: 320, y: sig_y, w: 200, h: 50, page: 1 }],
              },
            ],
          },
        ],
      }),
    });

    if (!templateResp.ok) {
      const err = await templateResp.text();
      return new Response(
        JSON.stringify({ error: `DocuSeal template error ${templateResp.status}: ${err}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const template = await templateResp.json();

    // ── Step 2: Create submission ─────────────────────────────────────────────
    const subResp = await fetch(`${DOCUSEAL_BASE_URL}/submissions`, {
      method: "POST",
      headers: dsHeaders,
      body: JSON.stringify({
        template_id: template.id,
        send_email: true,
        submitters: [
          { name: name_a, email: email_a, role: "Partner A", order: 0 },
          { name: name_b, email: email_b, role: "Partner B", order: 0 },
        ],
        message: {
          subject: `Agreement ready to sign: ${title}`,
          body:
            `Hi {{submitter.name}},\n\n` +
            `${name_a} and ${name_b} have created a shared ownership ` +
            `agreement using cohab.\n\nClick below to review and sign:\n{{submitter.link}}`,
        },
      }),
    });

    if (!subResp.ok) {
      const err = await subResp.text();
      return new Response(
        JSON.stringify({ error: `DocuSeal submission error ${subResp.status}: ${err}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const submitters = await subResp.json();
    const submission_id = String(submitters[0]?.submission_id ?? "");
    const slug         = submitters[0]?.slug ?? "";
    const signing_url_a = submitters[0]?.embed_src ?? "";
    const signing_url_b = submitters[1]?.embed_src ?? "";

    // ── Step 3: Track in Supabase DB (isolation from Samboappen) ─────────────
    // We only process webhook events for slugs in this table.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    await supabase.from("cohab_docuseal_submissions").insert({
      household_id,
      submission_id,
      slug,
      status: "pending",
      email_a,
      email_b,
    });

    return new Response(
      JSON.stringify({ submission_id, slug, signing_url_a, signing_url_b }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
