import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Country name (as it appears on tradingeconomics) → ISO currency code
const COUNTRY_CURRENCY: Record<string, string> = {
  "Norway": "NOK", "Sweden": "SEK", "Denmark": "DKK", "Euro Area": "EUR",
  "United Kingdom": "GBP", "Switzerland": "CHF", "Iceland": "ISK",
  "Czech Republic": "CZK", "Poland": "PLN", "Hungary": "HUF",
  "United States": "USD", "Canada": "CAD", "Mexico": "MXN",
  "Brazil": "BRL", "Chile": "CLP", "Colombia": "COP",
  "Australia": "AUD", "New Zealand": "NZD", "Japan": "JPY",
  "China": "CNY", "South Korea": "KRW", "India": "INR",
  "Singapore": "SGD", "Hong Kong": "HKD", "Malaysia": "MYR",
  "Indonesia": "IDR", "Thailand": "THB",
};

const CURRENCY_BANK: Record<string, string> = {
  NOK: "Norges Bank", SEK: "Riksbanken", DKK: "Danmarks Nationalbank",
  GBP: "Bank of England", EUR: "European Central Bank",
  USD: "Federal Reserve", CAD: "Bank of Canada",
  AUD: "Reserve Bank of Australia", NZD: "Reserve Bank of New Zealand",
  CHF: "Swiss National Bank", JPY: "Bank of Japan",
};

const CONTINENTS = ["europe", "america", "asia", "australia"];
const STALE_DAYS = 7;

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const url = new URL(req.url);
  const currency = url.searchParams.get("currency")?.toUpperCase();

  if (currency) {
    // Return rate for specific currency, refreshing if stale
    const { data: cached } = await supabase
      .from("central_bank_rates")
      .select("*")
      .eq("currency", currency)
      .maybeSingle();

    const ageMs = cached
      ? Date.now() - new Date(cached.updated_at).getTime()
      : Infinity;
    const isStale = ageMs > STALE_DAYS * 86_400_000;

    if (isStale) {
      await syncAllRates(supabase); // background refresh
    }

    // Re-fetch (might be updated now)
    const { data: fresh } = await supabase
      .from("central_bank_rates")
      .select("*")
      .eq("currency", currency)
      .maybeSingle();

    if (!fresh) {
      return new Response(JSON.stringify({ error: "Currency not found" }), {
        status: 404, headers: { ...CORS, "Content-Type": "application/json" }
      });
    }

    return new Response(JSON.stringify({
      currency: fresh.currency,
      country: fresh.country,
      rate: fresh.rate,
      source: fresh.source,
      updated_at: fresh.updated_at,
    }), { headers: { ...CORS, "Content-Type": "application/json" } });
  }

  // No currency param → sync all and return summary
  const count = await syncAllRates(supabase);
  return new Response(JSON.stringify({ synced: count }),
    { headers: { ...CORS, "Content-Type": "application/json" } }
  );
});

async function syncAllRates(supabase: ReturnType<typeof createClient>): Promise<number> {
  const rates: Array<{ currency: string; country: string; rate: number; source: string }> = [];

  for (const continent of CONTINENTS) {
    try {
      const fetched = await scrapeContinent(continent);
      rates.push(...fetched);
    } catch (e) {
      console.error(`Failed ${continent}:`, e);
    }
  }

  if (rates.length === 0) return 0;

  await supabase.from("central_bank_rates").upsert(
    rates.map((r) => ({ ...r, updated_at: new Date().toISOString() })),
    { onConflict: "currency" }
  );

  return rates.length;
}

async function scrapeContinent(
  continent: string
): Promise<Array<{ currency: string; country: string; rate: number; source: string }>> {
  const resp = await fetch(
    `https://tradingeconomics.com/country-list/interest-rate?continent=${continent}`,
    {
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; cohab-rate-fetcher/1.0)",
        "Accept": "text/html",
      },
      signal: AbortSignal.timeout(15_000),
    }
  );

  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  const html = await resp.text();

  // Extract rows: <td><a href="/country/indicator">Country</a></td><td>RATE</td>
  const rowRegex =
    /<tr[^>]*>\s*<td[^>]*>\s*<a[^>]+href="\/[^"]*"[^>]*>([^<]+)<\/a>\s*<\/td>\s*<td[^>]*>([0-9.]+)<\/td>/g;

  const results: Array<{ currency: string; country: string; rate: number; source: string }> = [];
  let m: RegExpExecArray | null;

  while ((m = rowRegex.exec(html)) !== null) {
    const country = m[1].trim();
    const ratePercent = parseFloat(m[2]);
    const currency = COUNTRY_CURRENCY[country];
    if (currency && !isNaN(ratePercent)) {
      results.push({
        currency,
        country,
        rate: ratePercent / 100,
        source: CURRENCY_BANK[currency] ?? "tradingeconomics.com",
      });
    }
  }

  return results;
}
