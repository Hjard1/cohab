import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DOCUSEAL_BASE_URL =
  Deno.env.get("DOCUSEAL_BASE_URL") ?? "https://api.docuseal.eu";
const DOCUSEAL_API_KEY = Deno.env.get("DOCUSEAL_API_KEY") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Signing-invitation email, localized to the app's language. Keys match the
// AppLanguage rawValues in the iOS app; fallback is English.
const EMAIL_TEXTS: Record<string, { subject: string; body: string }> = {
  en: {
    subject: "Your cohabitation agreement is ready to sign",
    body:
      `Hi {{submitter.name}},\n\n` +
      `{{name_a}} and {{name_b}} have prepared a cohabitation agreement with Cohab, ` +
      `covering shared assets, contributions and ownership.\n\n` +
      `Please review and sign here:\n\n{{submitter.link}}\n\n` +
      `This link is personal to you and expires in 30 days.\n\n` +
      `Best regards\nCohab`,
  },
  nb: {
    subject: "Samboeravtalen deres er klar for signering",
    body:
      `Hei {{submitter.name}},\n\n` +
      `{{name_a}} og {{name_b}} har laget en samboeravtale i Cohab, ` +
      `med oversikt over felles eiendeler, bidrag og eierforhold.\n\n` +
      `Les gjennom avtalen og signer her:\n\n{{submitter.link}}\n\n` +
      `Lenken er personlig og utløper om 30 dager.\n\n` +
      `Vennlig hilsen\nCohab`,
  },
  sv: {
    subject: "Ert samboavtal är redo att signeras",
    body:
      `Hej {{submitter.name}},\n\n` +
      `{{name_a}} och {{name_b}} har skapat ett samboavtal i Cohab, ` +
      `med översikt över gemensamma tillgångar, bidrag och ägarförhållanden.\n\n` +
      `Läs igenom avtalet och signera här:\n\n{{submitter.link}}\n\n` +
      `Länken är personlig och gäller i 30 dagar.\n\n` +
      `Vänliga hälsningar\nCohab`,
  },
  da: {
    subject: "Jeres samleveraftale er klar til underskrift",
    body:
      `Hej {{submitter.name}},\n\n` +
      `{{name_a}} og {{name_b}} har lavet en samleveraftale i Cohab, ` +
      `med overblik over fælles ejendele, bidrag og ejerforhold.\n\n` +
      `Læs aftalen og underskriv her:\n\n{{submitter.link}}\n\n` +
      `Linket er personligt og udløber om 30 dage.\n\n` +
      `Venlig hilsen\nCohab`,
  },
  fi: {
    subject: "Avoliittosopimuksenne on valmis allekirjoitettavaksi",
    body:
      `Hei {{submitter.name}},\n\n` +
      `{{name_a}} ja {{name_b}} ovat laatineet avoliittosopimuksen Cohab-sovelluksessa. ` +
      `Se kattaa yhteisen omaisuuden, maksut ja omistussuhteet.\n\n` +
      `Lue sopimus ja allekirjoita tästä:\n\n{{submitter.link}}\n\n` +
      `Linkki on henkilökohtainen ja voimassa 30 päivää.\n\n` +
      `Ystävällisin terveisin\nCohab`,
  },
  de: {
    subject: "Ihr Partnerschaftsvertrag ist zur Unterschrift bereit",
    body:
      `Hallo {{submitter.name}},\n\n` +
      `{{name_a}} und {{name_b}} haben mit Cohab einen Partnerschaftsvertrag erstellt, ` +
      `mit Übersicht über gemeinsames Vermögen, Beiträge und Eigentumsverhältnisse.\n\n` +
      `Bitte lesen Sie den Vertrag und unterschreiben Sie hier:\n\n{{submitter.link}}\n\n` +
      `Dieser Link ist persönlich und läuft in 30 Tagen ab.\n\n` +
      `Freundliche Grüße\nCohab`,
  },
  fr: {
    subject: "Votre contrat de vie commune est prêt à être signé",
    body:
      `Bonjour {{submitter.name}},\n\n` +
      `{{name_a}} et {{name_b}} ont préparé un contrat de vie commune avec Cohab, ` +
      `avec les biens communs, les contributions et la répartition de propriété.\n\n` +
      `Veuillez le lire et le signer ici :\n\n{{submitter.link}}\n\n` +
      `Ce lien est personnel et expire dans 30 jours.\n\n` +
      `Cordialement\nCohab`,
  },
  es: {
    subject: "Su acuerdo de convivencia está listo para firmar",
    body:
      `Hola {{submitter.name}},\n\n` +
      `{{name_a}} y {{name_b}} han preparado un acuerdo de convivencia con Cohab, ` +
      `con el resumen de bienes comunes, aportaciones y titularidad.\n\n` +
      `Revísalo y fírmalo aquí:\n\n{{submitter.link}}\n\n` +
      `Este enlace es personal y caduca en 30 días.\n\n` +
      `Un saludo\nCohab`,
  },
};

// Document title per language — visible in the signing UI and emails.
const AGREEMENT_TITLES: Record<string, string> = {
  en: "Cohabitation Agreement",
  nb: "Samboeravtale",
  sv: "Samboavtal",
  da: "Samleveraftale",
  fi: "Avoliittosopimus",
  de: "Partnerschaftsvertrag",
  fr: "Contrat de vie commune",
  es: "Acuerdo de convivencia",
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
      sig_y,       // fraction 0–1 from top of page
      sig_page,    // 0-indexed page number (0 = first page)
      title,
      household_id,
      language,    // app language (en, nb, sv, da, fi, de, fr, es)
      template_versions, // { clause_key: version } or { source: "bundled" } — audit trail
    } = await req.json();

    const page = typeof sig_page === "number" ? sig_page : 0;
    const lang = String(language ?? "").toLowerCase();
    const texts = EMAIL_TEXTS[lang] ?? EMAIL_TEXTS.en;
    // Localized title wins over the client-supplied one when the app sends
    // its language; older app versions keep working via the title field.
    const docTitle = lang
      ? `${name_a} & ${name_b} — ${AGREEMENT_TITLES[lang] ?? AGREEMENT_TITLES.en}`
      : title;

    // Two distinct signers are mandatory — the same address on both roles
    // would let one person complete the whole agreement alone.
    if (
      typeof email_a !== "string" || typeof email_b !== "string" ||
      email_a.trim().toLowerCase() === email_b.trim().toLowerCase()
    ) {
      return new Response(
        JSON.stringify({ error: "TWO_DISTINCT_EMAILS_REQUIRED" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!DOCUSEAL_API_KEY) {
      return new Response(
        JSON.stringify({ error: "DOCUSEAL_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // ── Monthly limit: 10 free DocuSeal signings per household. ─────────────
    const monthStart = new Date();
    monthStart.setUTCDate(1);
    monthStart.setUTCHours(0, 0, 0, 0);

    const { count } = await supabase
      .from("cohab_docuseal_submissions")
      .select("id", { count: "exact", head: true })
      .eq("household_id", household_id)
      .gte("created_at", monthStart.toISOString());

    if ((count ?? 0) >= 10) {
      return new Response(
        JSON.stringify({
          error: "DOCUSEAL_MONTHLY_LIMIT",
          message: "DocuSeal includes 10 free signings per month. The limit resets on the 1st.",
        }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
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
        name: docTitle,
        documents: [
          {
            name: docTitle,
            file: pdf_base64,
            // DocuSeal areas use fractional coords (0–1) and 0-indexed pages.
            // sig_y arrives as a fraction from ContractGenerator.
            // x/w/h are fixed fractions: 56/595, 200/595, 50/842, 320/595.
            fields: [
              {
                name: `${name_a} Signature`,
                role: "Partner A",
                type: "signature",
                required: true,
                areas: [{ x: 0.094, y: sig_y, w: 0.336, h: 0.059, page }],
              },
              {
                name: `${name_b} Signature`,
                role: "Partner B",
                type: "signature",
                required: true,
                areas: [{ x: 0.538, y: sig_y, w: 0.336, h: 0.059, page }],
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

    // ── Verify: the template MUST have exactly one required signature field
    // per role. If a field was dropped (bad coordinates, wrong page, …) the
    // submission could complete with only one signature — never send that out.
    const tplDetailResp = await fetch(`${DOCUSEAL_BASE_URL}/templates/${template.id}`, {
      headers: dsHeaders,
    });
    if (tplDetailResp.ok) {
      const tplDetail = await tplDetailResp.json();
      const sigFields = (tplDetail.fields ?? []).filter(
        (f: { type?: string; required?: boolean }) => f.type === "signature" && f.required !== false
      );
      const boundRoles = new Set(sigFields.map((f: { submitter_uuid?: string }) => f.submitter_uuid));
      const templateRoles = new Set(
        (tplDetail.submitters ?? []).map((s: { uuid?: string }) => s.uuid)
      );
      const everyRoleHasSignature = [...templateRoles].every((u) => boundRoles.has(u));
      if (sigFields.length < 2 || templateRoles.size < 2 || !everyRoleHasSignature) {
        return new Response(
          JSON.stringify({
            error: "TEMPLATE_SIGNATURE_FIELDS_INVALID",
            message:
              `Template ${template.id} has ${sigFields.length} signature fields for ` +
              `${templateRoles.size} roles — refusing to send an agreement that ` +
              `does not require both signatures.`,
          }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // ── Step 2: Create submission ─────────────────────────────────────────────
    const subResp = await fetch(`${DOCUSEAL_BASE_URL}/submissions`, {
      method: "POST",
      headers: dsHeaders,
      body: JSON.stringify({
        template_id: template.id,
        send_email: true,
        // "random" = both parties are invited immediately. The API default
        // ("preserved") would hold back partner B's email until A has signed.
        order: "random",
        submitters: [
          { name: name_a, email: email_a, role: "Partner A", order: 0 },
          { name: name_b, email: email_b, role: "Partner B", order: 0 },
        ],
        message: {
          subject: texts.subject,
          body: texts.body
            .replaceAll("{{name_a}}", name_a)
            .replaceAll("{{name_b}}", name_b),
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

    // The response array order is NOT guaranteed to match the request —
    // match each submitter by role (fall back to email) instead of index.
    const norm = (v: unknown) => String(v ?? "").trim().toLowerCase();
    const subA = submitters.find(
      (s: { role?: string; email?: string }) =>
        norm(s.role) === "partner a" || norm(s.email) === norm(email_a)
    );
    const subB = submitters.find(
      (s: { role?: string; email?: string }) =>
        norm(s.role) === "partner b" || norm(s.email) === norm(email_b)
    );

    if (!subA || !subB) {
      return new Response(
        JSON.stringify({
          error: "SUBMISSION_SUBMITTERS_INVALID",
          message: "DocuSeal did not return both Partner A and Partner B submitters.",
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const submission_id  = String(subA.submission_id ?? "");
    const slug         = subA.slug ?? "";        // Partner A's submitter slug (app polls by this)
    const signing_url_a = subA.embed_src ?? "";
    const signing_url_b = subB.embed_src ?? "";

    // ── Step 3: Track in Supabase DB (isolation from Samboappen) ─────────────
    // We only process webhook events for slugs in this table.
    await supabase.from("cohab_docuseal_submissions").insert({
      household_id,
      submission_id,
      slug,
      status: "pending",
      email_a,
      email_b,
      template_versions: template_versions ?? null,
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
